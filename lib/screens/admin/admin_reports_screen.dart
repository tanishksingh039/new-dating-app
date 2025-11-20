import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/user_safety_service.dart';
import 'report_details_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Admin Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.blue),
              title: const Text('Dashboard'),
              subtitle: const Text('View statistics and analytics'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dashboard coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.green),
              title: const Text('User Management'),
              subtitle: const Text('Manage all users'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User Management coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Banned Users'),
              subtitle: const Text('View banned and suspended users'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Banned Users list coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.purple),
              title: const Text('Analytics'),
              subtitle: const Text('Report trends and statistics'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Admin Settings'),
              subtitle: const Text('Configure admin panel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(ReportModel report, ReportStatus newStatus) async {
    try {
      await UserSafetyService.updateReportStatus(
        reportId: report.id,
        status: newStatus,
        adminId: 'admin_user', // In a real app, this would be the current admin's ID
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating report: $e')),
        );
      }
    }
  }

  Future<void> _showBanOptionsDialog(ReportModel report) async {
    final action = await showDialog<AdminAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Take Action on ${report.reportedUserName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an action to take:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            _buildActionOption(
              icon: Icons.warning,
              title: 'Issue Warning',
              description: 'Send a warning to the user',
              color: Colors.orange,
              action: AdminAction.warning,
            ),
            const SizedBox(height: 8),
            _buildActionOption(
              icon: Icons.block,
              title: 'Ban for 7 Days',
              description: 'Temporarily suspend account',
              color: Colors.red,
              action: AdminAction.tempBan7Days,
            ),
            const SizedBox(height: 8),
            _buildActionOption(
              icon: Icons.block_outlined,
              title: 'Permanent Ban',
              description: 'Permanently ban this user',
              color: Colors.red.shade900,
              action: AdminAction.permanentBan,
            ),
            const SizedBox(height: 8),
            _buildActionOption(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              description: 'Permanently delete user account',
              color: Colors.black,
              action: AdminAction.accountDeleted,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action != null && mounted) {
      await _takeAdminAction(report, action);
    }
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required AdminAction action,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, action),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _takeAdminAction(ReportModel report, AdminAction action) async {
    try {
      // Apply ban if needed
      if (action == AdminAction.tempBan7Days || action == AdminAction.permanentBan) {
        await UserSafetyService.banUser(
          userId: report.reportedUserId,
          banType: action,
          reason: 'Reported for ${report.reason.displayName}',
        );
      }

      // Update report with action taken
      await UserSafetyService.updateReportStatus(
        reportId: report.id,
        status: ReportStatus.resolved,
        adminAction: action,
        adminNotes: 'Action taken: ${action.displayName}',
        adminId: 'admin_user',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.displayName} - Report resolved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking action: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Report Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Admin Settings',
            onPressed: () {
              _showAdminMenu(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Reports',
            onPressed: () {
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink,
          tabs: const [
            Tab(
              text: 'All',
              icon: Icon(Icons.list, size: 20),
            ),
            Tab(
              text: 'Pending',
              icon: Icon(Icons.pending, size: 20),
            ),
            Tab(
              text: 'Reviewing',
              icon: Icon(Icons.rate_review, size: 20),
            ),
            Tab(
              text: 'Resolved',
              icon: Icon(Icons.check_circle, size: 20),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reports',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No reports found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Parse reports from snapshot
          final allReports = snapshot.data!.docs
              .map((doc) {
                try {
                  return ReportModel.fromMap(doc.data() as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing report: $e');
                  return null;
                }
              })
              .whereType<ReportModel>()
              .toList();

          final pendingReports = allReports
              .where((r) => r.status == ReportStatus.pending)
              .toList();
          final reviewingReports = allReports
              .where((r) => r.status == ReportStatus.underReview)
              .toList();
          final resolvedReports = allReports
              .where((r) =>
                  r.status == ReportStatus.resolved ||
                  r.status == ReportStatus.dismissed)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReportsList(allReports),
              _buildReportsList(pendingReports),
              _buildReportsList(reviewingReports),
              _buildReportsList(resolvedReports),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportsList(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailsScreen(report: report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(report.status),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Report reason and description
              Row(
                children: [
                  Icon(
                    _getReasonIcon(report.reason),
                    size: 20,
                    color: Colors.pink,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    report.reason.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                report.description.length > 100
                    ? '${report.description.substring(0, 100)}...'
                    : report.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 12),

              // Reported User info (from report model)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: report.reportedUserPhoto != null
                          ? NetworkImage(report.reportedUserPhoto!)
                          : null,
                      child: report.reportedUserPhoto == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reported User',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            report.reportedUserName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (report.evidenceImages.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '${report.evidenceImages.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Quick actions for pending/reviewing reports
              if (report.status == ReportStatus.pending || report.status == ReportStatus.underReview) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (report.status == ReportStatus.pending)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateReportStatus(report, ReportStatus.underReview),
                          child: const Text('Review'),
                        ),
                      ),
                    if (report.status == ReportStatus.pending) const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showBanOptionsDialog(report),
                        icon: const Icon(Icons.gavel, size: 18),
                        label: const Text('Take Action'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateReportStatus(report, ReportStatus.dismissed),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  IconData _getReasonIcon(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriateContent:
        return Icons.warning;
      case ReportReason.harassment:
        return Icons.report_problem;
      case ReportReason.spam:
        return Icons.block;
      case ReportReason.fakeProfile:
        return Icons.person_remove;
      case ReportReason.underage:
        return Icons.child_care;
      case ReportReason.violence:
        return Icons.gavel;
      case ReportReason.hateSpeech:
        return Icons.record_voice_over;
      case ReportReason.other:
        return Icons.help_outline;
    }
  }

  Future<UserModel?> _getUserInfo(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
