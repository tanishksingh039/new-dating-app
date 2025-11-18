import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/admin_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLeaderboardControlScreen extends StatefulWidget {
  final String adminUserId;

  const AdminLeaderboardControlScreen({
    Key? key,
    required this.adminUserId,
  }) : super(key: key);

  @override
  State<AdminLeaderboardControlScreen> createState() =>
      _AdminLeaderboardControlScreenState();
}

class _AdminLeaderboardControlScreenState
    extends State<AdminLeaderboardControlScreen> {
  final AdminProfileService _adminService = AdminProfileService();
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _currentEntry;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _rankController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load profile data
      _profileData = await _adminService.getAdminProfile(widget.adminUserId);

      // Load leaderboard entry
      _currentEntry =
          await _adminService.getAdminLeaderboardEntry(widget.adminUserId);

      if (_currentEntry != null) {
        setState(() {
          _pointsController.text = _currentEntry!['monthlyScore']?.toString() ?? '0';
          _rankController.text = _currentEntry!['monthlyRank']?.toString() ?? '';
          _badgeController.text = 'Admin'; // Badge not used in rewards system
        });
      }
    } catch (e) {
      _showError('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLeaderboard() async {
    if (_pointsController.text.trim().isEmpty) {
      _showError('Points are required');
      return;
    }

    final points = int.tryParse(_pointsController.text.trim());
    if (points == null) {
      _showError('Invalid points value');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final rank = _rankController.text.trim().isNotEmpty
          ? int.tryParse(_rankController.text.trim())
          : null;

      await _adminService.updateAdminLeaderboard(
        userId: widget.adminUserId,
        points: points,
        rank: rank,
        badge: _badgeController.text.trim().isNotEmpty
            ? _badgeController.text.trim()
            : 'Admin',
      );

      _showSuccess('Leaderboard updated successfully!');
      await _loadData();
    } catch (e) {
      _showError('Error updating leaderboard: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _removeFromLeaderboard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Leaderboard'),
        content: const Text(
            'Are you sure you want to remove your profile from the leaderboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.removeFromLeaderboard(widget.adminUserId);
        _showSuccess('Removed from leaderboard');
        setState(() {
          _currentEntry = null;
          _pointsController.clear();
          _rankController.clear();
          _badgeController.clear();
        });
      } catch (e) {
        _showError('Error removing from leaderboard: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard Control'),
        actions: [
          if (_currentEntry != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _removeFromLeaderboard,
              tooltip: 'Remove from Leaderboard',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.pink.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: _profileData != null &&
                                  (_profileData!['photos'] as List?)
                                          ?.isNotEmpty ==
                                      true
                              ? NetworkImage(_profileData!['photos'][0])
                              : null,
                          child: _profileData == null ||
                                  (_profileData!['photos'] as List?)?.isEmpty ==
                                      true
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profileData?['name'] ?? widget.adminUserId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.adminUserId,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.admin_panel_settings,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Status
                  if (_currentEntry != null) ...[
                    const Text(
                      'Current Leaderboard Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Monthly Points:',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                _currentEntry!['monthlyScore']?.toString() ?? '0',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (_currentEntry!['monthlyRank'] != null &&
                              _currentEntry!['monthlyRank'] > 0) ...[
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Rank:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  '#${_currentEntry!['monthlyRank']}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Control Panel
                  const Text(
                    'Leaderboard Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set any points and rank for your profile. Changes are instant and live.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Points Field
                  TextField(
                    controller: _pointsController,
                    decoration: InputDecoration(
                      labelText: 'Points',
                      hintText: 'Enter points (e.g., 10000)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.stars),
                      suffixText: 'pts',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),

                  // Rank Field
                  TextField(
                    controller: _rankController,
                    decoration: InputDecoration(
                      labelText: 'Rank (Optional)',
                      hintText: 'Enter rank (e.g., 1)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.emoji_events),
                      helperText: 'Leave empty for auto-rank',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),

                  // Badge Field
                  TextField(
                    controller: _badgeController,
                    decoration: InputDecoration(
                      labelText: 'Badge',
                      hintText: 'Enter badge name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.military_tech),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Points Buttons
                  const Text(
                    'Quick Points',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: double.infinity),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickPointButton(1000),
                        _buildQuickPointButton(5000),
                        _buildQuickPointButton(10000),
                        _buildQuickPointButton(50000),
                        _buildQuickPointButton(100000),
                        _buildQuickPointButton(999999),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateLeaderboard,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.update),
                      label: Text(_isSaving
                          ? 'Updating...'
                          : 'Update Leaderboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Changes are instant and work even when the app is live. Your profile will appear on the leaderboard immediately.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickPointButton(int points) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _pointsController.text = points.toString();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade50,
        foregroundColor: Colors.purple.shade700,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.purple.shade200),
        ),
      ),
      child: Text(
        points >= 1000 ? '${points ~/ 1000}K' : points.toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
