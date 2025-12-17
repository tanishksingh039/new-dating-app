import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Helper class to test notification badge functionality
class TestNotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a test winner notification for current user
  /// Use this to test if the notification badge appears
  static Future<void> createTestNotification() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('[TestNotificationHelper] ❌ No user logged in');
        return;
      }

      debugPrint('[TestNotificationHelper] 🧪 Creating test notification for user: $userId');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': '🏆 TEST: You\'re Winner of the Month!',
        'body': 'This is a test notification to verify the badge system works.',
        'type': 'winner_announcement',
        'data': {
          'winnerId': 'test_winner_id',
          'month': 'December',
          'year': '2024',
          'screen': 'rewards',
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'high',
      });

      debugPrint('[TestNotificationHelper] ✅ Test notification created successfully');
      debugPrint('[TestNotificationHelper] 🔔 Badge should appear on Rewards tab now');
    } catch (e, stackTrace) {
      debugPrint('[TestNotificationHelper] ❌ Error creating test notification: $e');
      debugPrint('[TestNotificationHelper] Stack trace: $stackTrace');
    }
  }

  /// Check if notifications exist for current user
  static Future<void> checkNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('[TestNotificationHelper] ❌ No user logged in');
        return;
      }

      debugPrint('[TestNotificationHelper] 🔍 Checking notifications for user: $userId');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: 'winner_announcement')
          .get();

      debugPrint('[TestNotificationHelper] 📊 Total winner notifications: ${snapshot.docs.length}');

      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isRead = data['read'] ?? false;
        if (!isRead) unreadCount++;
        
        debugPrint('[TestNotificationHelper]   - ${doc.id}:');
        debugPrint('[TestNotificationHelper]     Title: ${data['title']}');
        debugPrint('[TestNotificationHelper]     Read: $isRead');
        debugPrint('[TestNotificationHelper]     Created: ${data['createdAt']}');
      }

      debugPrint('[TestNotificationHelper] 🔔 Unread notifications: $unreadCount');
      
      if (unreadCount > 0) {
        debugPrint('[TestNotificationHelper] ✅ Badge SHOULD be visible');
      } else {
        debugPrint('[TestNotificationHelper] ⚠️ No unread notifications - badge will NOT show');
      }
    } catch (e, stackTrace) {
      debugPrint('[TestNotificationHelper] ❌ Error checking notifications: $e');
      debugPrint('[TestNotificationHelper] Stack trace: $stackTrace');
    }
  }

  /// Delete all test notifications
  static Future<void> deleteAllTestNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('[TestNotificationHelper] ❌ No user logged in');
        return;
      }

      debugPrint('[TestNotificationHelper] 🗑️ Deleting all notifications...');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: 'winner_announcement')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('[TestNotificationHelper] ✅ Deleted ${snapshot.docs.length} notifications');
    } catch (e) {
      debugPrint('[TestNotificationHelper] ❌ Error deleting notifications: $e');
    }
  }
}
