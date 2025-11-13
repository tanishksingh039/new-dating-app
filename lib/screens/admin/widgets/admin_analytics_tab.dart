import 'package:flutter/material.dart';
import '../../../services/admin_data_service.dart';
import 'admin_dashboard_card.dart';
import 'admin_stats_chart.dart';

/// Admin Analytics Tab Widget
/// Displays comprehensive analytics and charts
class AdminAnalyticsTab extends StatefulWidget {
  final UserAnalytics? userAnalytics;
  final SpotlightAnalytics? spotlightAnalytics;
  final RewardsAnalytics? rewardsAnalytics;

  const AdminAnalyticsTab({
    super.key,
    this.userAnalytics,
    this.spotlightAnalytics,
    this.rewardsAnalytics,
  });

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserGrowthData> _userGrowthData = [];
  bool _isLoadingCharts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoadingCharts = true);
    
    try {
      final growthData = await AdminDataService.getUserGrowthData(30);
      setState(() {
        _userGrowthData = growthData;
        _isLoadingCharts = false;
      });
    } catch (e) {
      setState(() => _isLoadingCharts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Spotlight'),
              Tab(text: 'Rewards'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUserAnalytics(),
              _buildSpotlightAnalytics(),
              _buildRewardsAnalytics(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserAnalytics() {
    if (widget.userAnalytics == null) {
      return const Center(child: Text('No user analytics available'));
    }

    final analytics = widget.userAnalytics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              AdminDashboardCard(
                title: 'Total Users',
                value: analytics.totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
                subtitle: 'All registered users',
              ),
              AdminDashboardCard(
                title: 'Daily Active',
                value: analytics.dailyActiveUsers.toString(),
                icon: Icons.today,
                color: Colors.green,
                subtitle: 'Active in last 24h',
              ),
              AdminDashboardCard(
                title: 'Weekly Active',
                value: analytics.weeklyActiveUsers.toString(),
                icon: Icons.date_range,
                color: Colors.orange,
                subtitle: 'Active in last 7 days',
              ),
              AdminDashboardCard(
                title: 'Monthly Active',
                value: analytics.monthlyActiveUsers.toString(),
                icon: Icons.calendar_month,
                color: Colors.purple,
                subtitle: 'Active in last 30 days',
              ),
              AdminDashboardCard(
                title: 'Premium Users',
                value: analytics.premiumUsers.toString(),
                icon: Icons.star,
                color: Colors.amber,
                subtitle: '${((analytics.premiumUsers / analytics.totalUsers) * 100).toStringAsFixed(1)}% of total',
              ),
              AdminDashboardCard(
                title: 'Verified Users',
                value: analytics.verifiedUsers.toString(),
                icon: Icons.verified,
                color: Colors.blue,
                subtitle: '${((analytics.verifiedUsers / analytics.totalUsers) * 100).toStringAsFixed(1)}% of total',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User growth chart
          if (_isLoadingCharts)
            const Center(child: CircularProgressIndicator())
          else
            AdminStatsChart(
              growthData: _userGrowthData,
              title: 'User Growth (Last 30 Days)',
              primaryColor: Colors.blue,
            ),
          const SizedBox(height: 24),

          // User engagement metrics
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
                  'User Engagement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEngagementMetric(
                  'Daily Retention',
                  '${((analytics.dailyActiveUsers / analytics.totalUsers) * 100).toStringAsFixed(1)}%',
                  analytics.dailyActiveUsers / analytics.totalUsers,
                  Colors.green,
                ),
                _buildEngagementMetric(
                  'Weekly Retention',
                  '${((analytics.weeklyActiveUsers / analytics.totalUsers) * 100).toStringAsFixed(1)}%',
                  analytics.weeklyActiveUsers / analytics.totalUsers,
                  Colors.blue,
                ),
                _buildEngagementMetric(
                  'Premium Conversion',
                  '${((analytics.premiumUsers / analytics.totalUsers) * 100).toStringAsFixed(1)}%',
                  analytics.premiumUsers / analytics.totalUsers,
                  Colors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightAnalytics() {
    if (widget.spotlightAnalytics == null) {
      return const Center(child: Text('No spotlight analytics available'));
    }

    final analytics = widget.spotlightAnalytics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spotlight metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              AdminDashboardCard(
                title: 'Total Bookings',
                value: analytics.totalBookings.toString(),
                icon: Icons.flash_on,
                color: Colors.orange,
                subtitle: 'All time bookings',
              ),
              AdminDashboardCard(
                title: 'Active Bookings',
                value: analytics.activeBookings.toString(),
                icon: Icons.flash_auto,
                color: Colors.green,
                subtitle: 'Currently active',
              ),
              AdminDashboardCard(
                title: 'Total Revenue',
                value: '₹${analytics.totalRevenue.toStringAsFixed(0)}',
                icon: Icons.currency_rupee,
                color: Colors.green,
                subtitle: 'From spotlight',
              ),
              AdminDashboardCard(
                title: 'Success Rate',
                value: '${((analytics.activeBookings + analytics.completedBookings) / analytics.totalBookings * 100).toStringAsFixed(1)}%',
                icon: Icons.check_circle,
                color: Colors.blue,
                subtitle: 'Non-cancelled bookings',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue chart
          AdminRevenueChart(
            dailyRevenue: analytics.dailyRevenue,
            title: 'Spotlight Revenue (Daily)',
            primaryColor: Colors.orange,
          ),
          const SizedBox(height: 24),

          // Booking status breakdown
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
                  'Booking Status Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusItem(
                  'Active',
                  analytics.activeBookings,
                  analytics.totalBookings,
                  Colors.green,
                ),
                _buildStatusItem(
                  'Completed',
                  analytics.completedBookings,
                  analytics.totalBookings,
                  Colors.blue,
                ),
                _buildStatusItem(
                  'Cancelled',
                  analytics.cancelledBookings,
                  analytics.totalBookings,
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsAnalytics() {
    if (widget.rewardsAnalytics == null) {
      return const Center(child: Text('No rewards analytics available'));
    }

    final analytics = widget.rewardsAnalytics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rewards metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              AdminDashboardCard(
                title: 'Total Users',
                value: analytics.totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
                subtitle: 'In rewards system',
              ),
              AdminDashboardCard(
                title: 'Active Users',
                value: analytics.activeUsers.toString(),
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: 'With points > 0',
              ),
              AdminDashboardCard(
                title: 'Total Points',
                value: analytics.totalPointsDistributed.toString(),
                icon: Icons.stars,
                color: Colors.amber,
                subtitle: 'Distributed overall',
              ),
              AdminDashboardCard(
                title: 'Engagement Rate',
                value: '${((analytics.activeUsers / analytics.totalUsers) * 100).toStringAsFixed(1)}%',
                icon: Icons.emoji_events,
                color: Colors.purple,
                subtitle: 'Users with activity',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top users leaderboard
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
                  'Top Users (Monthly)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...analytics.topUsers.take(5).map((user) => _buildLeaderboardItem(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetric(String title, String value, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String status, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$count (${(percentage * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Total: ${user.totalScore} points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${user.monthlyScore}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
