import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'account_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';
import '../verification/liveness_verification_screen.dart';
import '../safety/blocked_users_screen.dart';
import '../admin/admin_reports_screen.dart';
import '../admin/admin_login_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/community_guidelines_screen.dart';
import '../safety/my_reports_screen.dart';
import '../../services/account_deletion_service_v2.dart';

// Add Timestamp import
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final String currentUserId;
  bool _isLoading = false;
  bool _isVerified = false;
  DateTime? _verificationDate;
  
  // Admin user IDs
  final List<String> _adminUserIds = [
    'admin_user',
    'tanishk_admin',
    'shooluv_admin',
    'dev_admin',
  ];
  
  bool get _isAdmin => _adminUserIds.contains(currentUserId);

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    } else {
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _isVerified = data?['isVerified'] ?? false;
          final verificationTimestamp = data?['verificationDate'] as Timestamp?;
          _verificationDate = verificationTimestamp?.toDate();
        });
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
    }
  }

  // Helper method to convert Firestore data to JSON-serializable format
  Map<String, dynamic> _convertFirestoreData(Map<String, dynamic> data) {
    final Map<String, dynamic> converted = {};
    
    data.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to ISO 8601 string
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        // Recursively convert nested maps
        converted[key] = _convertFirestoreData(Map<String, dynamic>.from(value));
      } else if (value is List) {
        // Convert lists
        converted[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map) {
            return _convertFirestoreData(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });
    
    return converted;
  }

  Future<void> _downloadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      // Collect all user data and convert Timestamps
      final Map<String, dynamic> userData = {
        'profile': _convertFirestoreData(userDoc.data() ?? {}),
        'exportDate': DateTime.now().toIso8601String(),
        'userId': currentUserId,
      };

      // Fetch matches
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: currentUserId)
          .get();
      userData['matches'] = matchesSnapshot.docs
          .map((doc) => _convertFirestoreData(doc.data()))
          .toList();

      // Fetch swipes
      final swipesSnapshot = await FirebaseFirestore.instance
          .collection('swipes')
          .where('userId', isEqualTo: currentUserId)
          .get();
      userData['swipes'] = swipesSnapshot.docs
          .map((doc) => _convertFirestoreData(doc.data()))
          .toList();

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(userData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/shooluv_data_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      setState(() => _isLoading = false);

      if (mounted) {
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'My ShooLuv Data',
          text: 'Your personal data export from ShooLuv',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    // First confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.\n\n'
          'The following will be permanently deleted:\n'
          '• Your profile and photos\n'
          '• All matches and messages\n'
          '• Swipes and preferences\n'
          '• Reports and blocks\n'
          '• All other account data',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Second confirmation dialog
    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your last chance to cancel.\n\n'
          'Are you absolutely sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    );

    if (finalConfirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting your account...\nThis may take a moment.'),
              ],
            ),
          ),
        );
      }

      // Use the comprehensive deletion service V2
      await AccountDeletionServiceV2.deleteAccount();

      // Close progress dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message and navigate to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      // Close progress dialog if open
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Failed to delete account:\n\n$e\n\n'
              'Please try again or contact support if the problem persists.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (_isAdmin) const SizedBox(height: 10),
                _buildSection(
                  'Account',
                  [
                    _buildVerificationTile(),
                    _buildSettingTile(
                      Icons.person,
                      'Account Settings',
                      'Phone number, email, password',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      Icons.notifications,
                      'Notifications',
                      'Push notifications, email preferences',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSection(
                  'Privacy & Safety',
                  [
                    _buildSettingTile(
                      Icons.lock,
                      'Privacy Settings',
                      'Control who can see your profile',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      Icons.block,
                      'Blocked Users',
                      'Manage blocked accounts',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlockedUsersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      Icons.report_outlined,
                      'My Reports',
                      'View your submitted reports',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyReportsScreen(),
                          ),
                        );
                      },
                      iconColor: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSection(
                  'Data & Privacy',
                  [
                    _buildSettingTile(
                      Icons.download,
                      'Download My Data',
                      'Export all your data (GDPR/CCPA)',
                      _downloadUserData,
                      iconColor: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSection(
                  'Legal & Support',
                  [
                    _buildSettingTile(
                      Icons.shield,
                      'Community Guidelines',
                      'Rules and best practices',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CommunityGuidelinesScreen(),
                          ),
                        );
                      },
                      iconColor: Colors.green,
                    ),
                    _buildSettingTile(
                      Icons.privacy_tip,
                      'Privacy Policy',
                      'How we handle your data',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      iconColor: Colors.blue,
                    ),
                    _buildSettingTile(
                      Icons.description,
                      'Terms of Service',
                      'User agreement and terms',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                      iconColor: Colors.purple,
                    ),
                    _buildSettingTile(
                      Icons.help,
                      'Help & Support',
                      'Contact: support@shooluv.com',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email us at: support@shooluv.com'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Admin section (only for admin users)
                if (_isAdmin)
                  _buildSection(
                    'Admin',
                    [
                      _buildSettingTile(
                        Icons.dashboard,
                        'Admin Dashboard',
                        'View real-time statistics and analytics',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminLoginScreen(),
                            ),
                          );
                        },
                        iconColor: Colors.purple,
                      ),
                      _buildSettingTile(
                        Icons.report,
                        'Manage Reports',
                        'Review and manage user reports',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminReportsScreen(),
                            ),
                          );
                        },
                        iconColor: Colors.orange,
                      ),
                    ],
                  ),
                if (currentUserId == 'admin_user') const SizedBox(height: 10),
                _buildSection(
                  'Account Actions',
                  [
                    _buildSettingTile(
                      Icons.logout,
                      'Logout',
                      'Sign out of your account',
                      _logout,
                      iconColor: Colors.orange,
                    ),
                    _buildSettingTile(
                      Icons.delete_forever,
                      'Delete Account',
                      'Permanently delete your account',
                      _deleteAccount,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildVerificationTile() {
    if (_isVerified) {
      // User is already verified - show locked/completed state
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.verified, color: Colors.green, size: 22),
        ),
        title: Row(
          children: [
            const Text(
              'Profile Verified',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
        subtitle: Text(
          _verificationDate != null
              ? 'Verified on ${_formatDate(_verificationDate!)}'
              : 'Your profile is verified',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: const Text(
            'VERIFIED',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // Show info dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Verified Profile'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your profile has been successfully verified with liveness detection.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  if (_verificationDate != null) ...[
                    Text(
                      'Verified on: ${_formatDate(_verificationDate!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    '✓ Anti-spoofing verified\n'
                    '✓ Liveness detection passed\n'
                    '✓ Profile photo matched',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // User is not verified - show verification option
      return _buildSettingTile(
        Icons.verified_user,
        'Verify Profile',
        'Verify with liveness detection (anti-spoofing)',
        () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LivenessVerificationScreen(),
            ),
          );
          
          // Refresh verification status after returning
          if (result == true || mounted) {
            await _checkVerificationStatus();
          }
        },
        iconColor: Colors.blue,
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[600],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? iconColor,
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.pink).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? Colors.pink, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12, 
          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[600]
        ),
      ),
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged ?? (value) {},
              activeColor: iconColor ?? Colors.pink,
            )
          : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: hasSwitch ? null : onTap,
    );
  }

}