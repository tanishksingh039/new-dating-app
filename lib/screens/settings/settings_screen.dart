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
          subject: 'My shooLuv Data',
          text: 'Your personal data export from shooLuv',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data, matches, and messages will be permanently deleted.',
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

    // Ask for password confirmation
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Confirm Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter your password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found. Please login again.')),
          );
        }
        return;
      }
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .delete();

      // Delete swipes
      final swipes = await FirebaseFirestore.instance
          .collection('swipes')
          .where('userId', isEqualTo: currentUserId)
          .get();
      for (var doc in swipes.docs) {
        await doc.reference.delete();
      }

      // Delete matches
      final matches = await FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: currentUserId)
          .get();
      for (var doc in matches.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
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
                    _buildSettingTile(
                      Icons.verified_user,
                      'Verify Profile',
                      'Verify with liveness detection (anti-spoofing)',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LivenessVerificationScreen(),
                          ),
                        );
                      },
                      iconColor: Colors.blue,
                    ),
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
                  'Preferences',
                  [
                    _buildSettingTile(
                      Icons.straighten,
                      'Distance Unit',
                      'Kilometers',
                      () {
                        _showDistanceUnitDialog();
                      },
                    ),
                    _buildSettingTile(
                      Icons.cake,
                      'Show Age',
                      'Display age on profile',
                      () {
                        // TODO: Toggle age display
                      },
                      hasSwitch: true,
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

  void _showDistanceUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Distance Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Kilometers (km)'),
              value: 'km',
              groupValue: 'km',
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Distance unit updated')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Miles (mi)'),
              value: 'mi',
              groupValue: 'km',
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Distance unit updated')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}