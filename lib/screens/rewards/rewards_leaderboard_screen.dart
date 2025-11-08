import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
    if (_userStats == null) return const SizedBox();

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
                      '${_userStats!.monthlyScore}',
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
                        '#${_userStats!.monthlyRank > 0 ? _userStats!.monthlyRank : '--'}',
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
                  '${_userStats!.currentStreak}',
                  'Day Streak',
                ),
                _buildMiniStat(
                  Icons.trending_up,
                  '${_userStats!.weeklyScore}',
                  'This Week',
                ),
                _buildMiniStat(
                  Icons.star,
                  '${(_userStats!.positiveFeedbackRatio * 100).toInt()}%',
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
    if (_userStats == null) return const SizedBox();

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
              '${_userStats!.messagesSent}',
              Colors.blue,
            ),
            _buildStatRow(
              Icons.reply,
              'Replies Given',
              '${_userStats!.repliesGiven}',
              Colors.green,
            ),
            _buildStatRow(
              Icons.image,
              'Images Sent',
              '${_userStats!.imagesSent}',
              Colors.orange,
            ),
            _buildStatRow(
              Icons.thumb_up,
              'Positive Feedback',
              '${(_userStats!.positiveFeedbackRatio * 100).toInt()}%',
              Colors.pink,
            ),
            _buildStatRow(
              Icons.local_fire_department,
              'Current Streak',
              '${_userStats!.currentStreak} days',
              Colors.red,
            ),
            _buildStatRow(
              Icons.military_tech,
              'Longest Streak',
              '${_userStats!.longestStreak} days',
              Colors.amber,
            ),
          ],
        ),
      ),
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
            if (_incentives.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No active rewards at the moment',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._incentives.map((incentive) => _buildIncentiveCard(incentive)),
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
                      'Top 10 This Month',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_leaderboard.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No leaderboard data yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._leaderboard.map((entry) => _buildLeaderboardEntry(entry)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.purple : Colors.black,
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
