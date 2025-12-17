import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to track unread reward notifications (winner announcements)
class RewardNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get count of unread winner announcements for current user
  static Stream<int> getUnreadWinnerNotificationsCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'winner_announcement')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.length;
          debugPrint('[RewardNotificationService] 🔔 Unread winner notifications: $count');
          return count;
        });
  }

  /// Mark all winner notifications as read
  static Future<void> markWinnerNotificationsAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      debugPrint('[RewardNotificationService] ✅ Marking winner notifications as read');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: 'winner_announcement')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      debugPrint('[RewardNotificationService] ✅ ${snapshot.docs.length} notifications marked as read');
    } catch (e) {
      debugPrint('[RewardNotificationService] ❌ Error marking notifications as read: $e');
    }
  }

  /// Get all winner notifications (read and unread)
  static Stream<List<Map<String, dynamic>>> getWinnerNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'winner_announcement')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Delete a specific notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      debugPrint('[RewardNotificationService] ✅ Notification deleted');
    } catch (e) {
      debugPrint('[RewardNotificationService] ❌ Error deleting notification: $e');
    }
  }
}
