import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  bool _showOnlineStatus = true;
  bool _showDistance = true;
  bool _showAge = true;
  bool _showLastActive = false;
  bool _allowMessagesFromMatches = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      
      final privacy = doc.data()?['privacySettings'] as Map<String, dynamic>?;
      
      if (privacy != null) {
        setState(() {
          _showOnlineStatus = privacy['showOnlineStatus'] ?? true;
          _showDistance = privacy['showDistance'] ?? true;
          _showAge = privacy['showAge'] ?? true;
          _showLastActive = privacy['showLastActive'] ?? false;
          _allowMessagesFromMatches = privacy['allowMessagesFromMatches'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePrivacySetting(String key, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'privacySettings.$key': value,
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
          'Privacy Settings',
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
                  'Profile Visibility',
                  [
                    _buildSwitchTile(
                      'Show Online Status',
                      'Let others see when you\'re active',
                      _showOnlineStatus,
                      (value) {
                        setState(() => _showOnlineStatus = value);
                        _updatePrivacySetting('showOnlineStatus', value);
                      },
                    ),
                    _buildSwitchTile(
                      'Show Distance',
                      'Display your distance from others',
                      _showDistance,
                      (value) {
                        setState(() => _showDistance = value);
                        _updatePrivacySetting('showDistance', value);
                      },
                    ),
                    _buildSwitchTile(
                      'Show Age',
                      'Display your age on your profile',
                      _showAge,
                      (value) {
                        setState(() => _showAge = value);
                        _updatePrivacySetting('showAge', value);
                      },
                    ),
                    _buildSwitchTile(
                      'Show Last Active',
                      'Let matches see when you were last active',
                      _showLastActive,
                      (value) {
                        setState(() => _showLastActive = value);
                        _updatePrivacySetting('showLastActive', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSection(
                  'Messaging',
                  [
                    _buildSwitchTile(
                      'Allow Messages from Matches',
                      'Only matched users can message you',
                      _allowMessagesFromMatches,
                      (value) {
                        setState(() => _allowMessagesFromMatches = value);
                        _updatePrivacySetting('allowMessagesFromMatches', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Your privacy matters. Control what information you share with others.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
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
    ValueChanged<bool> onChanged, {
    bool isPremium = false,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
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