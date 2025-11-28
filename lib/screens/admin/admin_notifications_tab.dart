import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/push_notification_service.dart';

class AdminNotificationsTab extends StatefulWidget {
  const AdminNotificationsTab({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab>
    with SingleTickerProviderStateMixin {
  final PushNotificationService _notificationService = PushNotificationService();
  late TabController _tabController;

  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _selectedGender = 'all'; // 'all', 'male', 'female'
  String _selectedType = 'promotional'; // 'promotional', 'reward', 'match', 'system'
  bool _isSending = false;

  List<Map<String, dynamic>> _notificationHistory = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotificationHistory();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationHistory() async {
    final history = await _notificationService.getNotificationHistory();
    if (mounted) {
      setState(() {
        _notificationHistory = history;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await _notificationService.getNotificationStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final result = await _notificationService.sendNotificationByGender(
        gender: _selectedGender,
        title: _titleController.text,
        body: _bodyController.text,
        notificationType: _selectedType,
        bypassAuthCheck: true, // ✅ Bypass auth check for admin panel
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification sent to ${result['sentCount']} users',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _titleController.clear();
          _bodyController.clear();
          _loadNotificationHistory();
          _loadStats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error sending notification'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Send Notification'),
                Tab(text: 'History & Stats'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender selection
          const Text(
            'Select Target Audience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildGenderButton('All Users', 'all'),
                ),
                Expanded(
                  child: _buildGenderButton('Male Users', 'male'),
                ),
                Expanded(
                  child: _buildGenderButton('Female Users', 'female'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notification type
          const Text(
            'Notification Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: _selectedType,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'promotional', child: Text('Promotional')),
              DropdownMenuItem(value: 'reward', child: Text('Reward')),
              DropdownMenuItem(value: 'match', child: Text('Match')),
              DropdownMenuItem(value: 'system', child: Text('System')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Title',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter notification title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Body
          const Text(
            'Message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              hintText: 'Enter notification message',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send Notification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          border: Border(
            right: value != 'female'
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Stats cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Sent',
                      '${_stats['totalSent'] ?? 0}',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Failed',
                      '${_stats['totalFailed'] ?? 0}',
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Success Rate',
                      '${_stats['successRate'] ?? 0}%',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Notifications',
                      '${_stats['totalNotifications'] ?? 0}',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // History list
        Expanded(
          child: _notificationHistory.isEmpty
              ? const Center(
                  child: Text('No notifications sent yet'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notificationHistory.length,
                  itemBuilder: (context, index) {
                    final notification = _notificationHistory[index];
                    return _buildNotificationCard(notification);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final createdAt = notification['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notification['title'] ?? 'No title',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  notification['gender']?.toString().toUpperCase() ?? 'ALL',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notification['body'] ?? 'No message',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sent: ${notification['sentCount'] ?? 0} | Failed: ${notification['failedCount'] ?? 0}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
