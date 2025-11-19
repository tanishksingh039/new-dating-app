import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/report_model.dart';
import '../../services/user_safety_service.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  bool _isLoading = true;
  List<ReportModel> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final reports = await UserSafetyService.getMyReports(
          reporterId: currentUserId,
        );
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
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
        return Icons.schedule;
      case ReportStatus.underReview:
        return Icons.search;
      case ReportStatus.resolved:
        return Icons.check_circle;
      case ReportStatus.dismissed:
        return Icons.cancel;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(_reports[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Reports Submitted',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t submitted any reports yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final statusColor = _getStatusColor(report.status);
    final statusIcon = _getStatusIcon(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with reported user info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: report.reportedUserPhoto != null
                      ? NetworkImage(report.reportedUserPhoto!)
                      : null,
                  child: report.reportedUserPhoto == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reported: ${report.reportedUserName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeAgo(report.createdAt),
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason
                Row(
                  children: [
                    Icon(Icons.warning_amber, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      report.reason.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  report.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Evidence images
                if (report.evidenceImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${report.evidenceImages.length} evidence photo(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, size: 20, color: statusColor),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              report.status.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Action taken
                    if (report.adminAction != AdminAction.none)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getActionColor(report.adminAction).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getActionColor(report.adminAction),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getActionIcon(report.adminAction),
                              size: 16,
                              color: _getActionColor(report.adminAction),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              report.adminAction.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getActionColor(report.adminAction),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Admin notes
                if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Admin Response',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.adminNotes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(AdminAction action) {
    switch (action) {
      case AdminAction.none:
        return Colors.grey;
      case AdminAction.warning:
        return Colors.orange;
      case AdminAction.tempBan7Days:
        return Colors.red;
      case AdminAction.permanentBan:
        return Colors.red.shade900;
      case AdminAction.accountDeleted:
        return Colors.black;
    }
  }

  IconData _getActionIcon(AdminAction action) {
    switch (action) {
      case AdminAction.none:
        return Icons.info;
      case AdminAction.warning:
        return Icons.warning;
      case AdminAction.tempBan7Days:
        return Icons.block;
      case AdminAction.permanentBan:
        return Icons.block_outlined;
      case AdminAction.accountDeleted:
        return Icons.delete_forever;
    }
  }
}
