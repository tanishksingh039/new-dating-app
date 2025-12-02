import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import '../config/razorpay_config.dart';
import '../services/swipe_limit_service.dart'; // Add import for SwipeLimitService

/// Service to handle Razorpay payment integration
class PaymentService {
  late Razorpay _razorpay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Razorpay credentials are now managed in RazorpayConfig
  // Premium subscription price
  static const int premiumPriceInPaise = 9900; // ₹99.00
  
  // ⚠️ IMPORTANT: TEST/PROD TOGGLE FOR PREMIUM EXPIRY
  // Set to true for TESTING (30 seconds expiry)
  // Set to false for PRODUCTION (30 days expiry)
  static const bool USE_TEST_EXPIRY = false; // ✅ PRODUCTION MODE: 30 days expiry

  /// Initialize Razorpay with event handlers
  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  /// Start a payment flow (Test Mode - No Backend Required)
  /// 
  /// [amountInPaise] - Amount in paise (e.g., 9900 for ₹99.00)
  /// [description] - Description of the payment
  Future<void> startPayment({
    required int amountInPaise,
    required String description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user details from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      final userName = userData?['name'] ?? 'User';
      final userContact = userData?['phoneNumber'] ?? '';

      // Generate unique receipt ID
      final receipt = 'rcpt_${DateTime.now().millisecondsSinceEpoch}';
      
      // For test mode, we don't need backend order creation
      // Razorpay will work in test mode without order_id
      
      // Save payment attempt to Firestore for tracking
      final paymentRef = _firestore.collection('payment_orders').doc();
      await paymentRef.set({
        'userId': user.uid,
        'amount': amountInPaise,
        'currency': 'INR',
        'receipt': receipt,
        'description': description,
        'status': 'initiated',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Open Razorpay checkout (Test Mode)
      final options = {
        'key': RazorpayConfig.keyId,
        'amount': amountInPaise,
        'currency': RazorpayConfig.currency,
        'name': RazorpayConfig.companyName,
        'description': description,
        'receipt': receipt,
        'prefill': {
          'contact': userContact,
          'name': userName,
        },
        'theme': {
          'color': RazorpayConfig.themeColor,
        },
        'notes': {
          'userId': user.uid,
          'paymentRefId': paymentRef.id,
        }
      };

      _razorpay.open(options);
    } catch (e) {
      if (kDebugMode) {
        print('Error starting payment: $e');
      }
      rethrow;
    }
  }
  
  /// Start Premium Subscription Payment (₹99)
  Future<void> startPremiumPayment() async {
    await startPayment(
      amountInPaise: premiumPriceInPaise,
      description: 'Premium Subscription - Unlock all features',
    );
  }

  /// Verify payment signature
  /// This ensures the payment response is authentic and from Razorpay
  bool verifyPaymentSignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    try {
      // Create the signature verification string
      final data = '$orderId|$paymentId';
      
      // Generate HMAC SHA256 signature
      final key = utf8.encode(RazorpayConfig.keySecret);
      final bytes = utf8.encode(data);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      final generatedSignature = digest.toString();
      
      // Compare signatures
      return generatedSignature == signature;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying signature: $e');
      }
      return false;
    }
  }

  /// Handle successful payment with signature verification
  Future<void> handlePaymentSuccess({
    required String paymentId,
    String? orderId,
    String? signature,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Verify signature if available (for production)
      bool isVerified = true;
      if (orderId != null && signature != null) {
        isVerified = verifyPaymentSignature(
          orderId: orderId,
          paymentId: paymentId,
          signature: signature,
        );
        
        if (!isVerified) {
          if (kDebugMode) {
            print('Payment signature verification failed');
          }
          throw Exception('Payment verification failed');
        }
      }

      // Calculate premium expiry date
      // 🔴 CHANGE USE_TEST_EXPIRY TO FALSE FOR PRODUCTION
      final now = DateTime.now();
      final premiumExpiryDate = USE_TEST_EXPIRY
          ? now.add(const Duration(seconds: 30)) // TEST: 30 seconds
          : now.add(const Duration(days: 30));   // PRODUCTION: 30 days

      if (kDebugMode) {
        print('🎯 Premium Expiry Configuration:');
        print('   USE_TEST_EXPIRY: $USE_TEST_EXPIRY');
        print('   Expiry Date: $premiumExpiryDate');
        print('   Days until expiry: ${premiumExpiryDate.difference(now).inDays}');
      }

      // Update user's premium status with expiry date
      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': true,
        'premiumActivatedAt': FieldValue.serverTimestamp(),
        'premiumExpiryDate': Timestamp.fromDate(premiumExpiryDate),
        'lastPaymentId': paymentId,
      });

      // Log successful payment
      await _firestore.collection('payment_orders').add({
        'userId': user.uid,
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
        'amount': premiumPriceInPaise,
        'status': 'success',
        'verified': isVerified,
        'premiumExpiryDate': Timestamp.fromDate(premiumExpiryDate),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Add call to upgradeToPremium() to add 50 bonus swipes when payment succeeds
      await SwipeLimitService().upgradeToPremium();

      if (kDebugMode) {
        print('✅ Premium activated successfully');
        print('   Expires on: $premiumExpiryDate');
      }
      if (kDebugMode) {
        print('Payment successful: $paymentId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling payment success: $e');
      }
      rethrow;
    }
  }

  /// Verify payment (for backend verification)
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    // For test mode, verify locally
    if (RazorpayConfig.isTestMode) {
      return verifyPaymentSignature(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
    }
    
    // For production, you should verify on your backend
    // This is a placeholder for backend verification
    try {
      // TODO: Replace with your backend API endpoint
      // final response = await http.post(
      //   Uri.parse('YOUR_BACKEND_URL/verify-payment'),
      //   body: json.encode({
      //     'orderId': orderId,
      //     'paymentId': paymentId,
      //     'signature': signature,
      //   }),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // 
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return data['verified'] == true;
      // }
      
      return verifyPaymentSignature(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying payment: $e');
      }
      return false;
    }
  }


  /// Mark payment as failed in Firestore
  Future<void> markPaymentFailed({
    required String orderId,
    required String errorCode,
    required String errorDescription,
  }) async {
    try {
      await _firestore.collection('payment_orders').doc(orderId).update({
        'status': 'failed',
        'errorCode': errorCode,
        'errorDescription': errorDescription,
        'failedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking payment as failed: $e');
      }
    }
  }

  /// Get user's payment history
  Stream<QuerySnapshot> getPaymentHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('payment_orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay.clear();
  }
}
