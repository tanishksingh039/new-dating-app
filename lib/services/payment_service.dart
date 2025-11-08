import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle Razorpay payment integration
class PaymentService {
  late Razorpay _razorpay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TODO: Replace with your actual backend URL
  // For Firebase Cloud Functions: https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net
  static const String backendBaseUrl = 'YOUR_BACKEND_URL';
  
  // TODO: Replace with your Razorpay Test Key ID (from Razorpay Dashboard)
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';

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

  /// Start a payment flow
  /// 
  /// [amountInPaise] - Amount in paise (e.g., 49900 for ₹499.00)
  /// [description] - Description of the payment
  /// [receipt] - Your internal reference/receipt ID
  Future<void> startPayment({
    required int amountInPaise,
    required String description,
    String? receipt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user details from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      final userEmail = userData?['email'] ?? user.email ?? '';
      final userName = userData?['name'] ?? 'User';
      final userContact = userData?['phone'] ?? '';

      // Generate receipt if not provided
      final finalReceipt = receipt ?? 'rcpt_${DateTime.now().millisecondsSinceEpoch}';

      // Create order on backend
      final orderRes = await http.post(
        Uri.parse('$backendBaseUrl/createOrder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amountInPaise': amountInPaise,
          'currency': 'INR',
          'receipt': finalReceipt,
          'userId': user.uid,
        }),
      );

      if (orderRes.statusCode != 200) {
        throw Exception('Failed to create order: ${orderRes.body}');
      }

      final order = jsonDecode(orderRes.body);
      final orderId = order['id'];

      // Save order to Firestore for tracking
      await _firestore.collection('payment_orders').doc(orderId).set({
        'orderId': orderId,
        'userId': user.uid,
        'amount': amountInPaise,
        'currency': 'INR',
        'receipt': finalReceipt,
        'description': description,
        'status': 'created',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Open Razorpay checkout
      final options = {
        'key': razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'CampusBound',
        'description': description,
        'order_id': orderId,
        'prefill': {
          'contact': userContact,
          'email': userEmail,
          'name': userName,
        },
        'theme': {
          'color': '#FF6B9D',
        },
        'modal': {
          'ondismiss': () {
            if (kDebugMode) {
              print('Payment dismissed by user');
            }
          }
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

  /// Verify payment signature on backend
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final verifyRes = await http.post(
        Uri.parse('$backendBaseUrl/verifyPayment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );

      if (verifyRes.statusCode != 200) {
        return false;
      }

      final body = jsonDecode(verifyRes.body);
      final isValid = body['valid'] == true;

      if (isValid) {
        // Update order status in Firestore
        await _firestore.collection('payment_orders').doc(orderId).update({
          'status': 'success',
          'paymentId': paymentId,
          'signature': signature,
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Update user's premium status or credits
        final user = _auth.currentUser;
        if (user != null) {
          await _updateUserAfterPayment(user.uid, orderId);
        }
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying payment: $e');
      }
      return false;
    }
  }

  /// Update user's premium status or credits after successful payment
  Future<void> _updateUserAfterPayment(String userId, String orderId) async {
    try {
      final orderDoc = await _firestore.collection('payment_orders').doc(orderId).get();
      final orderData = orderDoc.data();
      
      if (orderData != null) {
        final amount = orderData['amount'] as int;
        final description = orderData['description'] as String;

        // Example: Add premium status or credits based on amount
        if (description.contains('Premium')) {
          await _firestore.collection('users').doc(userId).update({
            'isPremium': true,
            'premiumExpiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 30)),
            ),
            'lastPaymentAt': FieldValue.serverTimestamp(),
          });
        } else if (description.contains('Credits')) {
          // Add credits logic
          await _firestore.collection('users').doc(userId).update({
            'credits': FieldValue.increment(amount ~/ 100), // Example: 1 credit per rupee
            'lastPaymentAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user after payment: $e');
      }
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
