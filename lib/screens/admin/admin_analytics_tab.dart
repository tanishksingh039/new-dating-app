import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time stats
  int _totalUsers = 0;
  int _dailyActive = 0;
  int _weeklyActive = 0;
  int _monthlyActive = 0;
  int _premiumUsers = 0;
  int _verifiedUsers = 0;
  List<FlSpot> _growthData = [];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _setupRealTimeListeners();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _setupRealTimeListeners() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      if (!mounted) return;

      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      int total = 0;
      int daily = 0;
      int weekly = 0;
      int monthly = 0;
      int premium = 0;
      int verified = 0;
      Map<int, int> dailySignups = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          total++;

          if (data['isPremium'] == true) premium++;
          if (data['isVerified'] == true) verified++;

          if (data['lastActive'] != null) {
            final lastActive = (data['lastActive'] as Timestamp).toDate();
            if (lastActive.isAfter(dayAgo)) daily++;
            if (lastActive.isAfter(weekAgo)) weekly++;
            if (lastActive.isAfter(monthAgo)) monthly++;
          }

          // Track signups for growth chart
          if (data['createdAt'] != null) {
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            final daysAgo = now.difference(createdAt).inDays;
            if (daysAgo <= 30) {
              dailySignups[daysAgo] = (dailySignups[daysAgo] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Error processing user: $e');
        }
      }

      // Generate growth data
      List<FlSpot> spots = [];
      for (int i = 30; i >= 0; i--) {
        spots.add(FlSpot((30 - i).toDouble(), (dailySignups[i] ?? 0).toDouble()));
      }

      setState(() {
        _totalUsers = total;
        _dailyActive = daily;
        _weeklyActive = weekly;
        _monthlyActive = monthly;
        _premiumUsers = premium;
        _verifiedUsers = verified;
        _growthData = spots;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade700,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Spotlight'),
              Tab(text: 'Rewards'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildUsersAnalytics(),
              _buildSpotlightAnalytics(),
              _buildRewardsAnalytics(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildAnalyticsCard(
                'Total Users',
                _totalUsers.toString(),
                'All registered users',
                Icons.people,
                Colors.blue,
              ),
              _buildAnalyticsCard(
                'Daily Active',
                _dailyActive.toString(),
                'Active in last 24h',
                Icons.calendar_today,
                Colors.green,
              ),
              _buildAnalyticsCard(
                'Weekly Active',
                _weeklyActive.toString(),
                'Active in last 7 days',
                Icons.calendar_view_week,
                Colors.orange,
              ),
              _buildAnalyticsCard(
                'Monthly Active',
                _monthlyActive.toString(),
                'Active in last 30 days',
                Icons.calendar_month,
                Colors.purple,
              ),
              _buildAnalyticsCard(
                'Premium Users',
                _premiumUsers.toString(),
                '${(_premiumUsers / (_totalUsers > 0 ? _totalUsers : 1) * 100).toStringAsFixed(1)}% of total',
                Icons.star,
                Colors.amber,
              ),
              _buildAnalyticsCard(
                'Verified Users',
                _verifiedUsers.toString(),
                '${(_verifiedUsers / (_totalUsers > 0 ? _totalUsers : 1) * 100).toStringAsFixed(1)}% of total',
                Icons.verified,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Growth Chart
          const Text(
            'User Growth (Last 30 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
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
            child: _growthData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 30,
                      minY: 0,
                      maxY: (_growthData.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _growthData,
                          isCurved: true,
                          color: Colors.blue.shade400,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.shade100.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightAnalytics() {
    return const Center(
      child: Text('Spotlight Analytics Coming Soon'),
    );
  }

  Widget _buildRewardsAnalytics() {
    return const Center(
      child: Text('Rewards Analytics Coming Soon'),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
