import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/rewards_model.dart';
import '../../services/rewards_service.dart';
import 'rewards_history_screen.dart';
import 'rewards_rules_screen.dart';

class RewardsLeaderboardScreen extends StatefulWidget {
  const RewardsLeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<RewardsLeaderboardScreen> createState() => _RewardsLeaderboardScreenState();
}

class _RewardsLeaderboardScreenState extends State<RewardsLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  UserRewardsStats? _userStats;
  List<LeaderboardEntry> _leaderboard = [];
  List<RewardIncentive> _incentives = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  // Real-time stats stream
  Stream<UserRewardsStats?>? _userStatsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCachedStats(); // Load cached stats first for instant display
    _userStatsStream = _rewardsService.getUserStatsStream(currentUserId);
    _loadData();
    
    // Refresh stats every 5 seconds to catch updates
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // Recreate stream to force refresh
        setState(() {
          _userStatsStream = _rewardsService.getUserStatsStream(currentUserId);
        });
        _startAutoRefresh(); // Continue refreshing
      }
    });
  }

  // Load cached stats from local storage for instant display
  Future<void> _loadCachedStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('user_stats_$currentUserId');
      if (cachedData != null) {
        final Map<String, dynamic> statsMap = json.decode(cachedData);
        setState(() {
          _userStats = UserRewardsStats.fromJson(statsMap);
        });
      } else {
        // If no cache, create initial stats immediately
        await _createInitialStats();
      }
    } catch (e) {
      debugPrint('Error loading cached stats: $e');
      // Try to create initial stats on error
      await _createInitialStats();
    }
  }

  // Create initial stats for new users
  Future<void> _createInitialStats() async {
    try {
      final stats = await _rewardsService.getUserStats(currentUserId);
      if (stats != null && mounted) {
        setState(() {
          _userStats = stats;
        });
        _saveCachedStats(stats);
      }
    } catch (e) {
      debugPrint('Error creating initial stats: $e');
    }
  }

  // Save stats to cache
  Future<void> _saveCachedStats(UserRewardsStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = stats.toJson();
      final encodedData = json.encode(jsonData);
      await prefs.setString('user_stats_$currentUserId', encodedData);
    } catch (e) {
      debugPrint('Error saving cached stats: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _rewardsService.getUserStats(currentUserId);
      final leaderboard = await _rewardsService.getMonthlyLeaderboard();
      final incentives = await _rewardsService.getActiveIncentives();
      
      setState(() {
        _userStats = stats;
        _leaderboard = leaderboard;
        _incentives = incentives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh stats
          final stats = await _rewardsService.getUserStats(currentUserId);
          if (stats != null && mounted) {
            setState(() {
              _userStats = stats;
            });
            _saveCachedStats(stats);
          }
          await _loadData();
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildScoreCard(),
                  const SizedBox(height: 10),
                  _buildTabBar(),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildLeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.purple,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Rewards & Leaderboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.pink.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.emoji_events,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RewardsHistoryScreen(),
              ),
            );
          },
          tooltip: 'Reward History',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RewardsRulesScreen(),
              ),
            );
          },
          tooltip: 'Rules & Privacy',
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return StreamBuilder<UserRewardsStats?>(
      stream: _userStatsStream,
      builder: (context, snapshot) {
        debugPrint('📊 StreamBuilder rebuild - hasData: ${snapshot.hasData}, data: ${snapshot.data?.monthlyScore}');
        
        // Show cached data immediately if available, or loading state
        final stats = snapshot.data ?? _userStats;
        
        if (stats != null) {
          debugPrint('📊 Displaying stats - Monthly: ${stats.monthlyScore}, Total: ${stats.totalScore}');
        }
        
        // If still no stats after 3 seconds, show default values
        if (stats == null) {
          // Show default stats instead of loading spinner
          final defaultStats = UserRewardsStats(
            userId: currentUserId,
            totalScore: 0,
            weeklyScore: 0,
            monthlyScore: 0,
            messagesSent: 0,
            repliesGiven: 0,
            imagesSent: 0,
            positiveFeedbackRatio: 0.0,
            currentStreak: 0,
            longestStreak: 0,
            weeklyRank: 0,
            monthlyRank: 0,
            lastUpdated: DateTime.now(),
          );
          
          // Use default stats to show UI
          return _buildScoreCardContent(defaultStats);
        }
        
        // Update cached stats and save to local storage
        if (snapshot.hasData && _userStats != snapshot.data) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _userStats = snapshot.data;
              });
              // Save to cache for next time
              if (snapshot.data != null) {
                _saveCachedStats(snapshot.data!);
              }
            }
          });
        }
        
        return _buildScoreCardContent(stats);
      },
    );
  }

  Widget _buildScoreCardContent(UserRewardsStats stats) {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.pink.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Score',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.monthlyScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'points this month',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${stats.monthlyRank > 0 ? stats.monthlyRank : '--'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Rank',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  Icons.local_fire_department,
                  '${stats.currentStreak}',
                  'Day Streak',
                ),
                _buildMiniStat(
                  Icons.trending_up,
                  '${stats.weeklyScore}',
                  'This Week',
                ),
                _buildMiniStat(
                  Icons.star,
                  '${(stats.positiveFeedbackRatio * 100).toInt()}%',
                  'Positive',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.purple,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.purple,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMyStats(),
        const SizedBox(height: 16),
        _buildIncentives(),
      ],
    );
  }

  Widget _buildMyStats() {
    return StreamBuilder<UserRewardsStats?>(
      stream: _userStatsStream,
      builder: (context, snapshot) {
        // Show skeleton/placeholder while loading
        final stats = snapshot.data;
        if (stats == null) {
          return _buildStatsPlaceholder();
        }
        
        return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'My Stats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatRow(
              Icons.message,
              'Messages Sent',
              '${stats.messagesSent}',
              Colors.blue,
            ),
            _buildStatRow(
              Icons.reply,
              'Replies Given',
              '${stats.repliesGiven}',
              Colors.green,
            ),
            _buildStatRow(
              Icons.image,
              'Images Sent',
              '${stats.imagesSent}',
              Colors.orange,
            ),
            _buildStatRow(
              Icons.thumb_up,
              'Positive Feedback',
              '${(stats.positiveFeedbackRatio * 100).toInt()}%',
              Colors.pink,
            ),
            _buildStatRow(
              Icons.local_fire_department,
              'Current Streak',
              '${stats.currentStreak} days',
              Colors.red,
            ),
            _buildStatRow(
              Icons.military_tech,
              'Longest Streak',
              '${stats.longestStreak} days',
              Colors.amber,
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncentives() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'This Month\'s Rewards',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _incentives.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No active rewards at the moment',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: _incentives
                            .map((incentive) => _buildIncentiveCard(incentive))
                            .toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncentiveCard(RewardIncentive incentive) {
    final isEligible = _userStats != null &&
        _userStats!.monthlyScore >= incentive.requiredScore &&
        (_userStats!.monthlyRank <= incentive.requiredRank ||
            incentive.requiredRank == 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEligible
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEligible ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIncentiveIcon(incentive.type),
              size: 32,
              color: isEligible ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incentive.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  incentive.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${incentive.requiredScore} pts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (incentive.requiredRank > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Top ${incentive.requiredRank}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isEligible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Eligible',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIncentiveIcon(String type) {
    switch (type.toLowerCase()) {
      case 'netflix':
        return Icons.movie;
      case 'spotify':
        return Icons.music_note;
      case 'amazon':
        return Icons.shopping_bag;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildLeaderboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.leaderboard,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Top 20 This Month',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _leaderboard.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No leaderboard data yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : Column(
                            children: _leaderboard
                                .map((entry) => _buildLeaderboardEntry(entry))
                                .toList(),
                          ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    final isCurrentUser = entry.userId == currentUserId;
    final rankColor = entry.rank == 1
        ? Colors.amber
        : entry.rank == 2
            ? Colors.grey[400]
            : entry.rank == 3
                ? Colors.brown[300]
                : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.purple.shade50 : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.purple : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: entry.rank <= 3
                  ? Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 24,
                    )
                  : Text(
                      '${entry.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: entry.photoUrl != null
                ? CachedNetworkImageProvider(entry.photoUrl!)
                : null,
            child: entry.photoUrl == null
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.purple : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.score / (_leaderboard.first.score > 0
                        ? _leaderboard.first.score
                        : 1),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCurrentUser ? Colors.purple : Colors.pink,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.purple.shade100 : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.score}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.purple : Colors.black,
                  ),
                ),
                Text(
                  'points',
                  style: TextStyle(
                    fontSize: 10,
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
