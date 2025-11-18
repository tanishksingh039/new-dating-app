import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Real-time statistics
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _verifiedUsers = 0;
  int _premiumUsers = 0;
  int _totalReports = 0;
  int _pendingReports = 0;
  int _totalMatches = 0;
  int _todaySignups = 0;
  
  bool _isLoading = true;
  
  // Stream subscriptions for real-time updates
  Stream<QuerySnapshot>? _usersStream;
  Stream<QuerySnapshot>? _reportsStream;
  Stream<QuerySnapshot>? _matchesStream;

  @override
  void initState() {
    super.initState();
    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() {
    // Listen to users collection for real-time updates
    _usersStream = _firestore.collection('users').snapshots();
    _usersStream!.listen((snapshot) {
      _updateUserStats(snapshot);
    });

    // Listen to reports collection for real-time updates
    _reportsStream = _firestore.collection('reports').snapshots();
    _reportsStream!.listen((snapshot) {
      _updateReportStats(snapshot);
    });

    // Listen to matches collection for real-time updates
    _matchesStream = _firestore.collection('matches').snapshots();
    _matchesStream!.listen((snapshot) {
      _updateMatchStats(snapshot);
    });
  }

  void _updateUserStats(QuerySnapshot snapshot) {
    if (!mounted) return;
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    int total = 0;
    int active = 0;
    int verified = 0;
    int premium = 0;
    int todaySignups = 0;

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        total++;
        
        // Check if user is active (logged in within last 7 days)
        if (data['lastActive'] != null) {
          final lastActive = (data['lastActive'] as Timestamp).toDate();
          if (now.difference(lastActive).inDays <= 7) {
            active++;
          }
        }
        
        // Check if verified
        if (data['isVerified'] == true) {
          verified++;
        }
        
        // Check if premium
        if (data['isPremium'] == true) {
          premium++;
        }
        
        // Check if signed up today
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          if (createdAt.isAfter(todayStart)) {
            todaySignups++;
          }
        }
      } catch (e) {
        debugPrint('Error processing user doc: $e');
      }
    }

    setState(() {
      _totalUsers = total;
      _activeUsers = active;
      _verifiedUsers = verified;
      _premiumUsers = premium;
      _todaySignups = todaySignups;
      _isLoading = false;
    });
  }

  void _updateReportStats(QuerySnapshot snapshot) {
    if (!mounted) return;
    
    int total = 0;
    int pending = 0;

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        total++;
        
        if (data['status'] == 'pending') {
          pending++;
        }
      } catch (e) {
        debugPrint('Error processing report doc: $e');
      }
    }

    setState(() {
      _totalReports = total;
      _pendingReports = pending;
    });
  }

  void _updateMatchStats(QuerySnapshot snapshot) {
    if (!mounted) return;
    
    setState(() {
      _totalMatches = snapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _setupRealTimeListeners();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoading = true;
                });
                _setupRealTimeListeners();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Real-time indicator
                    _buildRealTimeIndicator(),
                    const SizedBox(height: 16),
                    
                    // User statistics
                    const Text(
                      'User Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid([
                      _StatCard(
                        title: 'Total Users',
                        value: _totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                        onTap: () => _navigateToUserManagement(),
                      ),
                      _StatCard(
                        title: 'Active Users',
                        value: _activeUsers.toString(),
                        subtitle: 'Last 7 days',
                        icon: Icons.person_outline,
                        color: Colors.green,
                        onTap: () => _navigateToUserManagement(filter: 'active'),
                      ),
                      _StatCard(
                        title: 'Verified Users',
                        value: _verifiedUsers.toString(),
                        icon: Icons.verified_user,
                        color: Colors.purple,
                        onTap: () => _navigateToUserManagement(filter: 'verified'),
                      ),
                      _StatCard(
                        title: 'Premium Users',
                        value: _premiumUsers.toString(),
                        icon: Icons.star,
                        color: Colors.amber,
                        onTap: () => _navigateToUserManagement(filter: 'premium'),
                      ),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    // Report statistics
                    const Text(
                      'Report Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid([
                      _StatCard(
                        title: 'Total Reports',
                        value: _totalReports.toString(),
                        icon: Icons.report,
                        color: Colors.orange,
                        onTap: () => _navigateToReports(),
                      ),
                      _StatCard(
                        title: 'Pending Reports',
                        value: _pendingReports.toString(),
                        subtitle: 'Needs attention',
                        icon: Icons.pending,
                        color: Colors.red,
                        onTap: () => _navigateToReports(),
                      ),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    // Activity statistics
                    const Text(
                      'Platform Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid([
                      _StatCard(
                        title: 'Total Matches',
                        value: _totalMatches.toString(),
                        icon: Icons.favorite,
                        color: Colors.pink,
                      ),
                      _StatCard(
                        title: 'Today\'s Signups',
                        value: _todaySignups.toString(),
                        icon: Icons.person_add,
                        color: Colors.teal,
                      ),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    // Recent activity
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRealTimeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Real-time data',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatCard> cards) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildStatCard(
          title: card.title,
          value: card.value,
          subtitle: card.subtitle,
          icon: card.icon,
          color: card.color,
          onTap: card.onTap,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('reports')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.report, color: Colors.orange),
                    ),
                    title: Text(
                      data['reason'] ?? 'Unknown reason',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _formatTimestamp(data['createdAt'] as Timestamp?),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: _buildStatusBadge(data['status'] ?? 'pending'),
                    onTap: () => _navigateToReports(),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'underReview':
        color = Colors.blue;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final date = timestamp.toDate();
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

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminReportsScreen(),
      ),
    );
  }

  void _navigateToUserManagement({String? filter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUsersScreen(filter: filter),
      ),
    );
  }
}

class _StatCard {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}
