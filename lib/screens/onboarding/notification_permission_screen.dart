import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends State<NotificationPermissionScreen> {
  bool _isLoading = false;
  bool _notificationsEnabled = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationPermissionScreen] $message');
    }
  }

  Future<void> _enableNotifications() async {
    setState(() => _isLoading = true);

    try {
      // In a real app, you would request notification permissions here
      // For now, we'll simulate the permission request
      await Future.delayed(const Duration(milliseconds: 1000));

      // Save notification preference
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseServices.saveOnboardingStep(
          userId: user.uid,
          stepData: {
            'notificationsEnabled': true,
            'profileComplete': 85, // 85% complete
            'onboardingStep': 'notifications_completed',
          },
        );
      }

      setState(() {
        _notificationsEnabled = true;
        _isLoading = false;
      });

      _log('Notifications enabled');
      
      // Auto-continue after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/profile-review');
      }
    } catch (e) {
      _log('Error enabling notifications: $e');
      _showSnackBar('Failed to enable notifications. Please try again.', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipNotifications() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseServices.saveOnboardingStep(
          userId: user.uid,
          stepData: {
            'notificationsEnabled': false,
            'profileComplete': 80, // 80% complete (slightly less for skipping)
            'onboardingStep': 'notifications_skipped',
          },
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/profile-review');
      }
    } catch (e) {
      _log('Error skipping notifications: $e');
      _showSnackBar('Failed to continue. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Notification Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        _notificationsEnabled ? 'Notifications enabled!' : 'Stay in the loop',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        _notificationsEnabled 
                          ? 'Perfect! You\'ll never miss a match or message'
                          : 'Get notified when someone likes you or sends a message',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Benefits
                      if (!_notificationsEnabled) ...[
                        _buildBenefit(
                          icon: '💕',
                          title: 'New matches',
                          description: 'Know instantly when someone likes you',
                        ),
                        const SizedBox(height: 20),
                        _buildBenefit(
                          icon: '💬',
                          title: 'Messages',
                          description: 'Never miss a conversation',
                        ),
                        const SizedBox(height: 20),
                        _buildBenefit(
                          icon: '🎯',
                          title: 'Smart timing',
                          description: 'We\'ll only notify you about important updates',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (!_notificationsEnabled) ...[
                      CustomButton(
                        text: 'Enable Notifications',
                        onPressed: _isLoading ? null : _enableNotifications,
                        isLoading: _isLoading,
                        backgroundColor: Colors.white,
                        textColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _skipNotifications,
                        child: Text(
                          'Maybe later',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ] else ...[
                      CustomButton(
                        text: 'Continue',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/onboarding/profile-review');
                        },
                        backgroundColor: Colors.white,
                        textColor: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.8, // 80% - Step 8 of 10
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '8/10',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
