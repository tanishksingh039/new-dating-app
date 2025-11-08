import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Push Notifications
  bool _pushEnabled = true;
  bool _newMatchNotif = true;
  bool _messageNotif = true;
  bool _likeNotif = true;
  bool _superLikeNotif = true;

  // Email Notifications
  bool _emailEnabled = false;
  bool _emailMatches = false;
  bool _emailMessages = false;
  bool _emailPromotions = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final notifSettings =
          doc.data()?['notificationSettings'] as Map<String, dynamic>?;

      if (notifSettings != null) {
        setState(() {
          // Push
          _pushEnabled = notifSettings['pushEnabled'] ?? true;
          _newMatchNotif = notifSettings['newMatchNotif'] ?? true;
          _messageNotif = notifSettings['messageNotif'] ?? true;
          _likeNotif = notifSettings['likeNotif'] ?? true;
          _superLikeNotif = notifSettings['superLikeNotif'] ?? true;

          // Email
          _emailEnabled = notifSettings['emailEnabled'] ?? false;
          _emailMatches = notifSettings['emailMatches'] ?? false;
          _emailMessages = notifSettings['emailMessages'] ?? false;
          _emailPromotions = notifSettings['emailPromotions'] ?? false;

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'notificationSettings.$key': value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating setting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 10),
                _buildSection(
                  'Push Notifications',
                  [
                    _buildSwitchTile(
                      'Enable Push Notifications',
                      'Receive notifications on your device',
                      _pushEnabled,
                      (value) {
                        setState(() => _pushEnabled = value);
                        _updateNotificationSetting('pushEnabled', value);
                      },
                    ),
                    if (_pushEnabled) ...[
                      _buildSwitchTile(
                        'New Matches',
                        'Get notified when you have a new match',
                        _newMatchNotif,
                        (value) {
                          setState(() => _newMatchNotif = value);
                          _updateNotificationSetting('newMatchNotif', value);
                        },
                      ),
                      _buildSwitchTile(
                        'Messages',
                        'Get notified when someone sends you a message',
                        _messageNotif,
                        (value) {
                          setState(() => _messageNotif = value);
                          _updateNotificationSetting('messageNotif', value);
                        },
                      ),
                      _buildSwitchTile(
                        'Likes',
                        'Get notified when someone likes you',
                        _likeNotif,
                        (value) {
                          setState(() => _likeNotif = value);
                          _updateNotificationSetting('likeNotif', value);
                        },
                      ),
                      _buildSwitchTile(
                        'Super Likes',
                        'Get notified when someone super likes you',
                        _superLikeNotif,
                        (value) {
                          setState(() => _superLikeNotif = value);
                          _updateNotificationSetting('superLikeNotif', value);
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _buildSection(
                  'Email Notifications',
                  [
                    _buildSwitchTile(
                      'Enable Email Notifications',
                      'Receive notifications via email',
                      _emailEnabled,
                      (value) {
                        setState(() => _emailEnabled = value);
                        _updateNotificationSetting('emailEnabled', value);
                      },
                    ),
                    if (_emailEnabled) ...[
                      _buildSwitchTile(
                        'Match Updates',
                        'Get emails about new matches',
                        _emailMatches,
                        (value) {
                          setState(() => _emailMatches = value);
                          _updateNotificationSetting('emailMatches', value);
                        },
                      ),
                      _buildSwitchTile(
                        'Message Notifications',
                        'Get emails about new messages',
                        _emailMessages,
                        (value) {
                          setState(() => _emailMessages = value);
                          _updateNotificationSetting('emailMessages', value);
                        },
                      ),
                      _buildSwitchTile(
                        'Promotions & Updates',
                        'Receive news and special offers',
                        _emailPromotions,
                        (value) {
                          setState(() => _emailPromotions = value);
                          _updateNotificationSetting('emailPromotions', value);
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_active,
                          size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        'Stay updated with your matches and messages',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.pink,
    );
  }
}