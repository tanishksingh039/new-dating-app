import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_users_tab.dart';
import 'admin_analytics_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_storage_tab.dart';
import 'admin_profile_manager_screen.dart';
import 'admin_leaderboard_control_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewAdminDashboard extends StatefulWidget {
  const NewAdminDashboard({Key? key}) : super(key: key);

  @override
  State<NewAdminDashboard> createState() => _NewAdminDashboardState();
}

class _NewAdminDashboardState extends State<NewAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Real-time data
  int _totalUsers = 0;
  int _activeToday = 0;
  int _premiumUsers = 0;
  int _totalRevenue = 0;
  int _spotlightBookings = 0;
  int _userActivityCount = 0;
  int _successfulPayments = 0;
  double _storageUsed = 0.0;

  String _currentAdminUserId = 'admin_user'; // Default admin ID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _setupRealTimeListeners();
    _getCurrentAdminId();
  }

  void _getCurrentAdminId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentAdminUserId = user.uid;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealTimeListeners() {
    // Listen to users collection
    _firestore.collection('users').snapshots().listen((snapshot) {
      if (!mounted) return;
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      int total = 0;
      int activeToday = 0;
      int premium = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          total++;
          
          if (data['isPremium'] == true) premium++;
          
          if (data['lastActive'] != null) {
            final lastActive = (data['lastActive'] as Timestamp).toDate();
            if (lastActive.isAfter(todayStart)) {
              activeToday++;
            }
          }
        } catch (e) {
          debugPrint('Error processing user: $e');
        }
      }

      setState(() {
        _totalUsers = total;
        _activeToday = activeToday;
        _premiumUsers = premium;
        _userActivityCount = activeToday;
      });
    });

    // Listen to payments collection (if exists)
    _firestore.collection('payments').snapshots().listen((snapshot) {
      if (!mounted) return;
      
      int revenue = 0;
      int successful = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['status'] == 'success' || data['status'] == 'completed') {
            successful++;
            revenue += (data['amount'] as num?)?.toInt() ?? 0;
          }
        } catch (e) {
          debugPrint('Error processing payment: $e');
        }
      }

      setState(() {
        _totalRevenue = revenue;
        _successfulPayments = successful;
      });
    });

    // Listen to spotlight bookings (if exists)
    _firestore.collection('spotlight_bookings').snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _spotlightBookings = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['status'] == 'active';
        }).length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final username = currentUser?.displayName ?? 'admin_master';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.pink.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Master Admin',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 4),
                Text(
                  '7h 59m',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                _setupRealTimeListeners();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard refreshed!'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              final confirm = await showDialog<bool>(
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
              
              if (confirm == true && mounted) {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.pink.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink.shade700,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard, size: 20),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(Icons.people, size: 20),
              text: 'Users',
            ),
            Tab(
              icon: Icon(Icons.analytics, size: 20),
              text: 'Analytics',
            ),
            Tab(
              icon: Icon(Icons.payment, size: 20),
              text: 'Payments',
            ),
            Tab(
              icon: Icon(Icons.storage, size: 20),
              text: 'Storage',
            ),
            Tab(
              icon: Icon(Icons.person_pin, size: 20),
              text: 'My Profile',
            ),
            Tab(
              icon: Icon(Icons.leaderboard, size: 20),
              text: 'Leaderboard',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(username),
          const AdminUsersTab(),
          const AdminAnalyticsTab(),
          const AdminPaymentsTab(),
          const AdminStorageTab(),
          AdminProfileManagerScreen(adminUserId: _currentAdminUserId),
          AdminLeaderboardControlScreen(adminUserId: _currentAdminUserId),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(String username) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade400, Colors.pink.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Here's what's happening with\nCampusBound today",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                'Total Users',
                _totalUsers.toString(),
                '1 active today',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Premium Users',
                _premiumUsers.toString(),
                '${(_premiumUsers / (_totalUsers > 0 ? _totalUsers : 1) * 100).toStringAsFixed(1)}% conversion',
                Icons.star,
                Colors.amber,
              ),
              _buildStatCard(
                'Total Revenue',
                '₹${_totalRevenue}',
                '${_successfulPayments} transactions',
                Icons.currency_rupee,
                Colors.green,
              ),
              _buildStatCard(
                'Spotlight Bookings',
                _spotlightBookings.toString(),
                '0 active',
                Icons.bolt,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // System Health
          const Text(
            'System Health',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildHealthItem(
            'User Activity',
            '$_userActivityCount users active today',
            Colors.green,
          ),
          _buildHealthItem(
            'Payment System',
            '$_successfulPayments successful payments',
            Colors.green,
          ),
          _buildHealthItem(
            'Storage Usage',
            '${_storageUsed.toStringAsFixed(2)} GB used',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String title, String subtitle, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
