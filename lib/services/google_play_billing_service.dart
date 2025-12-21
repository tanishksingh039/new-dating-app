import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/swipe_limit_service.dart';

/// Service to handle Google Play Billing integration
class GooglePlayBillingService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Product IDs - MUST match Google Play Console
  static const String premiumMonthlyId = 'premium_monthly';
  static const String premiumBasePlanId = 'monthly-basic';
  
  static const String spotlightProductId = 'spotlight_299';
  static const String spotlightBasePlanId = 'spotlight-299';
  
  static const String swipeProductId = 'swipe_20';
  static const String swipeBasePlanId = 'swipes-20';
  
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isInitialized = false;
  
  // Callbacks for UI updates
  Function(String)? onPurchaseSuccess;
  Function(String)? onPurchaseError;
  Function()? onPurchasePending;
  
  /// Check if Google Play Billing is available
  bool get isAvailable => _isAvailable;
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get available products
  List<ProductDetails> get products => _products;
  
  /// Initialize Google Play Billing
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) print('✅ Google Play Billing already initialized');
      return;
    }
    
    try {
      _isAvailable = await _iap.isAvailable();
      
      if (!_isAvailable) {
        if (kDebugMode) print('❌ In-app purchases not available');
        return;
      }
      
      if (kDebugMode) print('✅ Google Play Billing available');
      
      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          if (kDebugMode) print('🔚 Purchase stream closed');
          _subscription?.cancel();
        },
        onError: (error) {
          if (kDebugMode) print('❌ Purchase stream error: $error');
        },
      );
      
      // Load products
      await _loadProducts();
      
      _isInitialized = true;
      if (kDebugMode) print('✅ Google Play Billing initialized');
    } catch (e) {
      if (kDebugMode) print('❌ Error initializing Google Play Billing: $e');
      _isAvailable = false;
    }
  }
  
  /// Load products from Google Play Console
  Future<void> _loadProducts() async {
    try {
      const Set<String> productIds = {
        premiumMonthlyId,
        spotlightProductId,
        swipeProductId,
      };
      final ProductDetailsResponse response = 
          await _iap.queryProductDetails(productIds);
      
      if (response.error != null) {
        if (kDebugMode) {
          print('❌ Error loading products: ${response.error}');
        }
        return;
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          print('❌ Products not found in Play Console: ${response.notFoundIDs}');
          print('   Make sure product ID "$premiumMonthlyId" exists in Google Play Console');
        }
      }
      
      _products = response.productDetails;
      if (kDebugMode) {
        print('✅ Loaded ${_products.length} products from Google Play');
        for (var product in _products) {
          print('   - ${product.id}: ${product.title} - ${product.price}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading products: $e');
    }
  }
  
  /// Purchase a product by ID
  Future<bool> _purchaseProduct(String productId) async {
    if (!_isAvailable) {
      if (kDebugMode) print('❌ Google Play Billing not available');
      return false;
    }
    
    if (_products.isEmpty) {
      if (kDebugMode) print('❌ No products loaded. Trying to reload...');
      await _loadProducts();
      
      if (_products.isEmpty) {
        if (kDebugMode) print('❌ Still no products available');
        return false;
      }
    }
    
    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product $productId not found'),
      );
      
      if (kDebugMode) {
        print('🛒 Starting purchase for: ${product.title}');
        print('   Price: ${product.price}');
        print('   Product ID: ${product.id}');
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      
      // For subscriptions, use buyNonConsumable
      // For one-time purchases, also use buyNonConsumable
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (kDebugMode) {
        print(result ? '✅ Purchase initiated' : '❌ Purchase failed to initiate');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) print('❌ Error purchasing product: $e');
      onPurchaseError?.call('Error: $e');
      return false;
    }
  }
  
  /// Purchase premium subscription
  Future<bool> purchasePremium() async {
    return _purchaseProduct(premiumMonthlyId);
  }
  
  /// Purchase spotlight booking
  Future<bool> purchaseSpotlight() async {
    return _purchaseProduct(spotlightProductId);
  }
  
  /// Purchase swipe pack
  Future<bool> purchaseSwipes() async {
    return _purchaseProduct(swipeProductId);
  }
  
  /// Handle purchase updates from Google Play
  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (kDebugMode) {
        print('📦 Purchase update: ${purchaseDetails.productID}');
        print('   Status: ${purchaseDetails.status}');
        print('   Purchase ID: ${purchaseDetails.purchaseID}');
      }
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        if (kDebugMode) print('⏳ Purchase pending...');
        onPurchasePending?.call();
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        final errorMsg = purchaseDetails.error?.message ?? 'Unknown error';
        if (kDebugMode) print('❌ Purchase error: $errorMsg');
        onPurchaseError?.call(errorMsg);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify and grant premium
        if (kDebugMode) print('✅ Purchase successful, granting premium...');
        await _verifyAndGrantPremium(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        if (kDebugMode) print('🚫 Purchase canceled by user');
        onPurchaseError?.call('Purchase canceled');
      }
      
      // Complete purchase (important!)
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
        if (kDebugMode) print('✅ Purchase completed');
      }
    }
  }
  
  /// Verify purchase and grant access based on product type
  Future<void> _verifyAndGrantPremium(PurchaseDetails details) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) print('❌ No user logged in');
        return;
      }
      
      final productId = details.productID;
      
      // Handle different product types
      if (productId == premiumMonthlyId) {
        await _handlePremiumPurchase(user.uid, details);
      } else if (productId == spotlightProductId) {
        await _handleSpotlightPurchase(user.uid, details);
      } else if (productId == swipeProductId) {
        await _handleSwipePurchase(user.uid, details);
      } else {
        if (kDebugMode) print('❌ Unknown product ID: $productId');
        onPurchaseError?.call('Unknown product');
        return;
      }
      
      if (kDebugMode) print('✅ Purchase processed successfully');
      onPurchaseSuccess?.call(details.purchaseID ?? 'unknown');
    } catch (e) {
      if (kDebugMode) print('❌ Error processing purchase: $e');
      onPurchaseError?.call('Error processing purchase: $e');
    }
  }
  
  /// Handle premium subscription purchase
  Future<void> _handlePremiumPurchase(String userId, PurchaseDetails details) async {
    final now = DateTime.now();
    final expiryDate = now.add(const Duration(days: 30));
    
    if (kDebugMode) {
      print('👤 Granting premium to user: $userId');
      print('   Expires: $expiryDate');
    }
    
    // Update user's premium status
    await _firestore.collection('users').doc(userId).update({
      'isPremium': true,
      'premiumActivatedAt': FieldValue.serverTimestamp(),
      'premiumExpiryDate': Timestamp.fromDate(expiryDate),
      'lastPurchaseId': details.purchaseID,
      'lastPaymentPlatform': 'google_play',
    });
    
    // Log purchase
    await _firestore.collection('payment_orders').add({
      'userId': userId,
      'purchaseId': details.purchaseID,
      'productId': details.productID,
      'amount': 9900, // ₹99 in paise
      'currency': 'INR',
      'status': 'success',
      'platform': 'google_play',
      'type': 'premium',
      'description': 'Premium Subscription via Google Play',
      'premiumExpiryDate': Timestamp.fromDate(expiryDate),
      'completedAt': FieldValue.serverTimestamp(),
      'verificationData': details.verificationData.serverVerificationData,
    });
    
    // Grant 50 bonus swipes
    await SwipeLimitService().upgradeToPremium();
    
    if (kDebugMode) print('✅ Premium granted successfully');
  }
  
  /// Handle spotlight booking purchase
  Future<void> _handleSpotlightPurchase(String userId, PurchaseDetails details) async {
    if (kDebugMode) print('🌟 Processing spotlight purchase for user: $userId');
    
    // Log purchase
    await _firestore.collection('payment_orders').add({
      'userId': userId,
      'purchaseId': details.purchaseID,
      'productId': details.productID,
      'amount': 29900, // ₹299 in paise
      'currency': 'INR',
      'status': 'success',
      'platform': 'google_play',
      'type': 'spotlight',
      'description': 'Spotlight Booking via Google Play',
      'completedAt': FieldValue.serverTimestamp(),
      'verificationData': details.verificationData.serverVerificationData,
    });
    
    if (kDebugMode) print('✅ Spotlight purchase logged');
  }
  
  /// Handle swipe pack purchase
  Future<void> _handleSwipePurchase(String userId, PurchaseDetails details) async {
    if (kDebugMode) print('💫 Processing swipe pack purchase for user: $userId');
    
    // Get user's premium status to determine swipe count
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final isPremium = userDoc.data()?['isPremium'] ?? false;
    final swipesCount = isPremium ? 10 : 6;
    
    // Add swipes to user account
    await SwipeLimitService().addPurchasedSwipesAfterPayment(swipesCount);
    
    // Log purchase
    await _firestore.collection('payment_orders').add({
      'userId': userId,
      'purchaseId': details.purchaseID,
      'productId': details.productID,
      'amount': 2000, // ₹20 in paise
      'currency': 'INR',
      'status': 'success',
      'platform': 'google_play',
      'type': 'swipes',
      'swipesCount': swipesCount,
      'description': 'Swipe Pack ($swipesCount swipes) via Google Play',
      'completedAt': FieldValue.serverTimestamp(),
      'verificationData': details.verificationData.serverVerificationData,
    });
    
    if (kDebugMode) print('✅ $swipesCount swipes added successfully');
  }
  
  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      if (kDebugMode) print('❌ Google Play Billing not available');
      return;
    }
    
    try {
      if (kDebugMode) print('🔄 Restoring purchases...');
      await _iap.restorePurchases();
      if (kDebugMode) print('✅ Restore purchases initiated');
    } catch (e) {
      if (kDebugMode) print('❌ Error restoring purchases: $e');
      onPurchaseError?.call('Error restoring purchases: $e');
    }
  }
  
  /// Get premium product details
  ProductDetails? getPremiumProduct() {
    try {
      return _products.firstWhere((p) => p.id == premiumMonthlyId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get spotlight product details
  ProductDetails? getSpotlightProduct() {
    try {
      return _products.firstWhere((p) => p.id == spotlightProductId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get swipe pack product details
  ProductDetails? getSwipeProduct() {
    try {
      return _products.firstWhere((p) => p.id == swipeProductId);
    } catch (e) {
      return null;
    }
  }
  
  /// Dispose service and cancel subscriptions
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    if (kDebugMode) print('🔚 Google Play Billing service disposed');
  }
}
