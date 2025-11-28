import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';
import '../../services/user_safety_service.dart';
import 'report_details_screen.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({Key? key}) : super(key: key);

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab>
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

  Future<void> _updateReportStatus(ReportModel report, ReportStatus newStatus) async {
    try {
      debugPrint('[AdminReportsTab] Updating report status: ${report.id}');
      debugPrint('[AdminReportsTab] New status: ${newStatus.name}');
      
      await UserSafetyService.updateReportStatus(
        reportId: report.id,
        status: newStatus,
        adminId: 'admin_user',
      );
      
      debugPrint('[AdminReportsTab] ✅ Status updated successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[AdminReportsTab] ❌ Error updating report: $e');
      debugPrint('[AdminReportsTab] Error type: ${e.runtimeType}');
      debugPrint('[AdminReportsTab] Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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

    if (action != null) {
      _confirmAction(report, action);
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
                      fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(ReportModel report, AdminAction action) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(
          'Are you sure you want to ${action.displayName.toLowerCase()} ${report.reportedUserName}?',
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
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        debugPrint('[AdminReportsTab] Taking action: ${action.name} on report: ${report.id}');
        debugPrint('[AdminReportsTab] Report ID: ${report.id}');
        debugPrint('[AdminReportsTab] Reported User: ${report.reportedUserName}');
        debugPrint('[AdminReportsTab] Reported User ID: ${report.reportedUserId}');
        
        // Step 1: Update the reported user's account based on action
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(report.reportedUserId);
        
        Map<String, dynamic> userUpdates = {};
        String notificationTitle = '';
        String notificationBody = '';
        
        switch (action) {
          case AdminAction.warning:
            userUpdates = {
              'accountStatus': 'warned',
              'warningCount': FieldValue.increment(1),
              'lastWarningAt': FieldValue.serverTimestamp(),
              'lastWarningReason': report.reason.displayName,
            };
            notificationTitle = '⚠️ Warning Issued';
            notificationBody = 'You have received a warning for ${report.reason.displayName}. Please review our community guidelines.';
            break;
            
          case AdminAction.tempBan7Days:
            final banUntil = DateTime.now().add(const Duration(days: 7));
            userUpdates = {
              'accountStatus': 'banned',
              'isBanned': true,
              'bannedUntil': Timestamp.fromDate(banUntil),
              'bannedAt': FieldValue.serverTimestamp(),
              'banReason': report.reason.displayName,
              'banType': 'temporary',
            };
            notificationTitle = '🚫 Account Temporarily Suspended';
            notificationBody = 'Your account has been suspended for 7 days due to ${report.reason.displayName}. You can access your account again after ${banUntil.day}/${banUntil.month}/${banUntil.year}.';
            break;
            
          case AdminAction.permanentBan:
            userUpdates = {
              'accountStatus': 'banned',
              'isBanned': true,
              'bannedAt': FieldValue.serverTimestamp(),
              'banReason': report.reason.displayName,
              'banType': 'permanent',
            };
            notificationTitle = '⛔ Account Permanently Banned';
            notificationBody = 'Your account has been permanently banned due to ${report.reason.displayName}. This action cannot be reversed.';
            break;
            
          case AdminAction.accountDeleted:
            userUpdates = {
              'accountStatus': 'deleted',
              'isDeleted': true,
              'deletedAt': FieldValue.serverTimestamp(),
              'deletedReason': report.reason.displayName,
              'deletedBy': 'admin',
            };
            notificationTitle = '🗑️ Account Deleted';
            notificationBody = 'Your account has been permanently deleted due to ${report.reason.displayName}. All your data will be removed.';
            break;
            
          case AdminAction.none:
            // No action taken, just return
            debugPrint('[AdminReportsTab] No action selected');
            return;
        }
        
        // Update user account
        debugPrint('[AdminReportsTab] Updating user account: ${report.reportedUserId}');
        debugPrint('[AdminReportsTab] Updates: $userUpdates');
        
        try {
          await userRef.update(userUpdates);
          debugPrint('[AdminReportsTab] ✅ User account updated');
        } catch (e, stackTrace) {
          debugPrint('[AdminReportsTab] ❌ Error updating user: $e');
          debugPrint('[AdminReportsTab] Error type: ${e.runtimeType}');
          debugPrint('[AdminReportsTab] Stack trace: $stackTrace');
          
          if (e.toString().contains('permission-denied')) {
            debugPrint('[AdminReportsTab] 🔐 PERMISSION DENIED on user update');
            debugPrint('[AdminReportsTab] ═══════════════════════════════════════');
            debugPrint('[AdminReportsTab] TROUBLESHOOTING:');
            debugPrint('[AdminReportsTab] 1. Check Firestore rules are published');
            debugPrint('[AdminReportsTab] 2. Verify rule: allow update: if true;');
            debugPrint('[AdminReportsTab] 3. Collection: users');
            debugPrint('[AdminReportsTab] 4. Copy rules from FIRESTORE_RULES_ADMIN_BYPASS.txt');
            debugPrint('[AdminReportsTab] ═══════════════════════════════════════');
          }
          rethrow;
        }
        
        // Step 2: Send notification to the reported user
        debugPrint('[AdminReportsTab] Sending notification to user');
        debugPrint('[AdminReportsTab] User ID: ${report.reportedUserId}');
        debugPrint('[AdminReportsTab] Notification Title: $notificationTitle');
        debugPrint('[AdminReportsTab] Notification Body: $notificationBody');
        
        try {
          final notificationRef = await FirebaseFirestore.instance
              .collection('users')
              .doc(report.reportedUserId)
              .collection('notifications')
              .add({
            'title': notificationTitle,
            'body': notificationBody,
            'type': 'admin_action',
            'data': {
              'screen': 'settings',
              'action': action.name,
              'reason': report.reason.displayName,
              'reportId': report.id,
            },
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
            'priority': 'high',
          });
          
          debugPrint('[AdminReportsTab] ✅ Notification sent to user');
          debugPrint('[AdminReportsTab] Notification ID: ${notificationRef.id}');
          debugPrint('[AdminReportsTab] Path: users/${report.reportedUserId}/notifications/${notificationRef.id}');
        } catch (e, stackTrace) {
          debugPrint('[AdminReportsTab] ❌ Error sending notification: $e');
          debugPrint('[AdminReportsTab] Error type: ${e.runtimeType}');
          debugPrint('[AdminReportsTab] Stack trace: $stackTrace');
          
          if (e.toString().contains('permission-denied')) {
            debugPrint('[AdminReportsTab] 🔐 PERMISSION DENIED on notification');
            debugPrint('[AdminReportsTab] ═══════════════════════════════════════');
            debugPrint('[AdminReportsTab] TROUBLESHOOTING:');
            debugPrint('[AdminReportsTab] 1. Check Firestore rules are published');
            debugPrint('[AdminReportsTab] 2. Verify rule: allow write: if true;');
            debugPrint('[AdminReportsTab] 3. Subcollection: users/{userId}/notifications');
            debugPrint('[AdminReportsTab] 4. Copy rules from FIRESTORE_RULES_ADMIN_BYPASS.txt');
            debugPrint('[AdminReportsTab] ═══════════════════════════════════════');
          }
        }
        
        // Step 3: Update report with admin action
        debugPrint('[AdminReportsTab] Updating report status to resolved');
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(report.id)
              .update({
            'adminAction': action.name,
            'adminId': 'admin_user',
            'status': ReportStatus.resolved.name,
            'resolvedAt': FieldValue.serverTimestamp(),
            'actionTaken': true,
            'actionDetails': {
              'action': action.name,
              'timestamp': FieldValue.serverTimestamp(),
              'notificationSent': true,
            },
          });
          debugPrint('[AdminReportsTab] ✅ Report updated to resolved');
        } catch (e) {
          debugPrint('[AdminReportsTab] ⚠️ Error updating report: $e');
          if (e.toString().contains('permission-denied')) {
            debugPrint('[AdminReportsTab] 🔐 PERMISSION DENIED on report update');
          }
        }
        
        debugPrint('[AdminReportsTab] ✅ Action completed successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action taken: ${action.displayName}\nUser has been notified'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e, stackTrace) {
        debugPrint('[AdminReportsTab] ❌ Error taking action: $e');
        debugPrint('[AdminReportsTab] Error type: ${e.runtimeType}');
        debugPrint('[AdminReportsTab] Stack trace: $stackTrace');
        
        if (e.toString().contains('permission-denied')) {
          debugPrint('[AdminReportsTab] 🔐 PERMISSION DENIED');
          debugPrint('[AdminReportsTab] Check Firestore rules for reports collection');
          debugPrint('[AdminReportsTab] Rule should be: allow update: if true;');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error taking action: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pink,
            tabs: const [
              Tab(text: 'All', icon: Icon(Icons.list, size: 20)),
              Tab(text: 'Pending', icon: Icon(Icons.pending, size: 20)),
              Tab(text: 'Reviewing', icon: Icon(Icons.rate_review, size: 20)),
              Tab(text: 'Resolved', icon: Icon(Icons.check_circle, size: 20)),
            ],
          ),
        ),
        
        // Tab Bar View
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('[AdminReportsTab] Error loading reports: ${snapshot.error}');
                debugPrint('[AdminReportsTab] Error type: ${snapshot.error.runtimeType}');
                
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
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {}); // Trigger rebuild
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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

              // Parse reports
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
        ),
      ],
    );
  }

  Widget _buildReportsList(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text(
          'No reports in this category',
          style: TextStyle(color: Colors.grey),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailsScreen(report: report),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
                    child: Icon(
                      _getStatusIcon(report.status),
                      color: _getStatusColor(report.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.reportedUserName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Reporter ID: ${report.reporterId}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(report.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.report, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    report.reason.displayName,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportDetailsScreen(report: report),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View'),
                      ),
                      if (report.status == ReportStatus.pending ||
                          report.status == ReportStatus.underReview)
                        TextButton.icon(
                          onPressed: () => _showBanOptionsDialog(report),
                          icon: const Icon(Icons.gavel, size: 16),
                          label: const Text('Action'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.underReview:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.pending;
      case ReportStatus.underReview:
        return Icons.rate_review;
      case ReportStatus.resolved:
        return Icons.check_circle;
      case ReportStatus.dismissed:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
