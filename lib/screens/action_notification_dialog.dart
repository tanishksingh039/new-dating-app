import 'package:flutter/material.dart';
import '../services/action_notification_service.dart';
import '../services/ban_enforcement_service.dart';

class ActionNotificationDialog extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;

  const ActionNotificationDialog({
    Key? key,
    required this.notification,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<ActionNotificationDialog> createState() => _ActionNotificationDialogState();
}

class _ActionNotificationDialogState extends State<ActionNotificationDialog> {
  late Map<String, dynamic> actionDetails;

  @override
  void initState() {
    super.initState();
    actionDetails = ActionNotificationService().getActionDetails(widget.notification);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing by back button
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  actionDetails['icon'] ?? '📢',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                actionDetails['title'] ?? 'Admin Action',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getMessageBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getMessageBorderColor()),
                ),
                child: Text(
                  actionDetails['message'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (actionDetails['actionable'] == true)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your account access has been restricted.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Acknowledge button
              ElevatedButton(
                onPressed: () {
                  widget.onDismiss();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconBackgroundColor() {
    switch (actionDetails['color']) {
      case 'orange':
        return Colors.orange.shade100;
      case 'red':
      case 'darkRed':
        return Colors.red.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  Color _getMessageBackgroundColor() {
    switch (actionDetails['color']) {
      case 'orange':
        return Colors.orange.shade50;
      case 'red':
      case 'darkRed':
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _getMessageBorderColor() {
    switch (actionDetails['color']) {
      case 'orange':
        return Colors.orange.shade300;
      case 'red':
      case 'darkRed':
        return Colors.red.shade300;
      default:
        return Colors.blue.shade300;
    }
  }

  Color _getButtonColor() {
    switch (actionDetails['color']) {
      case 'orange':
        return Colors.orange;
      case 'red':
      case 'darkRed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
