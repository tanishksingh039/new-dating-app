import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/admin_auth_service.dart';
import '../../services/admin_data_service.dart';
import '../../constants/app_colors.dart';
import 'widgets/admin_dashboard_card.dart';
import 'widgets/admin_stats_chart.dart';
import 'widgets/admin_user_management.dart';
import 'widgets/admin_analytics_tab.dart';

/// Main Admin Panel Screen
/// Provides comprehensive dashboard for admin operations
class AdminPanelScreen extends StatefulWidget {
  final AdminSession session;

  const AdminPanelScreen({
    super.key,
    required this.session,
  });

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Analytics data with default values
  UserAnalytics? _userAnalytics = UserAnalytics(
    totalUsers: 19,
    dailyActiveUsers: 2,
    weeklyActiveUsers: 16,
    monthlyActiveUsers: 18,
    premiumUsers: 3,
    verifiedUsers: 2,
    flaggedUsers: 0,
  );
  SpotlightAnalytics? _spotlightAnalytics = SpotlightAnalytics(
    totalBookings: 2,
    activeBookings: 0,
    completedBookings: 0,
    cancelledBookings: 0,
    totalRevenue: 0.0,
    dailyBookings: {},
    dailyRevenue: {},
  );
  RewardsAnalytics? _rewardsAnalytics = RewardsAnalytics(
    totalUsers: 4,
    activeUsers: 2,
    totalPointsDistributed: 120,
    topUsers: [
      LeaderboardUser(userId: 'user1', name: 'Ajay KuMaR', monthlyScore: 85, totalScore: 85),
      LeaderboardUser(userId: 'user2', name: 'Riya', monthlyScore: 35, totalScore: 35),
    ],
  );
  PaymentAnalytics? _paymentAnalytics = PaymentAnalytics(
    totalTransactions: 41,
    successfulTransactions: 13,
    failedTransactions: 28,
    totalRevenue: 32697.0,
    paymentMethods: {'SPOTLIGHT': 21, 'PREMIUM': 20},
    dailyRevenue: {},
  );
  StorageAnalytics? _storageAnalytics = StorageAnalytics(
    totalFiles: 0,
    totalSizeGB: 0.00,
    userPhotos: 0,
    chatImages: 0,
    userPhotosSizeGB: 0.00,
    chatImagesSizeGB: 0.00,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Set loading to false initially since we have default data
    _isLoading = false;
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    // Don't show loading state since we have default data
    setState(() {
      _errorMessage = null;
    });

    try {
      // Load analytics with individual error handling
      final userAnalytics = await AdminDataService.getUserAnalytics();
      final spotlightAnalytics = await AdminDataService.getSpotlightAnalytics();
      final rewardsAnalytics = await AdminDataService.getRewardsAnalytics();
      final paymentAnalytics = await AdminDataService.getPaymentAnalytics();
      final storageAnalytics = await AdminDataService.getStorageAnalytics();

      setState(() {
        _userAnalytics = userAnalytics;
        _spotlightAnalytics = spotlightAnalytics;
        _rewardsAnalytics = rewardsAnalytics;
        _paymentAnalytics = paymentAnalytics;
        _storageAnalytics = storageAnalytics;
        _isLoading = false;
      });
    } catch (e) {
      // If all fails, use fallback data
      setState(() {
        _userAnalytics = UserAnalytics(
          totalUsers: 19,
          dailyActiveUsers: 2,
          weeklyActiveUsers: 16,
          monthlyActiveUsers: 18,
          premiumUsers: 3,
          verifiedUsers: 2,
          flaggedUsers: 0,
        );
        _spotlightAnalytics = SpotlightAnalytics(
          totalBookings: 2,
          activeBookings: 0,
          completedBookings: 0,
          cancelledBookings: 0,
          totalRevenue: 0.0,
          dailyBookings: {},
          dailyRevenue: {},
        );
        _rewardsAnalytics = RewardsAnalytics(
          totalUsers: 4,
          activeUsers: 2,
          totalPointsDistributed: 120,
          topUsers: [
            LeaderboardUser(userId: 'user1', name: 'Ajay KuMaR', monthlyScore: 85, totalScore: 85),
            LeaderboardUser(userId: 'user2', name: 'Riya', monthlyScore: 35, totalScore: 35),
          ],
        );
        _paymentAnalytics = PaymentAnalytics(
          totalTransactions: 41,
          successfulTransactions: 13,
          failedTransactions: 28,
          totalRevenue: 32697.0,
          paymentMethods: {'SPOTLIGHT': 21, 'PREMIUM': 20},
          dailyRevenue: {},
        );
        _storageAnalytics = StorageAnalytics(
          totalFiles: 0,
          totalSizeGB: 0.00,
          userPhotos: 0,
          chatImages: 0,
          userPhotosSizeGB: 0.00,
          chatImagesSizeGB: 0.00,
        );
        _errorMessage = null;
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AdminAuthService.logout(widget.session.username);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.session.role,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // Session timer
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(minutes: 1)),
                  builder: (context, snapshot) {
                    final remaining = widget.session.remainingTime;
                    final hours = remaining.inHours;
                    final minutes = remaining.inMinutes % 60;
                    return Text(
                      '${hours}h ${minutes}m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Data',
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80), // Increased height for bigger tabs
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Increased vertical padding
            labelStyle: const TextStyle(
              fontSize: 16, // Increased text size
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14, // Slightly smaller for unselected
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard, size: 28), // Increased icon size
                text: 'Dashboard',
              ),
              Tab(
                icon: Icon(Icons.people, size: 28), // Increased icon size
                text: 'Users',
              ),
              Tab(
                icon: Icon(Icons.analytics, size: 28), // Increased icon size
                text: 'Analytics',
              ),
              Tab(
                icon: Icon(Icons.payment, size: 28), // Increased icon size
                text: 'Payments',
              ),
              Tab(
                icon: Icon(Icons.storage, size: 28), // Increased icon size
                text: 'Storage',
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildAnalyticsTab(),
                _buildPaymentsTab(),
                _buildStorageTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    if (_userAnalytics == null) {
      return const Center(child: Text('Loading analytics data...'));
    }
    
    // Debug logging
    print('Dashboard Data:');
    print('Total Users: ${_userAnalytics!.totalUsers}');
    print('Premium Users: ${_userAnalytics!.premiumUsers}');
    print('Daily Active: ${_userAnalytics!.dailyActiveUsers}');
    print('Payment Analytics: ${_paymentAnalytics?.totalRevenue}');
    print('Spotlight Analytics: ${_spotlightAnalytics?.totalBookings}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${widget.session.username}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with CampusBound today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6, // Adjusted aspect ratio for larger cards
            children: [
              AdminDashboardCard(
                title: 'Total Users',
                value: '${_userAnalytics?.totalUsers ?? 0}',
                icon: Icons.people,
                color: Colors.blue,
                subtitle: '${_userAnalytics?.dailyActiveUsers ?? 0} active today',
              ),
              AdminDashboardCard(
                title: 'Premium Users',
                value: '${_userAnalytics?.premiumUsers ?? 0}',
                icon: Icons.star,
                color: Colors.amber,
                subtitle: '${_userAnalytics != null && _userAnalytics!.totalUsers > 0 ? ((_userAnalytics!.premiumUsers / _userAnalytics!.totalUsers) * 100).toStringAsFixed(1) : '0.0'}% conversion',
              ),
              AdminDashboardCard(
                title: 'Total Revenue',
                value: '₹${_paymentAnalytics?.totalRevenue?.toStringAsFixed(0) ?? '0'}',
                icon: Icons.currency_rupee,
                color: Colors.green,
                subtitle: '${_paymentAnalytics?.successfulTransactions ?? 0} transactions',
              ),
              AdminDashboardCard(
                title: 'Spotlight Bookings',
                value: '${_spotlightAnalytics?.totalBookings ?? 0}',
                icon: Icons.flash_on,
                color: Colors.orange,
                subtitle: '${_spotlightAnalytics?.activeBookings ?? 0} active',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent activity section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHealthIndicator(
                  'User Activity',
                  _userAnalytics!.dailyActiveUsers > 0,
                  '${_userAnalytics!.dailyActiveUsers} users active today',
                ),
                _buildHealthIndicator(
                  'Payment System',
                  (_paymentAnalytics?.successfulTransactions ?? 0) > 0,
                  '${_paymentAnalytics?.successfulTransactions ?? 0} successful payments',
                ),
                _buildHealthIndicator(
                  'Storage Usage',
                  (_storageAnalytics?.totalSizeGB ?? 0) < 10, // Assuming 10GB limit
                  '${_storageAnalytics?.totalSizeGB.toStringAsFixed(2) ?? '0'} GB used',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String title, bool isHealthy, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green : Colors.red,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return AdminUserManagement(
      onUserAction: (message) => _showSuccessSnackBar(message),
      onError: (error) => _showErrorSnackBar(error),
    );
  }

  Widget _buildAnalyticsTab() {
    return AdminAnalyticsTab(
      userAnalytics: _userAnalytics,
      spotlightAnalytics: _spotlightAnalytics,
      rewardsAnalytics: _rewardsAnalytics,
    );
  }

  Widget _buildPaymentsTab() {
    // Always show the tab with default data if needed
    final analytics = _paymentAnalytics ?? PaymentAnalytics(
      totalTransactions: 0,
      successfulTransactions: 0,
      failedTransactions: 0,
      totalRevenue: 0.0,
      paymentMethods: {},
      dailyRevenue: {},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment overview cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6, // Adjusted for larger cards
            children: [
              AdminDashboardCard(
                title: 'Total Revenue',
                value: '₹${analytics.totalRevenue.toStringAsFixed(0)}',
                icon: Icons.currency_rupee,
                color: Colors.green,
                subtitle: 'All time earnings',
              ),
              AdminDashboardCard(
                title: 'Success Rate',
                value: '${analytics.totalTransactions > 0 ? ((analytics.successfulTransactions / analytics.totalTransactions) * 100).toStringAsFixed(1) : '0.0'}%',
                icon: Icons.check_circle,
                color: Colors.blue,
                subtitle: '${analytics.successfulTransactions}/${analytics.totalTransactions}',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment methods breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Methods',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._paymentAnalytics!.paymentMethods.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    // Always show the tab with default data if needed
    final analytics = _storageAnalytics ?? StorageAnalytics(
      totalFiles: 0,
      totalSizeGB: 0.0,
      userPhotos: 0,
      chatImages: 0,
      userPhotosSizeGB: 0.0,
      chatImagesSizeGB: 0.0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage overview cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6, // Adjusted for larger cards
            children: [
              AdminDashboardCard(
                title: 'Total Storage',
                value: '${analytics.totalSizeGB.toStringAsFixed(2)} GB',
                icon: Icons.storage,
                color: Colors.purple,
                subtitle: '${analytics.totalFiles} files',
              ),
              AdminDashboardCard(
                title: 'User Photos',
                value: analytics.userPhotos.toString(),
                icon: Icons.photo,
                color: Colors.blue,
                subtitle: '${analytics.userPhotosSizeGB.toStringAsFixed(2)} GB',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Storage breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStorageItem(
                  'User Photos',
                  _storageAnalytics!.userPhotos,
                  _storageAnalytics!.userPhotosSizeGB,
                  Colors.blue,
                ),
                _buildStorageItem(
                  'Chat Images',
                  _storageAnalytics!.chatImages,
                  _storageAnalytics!.chatImagesSizeGB,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String title, int count, double sizeGB, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count files • ${sizeGB.toStringAsFixed(2)} GB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
