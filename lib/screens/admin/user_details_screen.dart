import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/user_safety_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<ReportModel> _userReports = [];
  int _totalMatches = 0;
  int _totalLikes = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load reports about this user
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: widget.user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _userReports = reportsSnapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();

      // Load match count
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: widget.user.uid)
          .get();
      _totalMatches = matchesSnapshot.docs.length;

      // Load likes count (swipes where this user was liked)
      final likesSnapshot = await _firestore
          .collection('swipes')
          .where('targetUserId', isEqualTo: widget.user.uid)
          .where('isLike', isEqualTo: true)
          .get();
      _totalLikes = likesSnapshot.docs.length;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  Future<void> _toggleVerification() async {
    try {
      await _firestore.collection('users').doc(widget.user.uid).update({
        'isVerified': !widget.user.isVerified,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.user.isVerified
                  ? 'User verification removed'
                  : 'User verified successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating verification: $e')),
        );
      }
    }
  }

  Future<void> _togglePremium() async {
    try {
      await _firestore.collection('users').doc(widget.user.uid).update({
        'isPremium': !widget.user.isPremium,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.user.isPremium
                  ? 'Premium status removed'
                  : 'Premium status granted',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating premium status: $e')),
        );
      }
    }
  }

  Future<void> _showBlockUserDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${widget.user.name}?'),
        content: const Text(
          'This will block the user from the platform. '
          'They won\'t be able to use the app until unblocked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block User'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserSafetyService.blockUser(
          blockerId: 'admin_system',
          blockedUserId: widget.user.uid,
          reason: 'Admin action',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User blocked successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error blocking user: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteUserDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.user.name}?'),
        content: const Text(
          'This will permanently delete the user account and all associated data. '
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete user document
        await _firestore.collection('users').doc(widget.user.uid).delete();

        // Delete associated data (matches, swipes, etc.)
        final batch = _firestore.batch();

        // Delete matches
        final matchesSnapshot = await _firestore
            .collection('matches')
            .where('users', arrayContains: widget.user.uid)
            .get();
        for (var doc in matchesSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Delete swipes
        final swipesSnapshot = await _firestore
            .collection('swipes')
            .where('userId', isEqualTo: widget.user.uid)
            .get();
        for (var doc in swipesSnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'verify':
                  _toggleVerification();
                  break;
                case 'premium':
                  _togglePremium();
                  break;
                case 'block':
                  _showBlockUserDialog();
                  break;
                case 'delete':
                  _showDeleteUserDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'verify',
                child: Row(
                  children: [
                    Icon(
                      widget.user.isVerified ? Icons.verified_user : Icons.verified,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(widget.user.isVerified ? 'Remove Verification' : 'Verify User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'premium',
                child: Row(
                  children: [
                    Icon(
                      widget.user.isPremium ? Icons.star_border : Icons.star,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(widget.user.isPremium ? 'Remove Premium' : 'Grant Premium'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete User'),
                  ],
                ),
              ),
            ],
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
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildReportsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.user.photos.isNotEmpty
                        ? NetworkImage(widget.user.photos[0])
                        : null,
                    child: widget.user.photos.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  if (widget.user.isVerified)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.user.name),
            _buildInfoRow('Phone', widget.user.phoneNumber.isNotEmpty ? widget.user.phoneNumber : 'Not provided'),
            _buildInfoRow('Gender', widget.user.gender.isNotEmpty ? widget.user.gender : 'Not specified'),
            if (widget.user.dateOfBirth != null)
              _buildInfoRow('Age', '${_calculateAge(widget.user.dateOfBirth!)} years old'),
            _buildInfoRow('Interests', widget.user.interests.isNotEmpty ? widget.user.interests.join(', ') : 'Not provided'),
            if (widget.user.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Bio:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.user.bio, style: const TextStyle(fontSize: 14)),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (widget.user.isVerified)
                  Chip(
                    label: const Text('Verified', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    avatar: const Icon(Icons.verified, size: 16, color: Colors.blue),
                  ),
                if (widget.user.isPremium)
                  Chip(
                    label: const Text('Premium', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.amber.withOpacity(0.1),
                    avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Matches',
                    _totalMatches.toString(),
                    Icons.favorite,
                    Colors.pink,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Likes Received',
                    _totalLikes.toString(),
                    Icons.thumb_up,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Reports',
                    _userReports.length.toString(),
                    Icons.report,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Last Active',
              widget.user.lastActive != null
                  ? _formatDateTime(widget.user.lastActive!)
                  : 'Never',
            ),
            _buildInfoRow(
              'Account Created',
              widget.user.createdAt != null
                  ? _formatDateTime(widget.user.createdAt!)
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildReportsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports (${_userReports.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_userReports.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No reports filed against this user',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userReports.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final report = _userReports[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.report, color: Colors.orange),
                    ),
                    title: Text(
                      report.reason.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _formatDateTime(report.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: _buildStatusChip(report.status),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        break;
      case ReportStatus.underReview:
        color = Colors.blue;
        break;
      case ReportStatus.resolved:
        color = Colors.green;
        break;
      case ReportStatus.dismissed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
