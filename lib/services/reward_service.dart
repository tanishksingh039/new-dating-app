import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';

class RewardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send reward to a specific user
  static Future<String> sendRewardToUser({
    required String userId,
    required String userName,
    String? userPhoto,
    required RewardType type,
    required String title,
    required String description,
    String? couponCode,
    String? couponValue,
    DateTime? expiryDate,
    String? adminId,
    String? adminNotes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('[RewardService] ═══════════════════════════════════════');
      debugPrint('[RewardService] 🎁 Sending reward to user');
      debugPrint('[RewardService] User ID: $userId');
      debugPrint('[RewardService] User Name: $userName');
      debugPrint('[RewardService] Reward Type: ${type.name}');
      debugPrint('[RewardService] Title: $title');
      debugPrint('[RewardService] Coupon Code: $couponCode');

      final reward = RewardModel(
        id: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        type: type,
        title: title,
        description: description,
        couponCode: couponCode,
        couponValue: couponValue,
        expiryDate: expiryDate,
        status: RewardStatus.pending,
        createdAt: DateTime.now(),
        adminId: adminId,
        adminNotes: adminNotes,
        metadata: metadata,
      );

      // Add reward to rewards collection
      final rewardRef = await _firestore.collection('rewards').add(reward.toMap());
      
      debugPrint('[RewardService] ✅ Reward created with ID: ${rewardRef.id}');

      // Send notification to user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': '🎁 You\'ve Received a Reward!',
        'body': title,
        'type': 'reward',
        'data': {
          'rewardId': rewardRef.id,
          'rewardType': type.name,
          'couponCode': couponCode,
          'screen': 'rewards',
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'high',
      });

      debugPrint('[RewardService] ✅ Notification sent to user');
      debugPrint('[RewardService] ═══════════════════════════════════════');

      return rewardRef.id;
    } catch (e, stackTrace) {
      debugPrint('[RewardService] ❌ Error sending reward: $e');
      debugPrint('[RewardService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get all rewards for a user
  static Stream<List<RewardModel>> getUserRewards(String userId) {
    debugPrint('[RewardService] ═══════════════════════════════════════');
    debugPrint('[RewardService] 📡 Setting up rewards stream');
    debugPrint('[RewardService] User ID: $userId');
    debugPrint('[RewardService] Collection: rewards');
    debugPrint('[RewardService] Query: userId == $userId');
    debugPrint('[RewardService] ═══════════════════════════════════════');
    
    return _firestore
        .collection('rewards')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint('[RewardService] 📊 Stream update received');
      debugPrint('[RewardService] Documents count: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('[RewardService] ℹ️ No rewards found for user');
        debugPrint('[RewardService] Possible reasons:');
        debugPrint('[RewardService] 1. No rewards have been sent to this user');
        debugPrint('[RewardService] 2. Wrong user ID');
        debugPrint('[RewardService] 3. Firestore rules blocking read');
      } else {
        for (var doc in snapshot.docs) {
          debugPrint('[RewardService] 📄 Reward: ${doc.id}');
          debugPrint('[RewardService]    Title: ${doc.data()['title']}');
          debugPrint('[RewardService]    Status: ${doc.data()['status']}');
        }
      }
      
      return snapshot.docs
          .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get pending rewards for a user
  static Future<List<RewardModel>> getPendingRewards(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rewards')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: RewardStatus.pending.name)
          .get();

      return snapshot.docs
          .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[RewardService] Error fetching pending rewards: $e');
      return [];
    }
  }

  /// Claim a reward
  static Future<void> claimReward(String rewardId) async {
    try {
      debugPrint('[RewardService] Claiming reward: $rewardId');

      await _firestore.collection('rewards').doc(rewardId).update({
        'status': RewardStatus.claimed.name,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[RewardService] ✅ Reward claimed successfully');
    } catch (e) {
      debugPrint('[RewardService] ❌ Error claiming reward: $e');
      rethrow;
    }
  }

  /// Mark reward as used
  static Future<void> markRewardAsUsed(String rewardId) async {
    try {
      debugPrint('[RewardService] Marking reward as used: $rewardId');

      await _firestore.collection('rewards').doc(rewardId).update({
        'status': RewardStatus.used.name,
        'usedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[RewardService] ✅ Reward marked as used');
    } catch (e) {
      debugPrint('[RewardService] ❌ Error marking reward as used: $e');
      rethrow;
    }
  }

  /// Get all rewards (admin)
  static Stream<List<RewardModel>> getAllRewards() {
    return _firestore
        .collection('rewards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Delete reward
  static Future<void> deleteReward(String rewardId) async {
    try {
      await _firestore.collection('rewards').doc(rewardId).delete();
      debugPrint('[RewardService] ✅ Reward deleted');
    } catch (e) {
      debugPrint('[RewardService] ❌ Error deleting reward: $e');
      rethrow;
    }
  }

  /// Get reward count for user
  static Future<int> getUserRewardCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rewards')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('[RewardService] Error getting reward count: $e');
      return 0;
    }
  }
}
