import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/swipe_config.dart';
import '../models/swipe_stats.dart';
import 'payment_service.dart';

/// Service to manage swipe limits and purchases
class SwipeLimitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();

  /// Get current user's swipe stats
  Future<SwipeStats?> getSwipeStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('swipe_stats')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Create initial stats
        return await _createInitialStats(user.uid);
      }

      final stats = SwipeStats.fromFirestore(doc);

      // Get user's premium status to determine reset logic
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isPremium = userDoc.data()?['isPremium'] ?? false;

      // Check if weekly reset is needed (ONLY for premium users)
      if (isPremium && stats.needsWeeklyReset()) {
        return await _resetWeeklySwipes(stats);
      }

      // Non-premium users: NO reset - swipes are static (lifetime)

      return stats;
    } catch (e) {
      print('Error getting swipe stats: $e');
      return null;
    }
  }

  /// Stream of swipe stats
  Stream<SwipeStats?> swipeStatsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('swipe_stats')
        .doc(user.uid)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) {
        return await _createInitialStats(user.uid);
      }

      final stats = SwipeStats.fromFirestore(doc);

      // Get user's premium status
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isPremium = userDoc.data()?['isPremium'] ?? false;

      // Check if weekly reset is needed (ONLY for premium users)
      if (isPremium && stats.needsWeeklyReset()) {
        return await _resetWeeklySwipes(stats);
      }

      // Non-premium users: NO reset - swipes are static

      return stats;
    });
  }

  /// Create initial stats for new user
  Future<SwipeStats> _createInitialStats(String userId) async {
    final now = DateTime.now();
    final stats = SwipeStats(
      userId: userId,
      totalSwipes: 0,
      freeSwipesUsed: 0,
      purchasedSwipesRemaining: 0,
      lastResetDate: now,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('swipe_stats')
        .doc(userId)
        .set(stats.toFirestore());

    return stats;
  }

  /// Reset weekly swipes to 50 (for premium users only)
  /// Premium users get 50 swipes reset every week during their premium period
  /// Testing: resets every 1 minute
  /// Production: resets every 7 days
  /// NOTE: Backend Cloud Function adds 50 swipes on update, so we set to 0
  Future<SwipeStats> _resetWeeklySwipes(SwipeStats stats) async {
    final now = DateTime.now();
    
    print('[WeeklyReset] 🔄 Weekly reset triggered for user ${stats.userId}');
    print('[WeeklyReset] 📊 Current state:');
    print('[WeeklyReset]   - purchasedSwipesRemaining: ${stats.purchasedSwipesRemaining}');
    print('[WeeklyReset]   - freeSwipesUsed: ${stats.freeSwipesUsed}');
    print('[WeeklyReset]   - lastResetDate: ${stats.lastResetDate}');
    
    // Reset to 0 swipes (backend will add 50 to make it 50 total)
    final updatedStats = stats.copyWith(
      freeSwipesUsed: 0,
      purchasedSwipesRemaining: 0,
      lastResetDate: now,
      updatedAt: now,
    );

    print('[WeeklyReset] 📝 Resetting to 0 (backend will add 50 to make 50 total)');
    
    // Write only essential fields to Firestore
    await _firestore
        .collection('swipe_stats')
        .doc(stats.userId)
        .update({
          'freeSwipesUsed': 0,
          'purchasedSwipesRemaining': 0,
          'lastResetDate': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
    
    print('[WeeklyReset] ✅ Reset completed - backend will add 50 to reach 50 total');

    return updatedStats;
  }

  /// Check if user can swipe
  Future<bool> canSwipe() async {
    try {
      final stats = await getSwipeStats();
      if (stats == null) return false;

      final user = _auth.currentUser;
      if (user == null) return false;

      // Get user's premium status
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isPremium = userDoc.data()?['isPremium'] ?? false;

      final freeSwipesLimit = SwipeConfig.getFreeSwipes(isPremium);

      return stats.hasSwipesAvailable(freeSwipesLimit);
    } catch (e) {
      print('Error checking swipe availability: $e');
      return false;
    }
  }

  /// Use a swipe
  Future<bool> useSwipe() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final stats = await getSwipeStats();
      if (stats == null) return false;

      // Get user's premium status
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isPremium = userDoc.data()?['isPremium'] ?? false;

      final freeSwipesLimit = SwipeConfig.getFreeSwipes(isPremium);

      // Check if swipe is available
      if (!stats.hasSwipesAvailable(freeSwipesLimit)) {
        print('❌ No swipes available');
        return false;
      }

      // Use free swipe first, then purchased swipes
      SwipeStats updatedStats;
      if (stats.freeSwipesUsed < freeSwipesLimit) {
        // Use free swipe
        updatedStats = stats.copyWith(
          totalSwipes: stats.totalSwipes + 1,
          freeSwipesUsed: stats.freeSwipesUsed + 1,
          updatedAt: DateTime.now(),
        );
        print('✅ Used free swipe (${stats.freeSwipesUsed + 1}/$freeSwipesLimit)');
      } else {
        // Use purchased swipe
        updatedStats = stats.copyWith(
          totalSwipes: stats.totalSwipes + 1,
          purchasedSwipesRemaining: stats.purchasedSwipesRemaining - 1,
          updatedAt: DateTime.now(),
        );
        print('✅ Used purchased swipe (${stats.purchasedSwipesRemaining - 1} remaining)');
      }

      await _firestore
          .collection('swipe_stats')
          .doc(user.uid)
          .update(updatedStats.toFirestore());

      return true;
    } catch (e) {
      print('Error using swipe: $e');
      return false;
    }
  }

  /// Purchase additional swipes
  /// Returns the number of swipes that will be added on successful payment
  Future<int> purchaseSwipes() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get user's premium status
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final isPremium = userDoc.data()?['isPremium'] ?? false;

    final swipesCount = SwipeConfig.getAdditionalSwipesCount(isPremium);
    final description = SwipeConfig.getSwipePackageDescription(isPremium);

    print('🛒 Purchasing swipes: $description');

    // Start payment - callbacks are handled by PaymentService.init()
    await _paymentService.startPayment(
      amountInPaise: SwipeConfig.additionalSwipesPriceInPaise,
      description: description,
    );

    return swipesCount;
  }

  /// Add purchased swipes after successful payment
  /// This should be called from the payment success callback
  Future<void> addPurchasedSwipesAfterPayment(int count) async {
    await _addPurchasedSwipes(count);
  }

  /// Add purchased swipes to user's account
  Future<void> _addPurchasedSwipes(int count) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final stats = await getSwipeStats();
      if (stats == null) return;

      final updatedStats = stats.copyWith(
        purchasedSwipesRemaining: stats.purchasedSwipesRemaining + count,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('swipe_stats')
          .doc(user.uid)
          .update(updatedStats.toFirestore());

      print('✅ Added $count purchased swipes');
    } catch (e) {
      print('Error adding purchased swipes: $e');
      rethrow;
    }
  }

  /// Upgrade to premium
  /// Properly handles remaining free swipes conversion
  Future<void> upgradeToPremium() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final stats = await getSwipeStats();
      if (stats == null) return;

      print('[PremiumUpgrade] 🎉 Upgrading user to premium');
      print('[PremiumUpgrade]   - Current swipes: ${stats.purchasedSwipesRemaining}');
      
      final now = DateTime.now();
      
      // Premium upgrade: Set to 0 (backend will add 50 to make it 50 total)
      final updatedStats = stats.copyWith(
        freeSwipesUsed: 0,
        purchasedSwipesRemaining: 0,
        lastResetDate: now,
        updatedAt: now,
      );

      print('[PremiumUpgrade] 📝 Setting swipes to 0 (backend will add 50 to make 50 total)');
      
      // Write to Firestore using set with merge to handle both new and existing documents
      await _firestore
          .collection('swipe_stats')
          .doc(user.uid)
          .set({
            'totalSwipes': updatedStats.totalSwipes,
            'freeSwipesUsed': 0,
            'purchasedSwipesRemaining': 0,
            'lastResetDate': Timestamp.fromDate(now),
            'createdAt': Timestamp.fromDate(updatedStats.createdAt),
            'updatedAt': Timestamp.fromDate(now),
          }, SetOptions(merge: true));

      print('[PremiumUpgrade] ✅ Swipes updated - backend will add 50 to reach 50 total');

      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': true,
        'premiumUpgradedAt': FieldValue.serverTimestamp(),
      });

      print('[PremiumUpgrade] ✅ Upgraded to premium - User will have 50 swipes');
    } catch (e) {
      print('Error upgrading to premium: $e');
      rethrow;
    }
  }

  /// Get swipe stats summary
  Future<Map<String, dynamic>> getSwipeSummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'canSwipe': false,
          'freeSwipesRemaining': 0,
          'purchasedSwipesRemaining': 0,
          'totalRemaining': 0,
          'isPremium': false,
        };
      }

      final stats = await getSwipeStats();
      if (stats == null) {
        return {
          'canSwipe': false,
          'freeSwipesRemaining': 0,
          'purchasedSwipesRemaining': 0,
          'totalRemaining': 0,
          'isPremium': false,
        };
      }

      // Get user's premium status
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isPremium = userDoc.data()?['isPremium'] ?? false;

      final freeSwipesLimit = SwipeConfig.getFreeSwipes(isPremium);
      final freeSwipesRemaining = stats.getRemainingFreeSwipes(freeSwipesLimit);
      final totalRemaining = stats.getTotalRemainingSwipes(freeSwipesLimit);

      return {
        'canSwipe': totalRemaining > 0,
        'freeSwipesRemaining': freeSwipesRemaining,
        'purchasedSwipesRemaining': stats.purchasedSwipesRemaining,
        'totalRemaining': totalRemaining,
        'isPremium': isPremium,
        'freeSwipesLimit': freeSwipesLimit,
        'freeSwipesUsed': stats.freeSwipesUsed,
      };
    } catch (e) {
      print('Error getting swipe summary: $e');
      return {
        'canSwipe': false,
        'freeSwipesRemaining': 0,
        'purchasedSwipesRemaining': 0,
        'totalRemaining': 0,
        'isPremium': false,
      };
    }
  }
}