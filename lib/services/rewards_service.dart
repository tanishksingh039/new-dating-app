import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rewards_model.dart';
import '../models/user_model.dart';

class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's rewards stats
  Future<UserRewardsStats?> getUserStats(String userId) async {
    try {
      final doc = await _firestore
          .collection('rewards_stats')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserRewardsStats.fromMap(doc.data()!);
      }
      
      // Create initial stats if doesn't exist
      final initialStats = UserRewardsStats(
        userId: userId,
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
      
      await _firestore
          .collection('rewards_stats')
          .doc(userId)
          .set(initialStats.toMap());
          
      return initialStats;
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }

  // Get monthly leaderboard (top 10)
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
    try {
      final snapshot = await _firestore
          .collection('rewards_stats')
          .orderBy('monthlyScore', descending: true)
          .limit(10)
          .get();

      List<LeaderboardEntry> leaderboard = [];
      int rank = 1;

      for (var doc in snapshot.docs) {
        final stats = UserRewardsStats.fromMap(doc.data());
        
        // Get user details
        final userDoc = await _firestore
            .collection('users')
            .doc(stats.userId)
            .get();
            
        if (userDoc.exists) {
          final user = UserModel.fromMap(userDoc.data()!);
          leaderboard.add(LeaderboardEntry(
            userId: stats.userId,
            userName: user.name,
            photoUrl: user.photos.isNotEmpty ? user.photos[0] : null,
            score: stats.monthlyScore,
            rank: rank,
            isVerified: user.isVerified,
          ));
          rank++;
        }
      }

      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Get weekly leaderboard
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard() async {
    try {
      final snapshot = await _firestore
          .collection('rewards_stats')
          .orderBy('weeklyScore', descending: true)
          .limit(10)
          .get();

      List<LeaderboardEntry> leaderboard = [];
      int rank = 1;

      for (var doc in snapshot.docs) {
        final stats = UserRewardsStats.fromMap(doc.data());
        
        final userDoc = await _firestore
            .collection('users')
            .doc(stats.userId)
            .get();
            
        if (userDoc.exists) {
          final user = UserModel.fromMap(userDoc.data()!);
          leaderboard.add(LeaderboardEntry(
            userId: stats.userId,
            userName: user.name,
            photoUrl: user.photos.isNotEmpty ? user.photos[0] : null,
            score: stats.weeklyScore,
            rank: rank,
            isVerified: user.isVerified,
          ));
          rank++;
        }
      }

      return leaderboard;
    } catch (e) {
      print('Error getting weekly leaderboard: $e');
      return [];
    }
  }

  // Get active reward incentives
  Future<List<RewardIncentive>> getActiveIncentives() async {
    try {
      final snapshot = await _firestore
          .collection('reward_incentives')
          .where('isActive', isEqualTo: true)
          .where('validUntil', isGreaterThan: Timestamp.now())
          .get();

      return snapshot.docs
          .map((doc) => RewardIncentive.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting incentives: $e');
      return [];
    }
  }

  // Get user's reward history
  Future<List<RewardHistory>> getUserRewardHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reward_history')
          .where('userId', isEqualTo: userId)
          .orderBy('wonDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RewardHistory.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting reward history: $e');
      return [];
    }
  }

  // Award points for message sent
  Future<void> awardMessagePoints(String userId) async {
    await _updateScore(userId, ScoringRules.messageSentPoints, 'messagesSent');
  }

  // Award points for reply given
  Future<void> awardReplyPoints(String userId) async {
    await _updateScore(userId, ScoringRules.replyGivenPoints, 'repliesGiven');
  }

  // Award points for image sent
  Future<void> awardImagePoints(String userId) async {
    await _updateScore(userId, ScoringRules.imageSentPoints, 'imagesSent');
  }

  // Award points for positive feedback
  Future<void> awardPositiveFeedbackPoints(String userId) async {
    await _updateScore(userId, ScoringRules.positiveFeedbackPoints, null);
  }

  // Update score helper
  Future<void> _updateScore(String userId, int points, String? statField) async {
    try {
      final docRef = _firestore.collection('rewards_stats').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          // Create new stats
          final newStats = UserRewardsStats(
            userId: userId,
            totalScore: points,
            weeklyScore: points,
            monthlyScore: points,
            messagesSent: statField == 'messagesSent' ? 1 : 0,
            repliesGiven: statField == 'repliesGiven' ? 1 : 0,
            imagesSent: statField == 'imagesSent' ? 1 : 0,
            positiveFeedbackRatio: 0.0,
            currentStreak: 0,
            longestStreak: 0,
            weeklyRank: 0,
            monthlyRank: 0,
            lastUpdated: DateTime.now(),
          );
          transaction.set(docRef, newStats.toMap());
        } else {
          final data = snapshot.data()!;
          final updates = {
            'totalScore': (data['totalScore'] ?? 0) + points,
            'weeklyScore': (data['weeklyScore'] ?? 0) + points,
            'monthlyScore': (data['monthlyScore'] ?? 0) + points,
            'lastUpdated': Timestamp.now(),
          };
          
          if (statField != null) {
            updates[statField] = (data[statField] ?? 0) + 1;
          }
          
          transaction.update(docRef, updates);
        }
      });
      
      // Check for milestones and send notifications
      await _checkMilestones(userId);
    } catch (e) {
      print('Error updating score: $e');
    }
  }

  // Check for milestones and trigger notifications
  Future<void> _checkMilestones(String userId) async {
    try {
      final stats = await getUserStats(userId);
      if (stats == null) return;

      // Check if user entered top 10
      if (stats.monthlyRank <= 10 && stats.monthlyRank > 0) {
        await _sendMilestoneNotification(
          userId,
          'Top 10 Achievement! 🎉',
          'You\'re now ranked #${stats.monthlyRank} on the leaderboard!',
        );
      }

      // Check score milestones
      if (stats.monthlyScore % 500 == 0 && stats.monthlyScore > 0) {
        await _sendMilestoneNotification(
          userId,
          'Milestone Reached! 🌟',
          'You\'ve reached ${stats.monthlyScore} points this month!',
        );
      }

      // Check streak milestones
      if (stats.currentStreak % 7 == 0 && stats.currentStreak > 0) {
        await _sendMilestoneNotification(
          userId,
          'Streak Master! 🔥',
          '${stats.currentStreak} day streak! Keep it going!',
        );
      }
    } catch (e) {
      print('Error checking milestones: $e');
    }
  }

  // Send milestone notification
  Future<void> _sendMilestoneNotification(
    String userId,
    String title,
    String body,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'milestone',
        'read': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Update daily streak
  Future<void> updateDailyStreak(String userId) async {
    try {
      final docRef = _firestore.collection('rewards_stats').doc(userId);
      final doc = await docRef.get();
      
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
      final now = DateTime.now();
      
      // Check if it's a new day
      if (now.difference(lastUpdated).inHours >= 24) {
        final currentStreak = (data['currentStreak'] ?? 0) + 1;
        final longestStreak = currentStreak > (data['longestStreak'] ?? 0)
            ? currentStreak
            : data['longestStreak'];
            
        await docRef.update({
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'totalScore': (data['totalScore'] ?? 0) + ScoringRules.dailyStreakBonus,
          'weeklyScore': (data['weeklyScore'] ?? 0) + ScoringRules.dailyStreakBonus,
          'monthlyScore': (data['monthlyScore'] ?? 0) + ScoringRules.dailyStreakBonus,
          'lastUpdated': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Reset weekly scores (to be called by Cloud Function)
  Future<void> resetWeeklyScores() async {
    try {
      final snapshot = await _firestore.collection('rewards_stats').get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.update({'weeklyScore': 0});
      }
    } catch (e) {
      print('Error resetting weekly scores: $e');
    }
  }

  // Reset monthly scores (to be called by Cloud Function)
  Future<void> resetMonthlyScores() async {
    try {
      final snapshot = await _firestore.collection('rewards_stats').get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.update({'monthlyScore': 0});
      }
    } catch (e) {
      print('Error resetting monthly scores: $e');
    }
  }
}
