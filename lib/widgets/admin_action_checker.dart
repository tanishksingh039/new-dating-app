import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/action_notification_service.dart';
import '../services/ban_enforcement_service.dart';
import '../screens/action_notification_dialog.dart';
import '../screens/banned_screen.dart';
import '../screens/warning_screen.dart';

class AdminActionChecker extends StatefulWidget {
  final Widget child;
  final bool checkOnEveryBuild; // Option to check on every build or just once

  const AdminActionChecker({
    Key? key,
    required this.child,
    this.checkOnEveryBuild = true, // Default: check every time
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

  @override
  void didUpdateWidget(AdminActionChecker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check again when widget updates if checkOnEveryBuild is true
    if (widget.checkOnEveryBuild) {
      _checked = false; // Reset checked flag to allow re-checking
      _checkAdminActions();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check when dependencies change (e.g., when navigating between tabs)
    if (widget.checkOnEveryBuild && !_checked) {
      _checkAdminActions();
    }
  }

  Future<void> _checkAdminActions() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('[AdminActionChecker] ❌ No user ID found');
        setState(() => _checked = true);
        return;
      }

      debugPrint('[AdminActionChecker] ═══════════════════════════════════════');
      debugPrint('[AdminActionChecker] 🔍 Checking admin actions for: $userId');
      debugPrint('[AdminActionChecker] Timestamp: ${DateTime.now()}');
      debugPrint('[AdminActionChecker] ═══════════════════════════════════════');

      // First check if user is banned
      debugPrint('[AdminActionChecker] Step 1: Checking ban status...');
      final banStatus = await _banService.checkBanStatus(userId);
      debugPrint('[AdminActionChecker] Ban status result: $banStatus');
      debugPrint('[AdminActionChecker] isBanned: ${banStatus['isBanned']}');

      if (banStatus['isBanned'] == true) {
        debugPrint('[AdminActionChecker] ⛔ User is banned, showing banned screen');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/banned',
            arguments: banStatus,
          );
        }
        return;
      }

      // Then check for pending action notifications
      debugPrint('[AdminActionChecker] Step 2: Fetching pending notifications...');
      debugPrint('[AdminActionChecker] Query path: users/$userId/notifications');
      debugPrint('[AdminActionChecker] Query filters: type=admin_action, read=false');
      
      final notifications = await _notificationService.getPendingActionNotifications(userId);
      debugPrint('[AdminActionChecker] 📬 Notifications count: ${notifications.length}');
      
      if (notifications.isNotEmpty) {
        debugPrint('[AdminActionChecker] ✅ Found ${notifications.length} pending notifications');
        
        for (int i = 0; i < notifications.length; i++) {
          final notif = notifications[i];
          debugPrint('[AdminActionChecker] Notification #${i + 1}:');
          debugPrint('[AdminActionChecker]   ID: ${notif['id']}');
          debugPrint('[AdminActionChecker]   Title: ${notif['title']}');
          debugPrint('[AdminActionChecker]   Action: ${notif['action']}');
          debugPrint('[AdminActionChecker]   Reason: ${notif['reason']}');
          debugPrint('[AdminActionChecker]   CreatedAt: ${notif['createdAt']}');
        }
        
        final firstNotification = notifications[0];
        final action = firstNotification['action'];
        
        debugPrint('[AdminActionChecker] Processing first notification...');
        debugPrint('[AdminActionChecker] Action type: "$action"');
        debugPrint('[AdminActionChecker] Action type runtimeType: ${action.runtimeType}');
        debugPrint('[AdminActionChecker] Is action == "warning"? ${action == 'warning'}');

        if (mounted) {
          // Check if it's a warning - show full screen
          if (action == 'warning') {
            debugPrint('[AdminActionChecker] ✅ Action matches "warning", showing warning screen...');
            _showWarningScreen(firstNotification, userId);
          } else if (action.toString().toLowerCase().contains('warning')) {
            debugPrint('[AdminActionChecker] ⚠️ Action contains "warning" (case-insensitive), showing warning screen...');
            _showWarningScreen(firstNotification, userId);
          } else {
            // For other actions (bans, etc), show dialog
            debugPrint('[AdminActionChecker] Action is not warning, showing notification dialog...');
            debugPrint('[AdminActionChecker] Action value: "$action"');
            _showActionNotification(firstNotification, userId);
          }
        } else {
          debugPrint('[AdminActionChecker] ⚠️ Widget not mounted, cannot show notification');
        }
      } else {
        debugPrint('[AdminActionChecker] ℹ️ No pending notifications found');
        debugPrint('[AdminActionChecker] This could mean:');
        debugPrint('[AdminActionChecker] 1. No notifications exist for this user');
        debugPrint('[AdminActionChecker] 2. All notifications are already read');
        debugPrint('[AdminActionChecker] 3. Firestore query failed silently');
        debugPrint('[AdminActionChecker] 4. Permission denied (check Firestore rules)');
        setState(() => _checked = true);
      }
    } catch (e, stackTrace) {
      debugPrint('[AdminActionChecker] ❌ Error checking admin actions: $e');
      debugPrint('[AdminActionChecker] Error type: ${e.runtimeType}');
      debugPrint('[AdminActionChecker] Stack trace: $stackTrace');
      debugPrint('[AdminActionChecker] ═══════════════════════════════════════');
      setState(() => _checked = true);
    }
  }

  void _showWarningScreen(Map<String, dynamic> notification, String userId) async {
    try {
      debugPrint('[AdminActionChecker] ═══════════════════════════════════════');
      debugPrint('[AdminActionChecker] 🎯 Showing warning screen');
      debugPrint('[AdminActionChecker] Notification ID: ${notification['id']}');
      debugPrint('[AdminActionChecker] Reason: ${notification['reason']}');
      debugPrint('[AdminActionChecker] ═══════════════════════════════════════');
      
      if (!mounted) {
        debugPrint('[AdminActionChecker] ❌ Widget not mounted, cannot show warning');
        return;
      }
      
      debugPrint('[AdminActionChecker] Navigating to warning screen...');
      debugPrint('[AdminActionChecker] Context: $context');
      debugPrint('[AdminActionChecker] Navigator state: ${Navigator.of(context)}');
      
      // Navigate to full-screen warning
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            debugPrint('[AdminActionChecker] Building WarningScreen widget');
            return WarningScreen(
              warningData: {
                'reason': notification['reason'] ?? 'Violation of community guidelines',
                'warningCount': 1,
                'lastWarningAt': notification['createdAt'],
              },
            );
          },
        ),
      );

      debugPrint('[AdminActionChecker] ✅ User returned from warning screen');
      debugPrint('[AdminActionChecker] Result: $result');
      
      if (!mounted) {
        debugPrint('[AdminActionChecker] ⚠️ Widget unmounted after warning screen');
        return;
      }
      
      // Mark as read after user acknowledges
      debugPrint('[AdminActionChecker] Marking notification as read...');
      debugPrint('[AdminActionChecker] Notification ID: ${notification['id']}');
      
      await _notificationService.markNotificationAsRead(userId, notification['id']);
      debugPrint('[AdminActionChecker] ✅ Notification marked as read');

      // Check if there are more notifications
      debugPrint('[AdminActionChecker] Checking for more notifications...');
      final remaining = await _notificationService.getPendingActionNotifications(userId);
      debugPrint('[AdminActionChecker] Remaining notifications: ${remaining.length}');

      if (remaining.isNotEmpty && mounted) {
        debugPrint('[AdminActionChecker] More notifications found, showing next...');
        // Show next notification
        final nextNotification = remaining[0];
        final nextAction = nextNotification['action'];
        
        debugPrint('[AdminActionChecker] Next action: $nextAction');
        
        if (nextAction == 'warning') {
          _showWarningScreen(nextNotification, userId);
        } else {
          _showActionNotification(nextNotification, userId);
        }
      } else {
        debugPrint('[AdminActionChecker] ✅ All notifications shown');
        // All notifications shown
        if (mounted) {
          setState(() => _checked = true);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[AdminActionChecker] ❌ Error in _showWarningScreen: $e');
      debugPrint('[AdminActionChecker] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _checked = true);
      }
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
