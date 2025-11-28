import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/action_notification_service.dart';
import '../services/ban_enforcement_service.dart';
import '../screens/action_notification_dialog.dart';
import '../screens/banned_screen.dart';

class AdminActionChecker extends StatefulWidget {
  final Widget child;

  const AdminActionChecker({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AdminActionChecker> createState() => _AdminActionCheckerState();
}

class _AdminActionCheckerState extends State<AdminActionChecker> {
  final ActionNotificationService _notificationService = ActionNotificationService();
  final BanEnforcementService _banService = BanEnforcementService();
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkAdminActions();
  }

  Future<void> _checkAdminActions() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _checked = true);
        return;
      }

      debugPrint('[AdminActionChecker] Checking admin actions for: $userId');

      // First check if user is banned
      final banStatus = await _banService.checkBanStatus(userId);

      if (banStatus['isBanned'] == true) {
        debugPrint('[AdminActionChecker] User is banned, showing banned screen');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/banned',
            arguments: banStatus,
          );
        }
        return;
      }

      // Then check for pending action notifications
      final notifications = await _notificationService.getPendingActionNotifications(userId);

      if (notifications.isNotEmpty) {
        debugPrint('[AdminActionChecker] Found ${notifications.length} pending notifications');

        // Show first notification
        if (mounted) {
          _showActionNotification(notifications[0], userId);
        }
      } else {
        debugPrint('[AdminActionChecker] No pending notifications');
        setState(() => _checked = true);
      }
    } catch (e) {
      debugPrint('[AdminActionChecker] ❌ Error checking admin actions: $e');
      setState(() => _checked = true);
    }
  }

  void _showActionNotification(Map<String, dynamic> notification, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActionNotificationDialog(
        notification: notification,
        onDismiss: () async {
          // Mark as read
          await _notificationService.markNotificationAsRead(userId, notification['id']);

          // Check if there are more notifications
          final remaining = await _notificationService.getPendingActionNotifications(userId);

          if (remaining.isNotEmpty) {
            // Show next notification
            if (mounted) {
              _showActionNotification(remaining[0], userId);
            }
          } else {
            // All notifications shown
            setState(() => _checked = true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
