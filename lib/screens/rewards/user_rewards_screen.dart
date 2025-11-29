import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/reward_model.dart';
import '../../services/reward_service.dart';
import '../../constants/app_colors.dart';

class UserRewardsScreen extends StatefulWidget {
  const UserRewardsScreen({Key? key}) : super(key: key);

  @override
  State<UserRewardsScreen> createState() => _UserRewardsScreenState();
}

class _UserRewardsScreenState extends State<UserRewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    debugPrint('[UserRewardsScreen] ═══════════════════════════════════════');
    debugPrint('[UserRewardsScreen] 🎁 Initializing User Rewards Screen');
    debugPrint('[UserRewardsScreen] User ID: $_userId');
    debugPrint('[UserRewardsScreen] ═══════════════════════════════════════');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Rewards'),
        ),
        body: const Center(
          child: Text('Please log in to view rewards'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Claimed'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: StreamBuilder<List<RewardModel>>(
        stream: RewardService.getUserRewards(_userId!),
        builder: (context, snapshot) {
          debugPrint('[UserRewardsScreen] StreamBuilder state: ${snapshot.connectionState}');
          debugPrint('[UserRewardsScreen] Has data: ${snapshot.hasData}');
          debugPrint('[UserRewardsScreen] Has error: ${snapshot.hasError}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('[UserRewardsScreen] ⏳ Loading rewards...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('[UserRewardsScreen] ❌ Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading rewards: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allRewards = snapshot.data ?? [];
          debugPrint('[UserRewardsScreen] 📦 Total rewards: ${allRewards.length}');
          
          final availableRewards = allRewards
              .where((r) => r.status == RewardStatus.pending && !r.isExpired)
              .toList();
          debugPrint('[UserRewardsScreen] ✅ Available: ${availableRewards.length}');
          
          final claimedRewards = allRewards
              .where((r) => r.status == RewardStatus.claimed || r.status == RewardStatus.used)
              .toList();
          
          final expiredRewards = allRewards
              .where((r) => r.status == RewardStatus.expired || r.isExpired)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRewardsList(availableRewards, 'available'),
              _buildRewardsList(claimedRewards, 'claimed'),
              _buildRewardsList(expiredRewards, 'expired'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardsList(List<RewardModel> rewards, String type) {
    if (rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'available'
                  ? Icons.card_giftcard_outlined
                  : type == 'claimed'
                      ? Icons.check_circle_outline
                      : Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'available'
                  ? 'No rewards available'
                  : type == 'claimed'
                      ? 'No claimed rewards'
                      : 'No expired rewards',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'available'
                  ? 'Keep engaging to earn rewards!'
                  : type == 'claimed'
                      ? 'Claim rewards to see them here'
                      : 'Expired rewards will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return _buildRewardCard(rewards[index], type);
      },
    );
  }

  Widget _buildRewardCard(RewardModel reward, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(reward.type),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getRewardIcon(reward.type),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward.typeDisplayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(reward),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                reward.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Coupon Code (if available)
              if (reward.couponCode != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Coupon Code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (reward.couponValue != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                reward.couponValue!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                reward.couponCode!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: reward.couponCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coupon code copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy Code',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Expiry Date
              if (reward.expiryDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expires: ${_formatDate(reward.expiryDate!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),

              // Claim Button (for available rewards)
              if (type == 'available' && !reward.isClaimed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _claimReward(reward),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _getGradientColors(reward.type)[0],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Claim Reward',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // Claimed/Used Date
              if (reward.claimedAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Claimed: ${_formatDate(reward.claimedAt!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RewardModel reward) {
    Color bgColor;
    Color textColor;
    String text;

    if (reward.isExpired) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      text = 'EXPIRED';
    } else if (reward.isUsed) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
      text = 'USED';
    } else if (reward.isClaimed) {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      text = 'CLAIMED';
    } else {
      bgColor = Colors.blue.shade100;
      textColor = Colors.blue.shade700;
      text = 'NEW';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  List<Color> _getGradientColors(RewardType type) {
    switch (type) {
      case RewardType.coupon:
        return [Colors.orange.shade400, Colors.deepOrange.shade600];
      case RewardType.badge:
        return [Colors.purple.shade400, Colors.deepPurple.shade600];
      case RewardType.premium:
        return [Colors.amber.shade400, Colors.orange.shade600];
      case RewardType.spotlight:
        return [Colors.pink.shade400, Colors.red.shade600];
      case RewardType.other:
        return [Colors.blue.shade400, Colors.indigo.shade600];
    }
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.coupon:
        return Icons.local_offer;
      case RewardType.badge:
        return Icons.military_tech;
      case RewardType.premium:
        return Icons.workspace_premium;
      case RewardType.spotlight:
        return Icons.star;
      case RewardType.other:
        return Icons.card_giftcard;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _claimReward(RewardModel reward) async {
    try {
      await RewardService.claimReward(reward.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
