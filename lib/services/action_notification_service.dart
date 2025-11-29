import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActionNotificationService {
  static final ActionNotificationService _instance = ActionNotificationService._internal();
  factory ActionNotificationService() => _instance;
  ActionNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get pending admin action notifications
  Future<List<Map<String, dynamic>>> getPendingActionNotifications(String userId) async {
    try {
      debugPrint('[ActionNotificationService] ═══════════════════════════════════════');
      debugPrint('[ActionNotificationService] 📡 Fetching pending action notifications');
      debugPrint('[ActionNotificationService] User ID: $userId');
      debugPrint('[ActionNotificationService] Path: users/$userId/notifications');
      debugPrint('[ActionNotificationService] Query: type=admin_action, read=false');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: 'admin_action')
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('[ActionNotificationService] 📊 Query completed');
      debugPrint('[ActionNotificationService] Found ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        debugPrint('[ActionNotificationService] ℹ️ No pending notifications found');
        debugPrint('[ActionNotificationService] Possible reasons:');
        debugPrint('[ActionNotificationService] 1. No notifications exist');
        debugPrint('[ActionNotificationService] 2. All notifications are read');
        debugPrint('[ActionNotificationService] 3. Wrong user ID');
        debugPrint('[ActionNotificationService] ═══════════════════════════════════════');
        return [];
      }

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('[ActionNotificationService] 📄 Notification ID: ${doc.id}');
        debugPrint('[ActionNotificationService]    Title: ${data['title']}');
        debugPrint('[ActionNotificationService]    Type: ${data['type']}');
        debugPrint('[ActionNotificationService]    Read: ${data['read']}');
        debugPrint('[ActionNotificationService]    Action: ${data['data']?['action']}');
        
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'body': data['body'] ?? '',
          'action': data['data']?['action'] ?? '',
          'reason': data['data']?['reason'] ?? '',
          'reportId': data['data']?['reportId'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();

      debugPrint('[ActionNotificationService] ✅ Returning ${notifications.length} notifications');
      debugPrint('[ActionNotificationService] ═══════════════════════════════════════');
      return notifications;
    } catch (e, stackTrace) {
      debugPrint('[ActionNotificationService] ❌ Error fetching notifications: $e');
      debugPrint('[ActionNotificationService] Error type: ${e.runtimeType}');
      debugPrint('[ActionNotificationService] Stack trace: $stackTrace');
      
      if (e.toString().contains('permission-denied')) {
        debugPrint('[ActionNotificationService] 🔐 PERMISSION DENIED');
        debugPrint('[ActionNotificationService] ═══════════════════════════════════════');
        debugPrint('[ActionNotificationService] TROUBLESHOOTING:');
        debugPrint('[ActionNotificationService] 1. Check Firestore rules are published');
        debugPrint('[ActionNotificationService] 2. Verify rule: allow read: if true;');
        debugPrint('[ActionNotificationService] 3. Subcollection: users/{userId}/notifications');
        debugPrint('[ActionNotificationService] ═══════════════════════════════════════');
      }
      
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      debugPrint('[ActionNotificationService] Marking notification as read: $notificationId');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      debugPrint('[ActionNotificationService] ✅ Notification marked as read');
    } catch (e) {
      debugPrint('[ActionNotificationService] ❌ Error marking as read: $e');
    }
  }

  /// Get action details from notification
  Map<String, dynamic> getActionDetails(Map<String, dynamic> notification) {
    final action = notification['action'] ?? '';
    final reason = notification['reason'] ?? '';

    switch (action) {
      case 'warning':
        return {
          'type': 'warning',
          'title': '⚠️ Warning Issued',
          'icon': '⚠️',
          'color': 'orange',
          'message': 'You have received a warning for: $reason\n\nPlease review our community guidelines.',
          'actionable': false,
        };
      case 'tempBan7Days':
        return {
          'type': 'tempBan',
          'title': '🚫 Account Suspended',
          'icon': '🚫',
          'color': 'red',
          'message': 'Your account has been suspended for 7 days due to: $reason',
          'actionable': true,
        };
      case 'permanentBan':
        return {
          'type': 'permanentBan',
          'title': '⛔ Account Permanently Banned',
          'icon': '⛔',
          'color': 'darkRed',
          'message': 'Your account has been permanently banned due to: $reason\n\nThis action cannot be reversed.',
          'actionable': true,
        };
      case 'accountDeleted':
        return {
          'type': 'deleted',
          'title': '🗑️ Account Deleted',
          'icon': '🗑️',
          'color': 'red',
          'message': 'Your account has been permanently deleted due to: $reason\n\nAll your data has been removed.',
          'actionable': true,
        };
      default:
        return {
          'type': 'unknown',
          'title': '📢 Admin Action',
          'icon': '📢',
          'color': 'blue',
          'message': notification['body'] ?? 'An admin action has been taken on your account.',
          'actionable': false,
        };
    }
  }
}
