import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'account_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final String currentUserId;
  bool _isLoading = false;

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
                const SizedBox(height: 10),
                _buildSection(
                  'Account',
                  [
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
                        // TODO: Navigate to blocked users screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon!')),
                        );
                      },
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
                  'Support',
                  [
                    _buildSettingTile(
                      Icons.help,
                      'Help & Support',
                      'FAQs, contact us',
                      () {
                        // TODO: Navigate to help screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon!')),
                        );
                      },
                    ),
                    _buildSettingTile(
                      Icons.info,
                      'About',
                      'Terms, privacy policy, version',
                      () {
                        // TODO: Navigate to about screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
      color: Colors.white,
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
                color: Colors.grey[600],
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
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: hasSwitch
          ? Switch(
              value: true,
              onChanged: (value) {},
              activeColor: Colors.pink,
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