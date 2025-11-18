import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rewards_model.dart';
import '../models/user_model.dart';
import '../models/message_tracking_model.dart';
import 'message_content_analyzer.dart';
import 'face_detection_service.dart';

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

  // Get real-time user stats stream
  Stream<UserRewardsStats?> getUserStatsStream(String userId) {
    return _firestore
        .collection('rewards_stats')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserRewardsStats.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Get monthly leaderboard (top 20)
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
    try {
      final snapshot = await _firestore
          .collection('rewards_stats')
          .orderBy('monthlyScore', descending: true)
          .limit(20)
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

  // Get weekly leaderboard (top 20)
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard() async {
    try {
      final snapshot = await _firestore
          .collection('rewards_stats')
          .orderBy('weeklyScore', descending: true)
          .limit(20)
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

  // Award points for message sent (with quality check)
  Future<void> awardMessagePoints(
    String userId,
    String conversationId,
    String messageText,
  ) async {
    try {
      // Check rate limits
      final tracking = await _getMessageTracking(userId, conversationId);
      if (tracking != null) {
        if (tracking.hasExceededMessageLimit()) {
          debugPrint('❌ Message rate limit exceeded for user: $userId');
          return;
        }
        if (tracking.isTooQuick()) {
          debugPrint('❌ Messages sent too quickly for user: $userId');
          return;
        }
      }

      // Analyze message quality
      final quality = MessageContentAnalyzer.analyzeMessage(messageText);
      
      // Check for spam/gibberish
      if (quality.isSpam || quality.isGibberish) {
        debugPrint('❌ Spam/gibberish detected - no points awarded');
        await _applyPenalty(userId, ScoringRules.spamPenalty);
        return;
      }

      // Check for duplicates
      if (tracking != null && MessageContentAnalyzer.isDuplicate(messageText, tracking.recentMessages)) {
        debugPrint('❌ Duplicate message detected - penalty applied');
        await _applyPenalty(userId, ScoringRules.duplicatePenalty);
        return;
      }

      // Calculate points with quality multiplier
      final multiplier = MessageContentAnalyzer.getPointsMultiplier(quality.score);
      final points = (ScoringRules.messageSentPoints * multiplier).toInt();

      if (points > 0) {
        await _updateScore(userId, points, 'messagesSent');
        await _updateMessageTracking(userId, conversationId, messageText, quality.score);
        debugPrint('✅ Awarded $points points (quality: ${quality.score})');
      } else {
        debugPrint('⚠️ Low quality message - no points awarded');
      }
    } catch (e) {
      debugPrint('❌ Error awarding message points: $e');
    }
  }

  // Award points for reply given (with quality check)
  Future<void> awardReplyPoints(
    String userId,
    String conversationId,
    String messageText,
  ) async {
    try {
      // Analyze message quality
      final quality = MessageContentAnalyzer.analyzeMessage(messageText);
      
      if (quality.isSpam || quality.isGibberish) {
        debugPrint('❌ Spam reply detected - no points awarded');
        return;
      }

      // Calculate points with quality multiplier
      final multiplier = MessageContentAnalyzer.getPointsMultiplier(quality.score);
      final points = (ScoringRules.replyGivenPoints * multiplier).toInt();

      if (points > 0) {
        await _updateScore(userId, points, 'repliesGiven');
        debugPrint('✅ Awarded $points reply points (quality: ${quality.score})');
      }
    } catch (e) {
      debugPrint('❌ Error awarding reply points: $e');
    }
  }

  // Award points for image sent (with rate limiting and face verification)
  Future<void> awardImagePoints(
    String userId,
    String conversationId,
    String imagePath, {
    String? profileImagePath,
  }) async {
    try {
      // Check image rate limits
      final tracking = await _getMessageTracking(userId, conversationId);
      if (tracking != null && tracking.hasExceededImageLimit()) {
        debugPrint('❌ Image rate limit exceeded for user: $userId');
        return;
      }

      debugPrint('🎯 Verifying face in image for user: $userId');
      
      // Verify that image contains a face
      final faceDetectionService = FaceDetectionService();
      final faceResult = await faceDetectionService.detectFacesInImage(imagePath);
      
      if (!faceResult.success || faceResult.faceCount == 0) {
        debugPrint('❌ No face detected in image - no points awarded');
        faceDetectionService.dispose();
        return;
      }

      // If profile image is provided, compare faces for similarity
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final comparisonResult = await faceDetectionService.compareFaces(
          profileImagePath,
          imagePath,
        );
        
        if (!comparisonResult.isMatch) {
          debugPrint('❌ Face does not match profile - no points awarded');
          debugPrint('   Similarity: ${comparisonResult.similarity}');
          faceDetectionService.dispose();
          return;
        }
        
        debugPrint('✅ Face matches profile! Similarity: ${comparisonResult.similarity}');
      } else {
        debugPrint('✅ Face detected in image (${faceResult.faceCount} face(s))');
      }

      faceDetectionService.dispose();

      debugPrint('🎯 Awarding image points to user: $userId');
      await _updateScore(userId, ScoringRules.imageSentPoints, 'imagesSent');
      await _updateImageTracking(userId, conversationId);
      debugPrint('✅ Image points awarded successfully!');
    } catch (e) {
      debugPrint('❌ Error awarding image points: $e');
      rethrow;
    }
  }

  // Award points for positive feedback
  Future<void> awardPositiveFeedbackPoints(String userId) async {
    await _updateScore(userId, ScoringRules.positiveFeedbackPoints, null);
  }

  // Apply penalty for spam/duplicates
  Future<void> _applyPenalty(String userId, int penaltyPoints) async {
    try {
      await _updateScore(userId, penaltyPoints, null);
      debugPrint('⚠️ Applied penalty: $penaltyPoints points');
    } catch (e) {
      debugPrint('❌ Error applying penalty: $e');
    }
  }

  // Update score helper
  Future<void> _updateScore(String userId, int points, String? statField) async {
    try {
      debugPrint('📝 Starting score update for user: $userId');
      debugPrint('📝 Points: $points, Field: $statField');
      
      final docRef = _firestore.collection('rewards_stats').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          debugPrint('🆕 Creating new stats document');
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
          debugPrint('✅ New stats created: ${newStats.toMap()}');
        } else {
          debugPrint('📊 Updating existing stats');
          final data = snapshot.data()!;
          final oldTotal = data['totalScore'] ?? 0;
          final oldMonthly = data['monthlyScore'] ?? 0;
          
          final updates = {
            'totalScore': oldTotal + points,
            'weeklyScore': (data['weeklyScore'] ?? 0) + points,
            'monthlyScore': oldMonthly + points,
            'lastUpdated': Timestamp.now(),
          };
          
          if (statField != null) {
            updates[statField] = (data[statField] ?? 0) + 1;
          }
          
          debugPrint('📈 Old total: $oldTotal, New total: ${oldTotal + points}');
          debugPrint('📈 Old monthly: $oldMonthly, New monthly: ${oldMonthly + points}');
          debugPrint('📝 Updates: $updates');
          
          transaction.update(docRef, updates);
          debugPrint('✅ Stats updated successfully');
        }
      });
      
      debugPrint('🎉 Transaction completed successfully');
      
      // Check for milestones and send notifications
      await _checkMilestones(userId);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR updating score: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
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

  // Track daily conversation with unique person
  Future<void> trackDailyConversation(String userId, String otherUserId) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final conversationRef = _firestore
          .collection('daily_conversations')
          .doc(userId)
          .collection('dates')
          .doc(dateKey);
      
      final conversationDoc = await conversationRef.get();
      
      if (!conversationDoc.exists) {
        // First conversation of the day
        await conversationRef.set({
          'conversations': [otherUserId],
          'date': Timestamp.now(),
        });
        await _awardConversationBonus(userId, 1);
      } else {
        final data = conversationDoc.data()!;
        final conversations = List<String>.from(data['conversations'] ?? []);
        
        // Check if this is a new unique conversation
        if (!conversations.contains(otherUserId)) {
          conversations.add(otherUserId);
          await conversationRef.update({'conversations': conversations});
          
          // Award bonus (max 10 unique conversations per day)
          if (conversations.length <= 10) {
            await _awardConversationBonus(userId, conversations.length);
          }
        }
      }
    } catch (e) {
      print('Error tracking conversation: $e');
    }
  }

  // Award conversation bonus points
  Future<void> _awardConversationBonus(String userId, int conversationCount) async {
    try {
      final points = ScoringRules.streakBonusPerConversation;
      await _updateScore(userId, points, null);
    } catch (e) {
      print('Error awarding conversation bonus: $e');
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

  // Get message tracking for rate limiting and duplicate detection
  Future<MessageTracking?> _getMessageTracking(String userId, String conversationId) async {
    try {
      final doc = await _firestore
          .collection('message_tracking')
          .doc('${userId}_$conversationId')
          .get();

      if (doc.exists) {
        return MessageTracking.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting message tracking: $e');
      return null;
    }
  }

  // Update message tracking after sending a message
  Future<void> _updateMessageTracking(
    String userId,
    String conversationId,
    String messageText,
    int qualityScore,
  ) async {
    try {
      final docRef = _firestore
          .collection('message_tracking')
          .doc('${userId}_$conversationId');

      final doc = await docRef.get();
      final now = DateTime.now();

      if (!doc.exists) {
        // Create new tracking
        final tracking = MessageTracking(
          userId: userId,
          conversationId: conversationId,
          recentMessages: [messageText],
          messageQualities: [qualityScore],
          hourlyMessageCount: 1,
          hourlyImageCount: 0,
          lastMessageTime: now,
          lastImageTime: now,
          dailyConversationCount: 1,
        );
        await docRef.set(tracking.toMap());
      } else {
        // Update existing tracking
        final data = doc.data()!;
        final lastMessageTime = (data['lastMessageTime'] as Timestamp).toDate();
        final hoursSinceLastMessage = now.difference(lastMessageTime).inHours;

        // Reset hourly counter if more than 1 hour has passed
        final hourlyCount = hoursSinceLastMessage >= 1 ? 1 : (data['hourlyMessageCount'] ?? 0) + 1;

        // Keep only last 10 messages
        final recentMessages = List<String>.from(data['recentMessages'] ?? []);
        recentMessages.add(messageText);
        if (recentMessages.length > RateLimitConfig.maxRecentMessagesTracked) {
          recentMessages.removeAt(0);
        }

        // Keep only last 10 quality scores
        final messageQualities = List<int>.from(data['messageQualities'] ?? []);
        messageQualities.add(qualityScore);
        if (messageQualities.length > RateLimitConfig.maxRecentMessagesTracked) {
          messageQualities.removeAt(0);
        }

        await docRef.update({
          'recentMessages': recentMessages,
          'messageQualities': messageQualities,
          'hourlyMessageCount': hourlyCount,
          'lastMessageTime': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      debugPrint('Error updating message tracking: $e');
    }
  }

  // Update image tracking after sending an image
  Future<void> _updateImageTracking(String userId, String conversationId) async {
    try {
      final docRef = _firestore
          .collection('message_tracking')
          .doc('${userId}_$conversationId');

      final doc = await docRef.get();
      final now = DateTime.now();

      if (doc.exists) {
        final data = doc.data()!;
        final lastImageTime = (data['lastImageTime'] as Timestamp?)?.toDate() ?? now;
        final hoursSinceLastImage = now.difference(lastImageTime).inHours;

        // Reset hourly counter if more than 1 hour has passed
        final hourlyCount = hoursSinceLastImage >= 1 ? 1 : (data['hourlyImageCount'] ?? 0) + 1;

        await docRef.update({
          'hourlyImageCount': hourlyCount,
          'lastImageTime': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      debugPrint('Error updating image tracking: $e');
    }
  }
}
