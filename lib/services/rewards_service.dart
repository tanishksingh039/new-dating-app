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

      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return UserRewardsStats.fromMap(data);
        }
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

  // Get monthly leaderboard (top 20) - ONE TIME
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
    print('[RewardsService] 🔄 getMonthlyLeaderboard STARTED');
    try {
      print('[RewardsService] 📊 Querying rewards_stats (top 20 by monthlyScore)...');
      final snapshot = await _firestore
          .collection('rewards_stats')
          .orderBy('monthlyScore', descending: true)
          .limit(20)
          .get();

      print('[RewardsService] ✅ Query returned ${snapshot.docs.length} documents');
      List<LeaderboardEntry> leaderboard = [];
      int rank = 1;
      int skipped = 0;

      for (var doc in snapshot.docs) {
        final stats = UserRewardsStats.fromMap(doc.data());
        print('[RewardsService] 👤 Processing user: ${stats.userId}, monthlyScore: ${stats.monthlyScore}');
        
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
          print('[RewardsService] ✅ Added to leaderboard: ${user.name} (rank $rank, score ${stats.monthlyScore})');
          rank++;
        } else {
          print('[RewardsService] ⚠️ User document not found for userId: ${stats.userId}');
          skipped++;
        }
      }

      print('[RewardsService] 🎉 getMonthlyLeaderboard COMPLETED: ${leaderboard.length} entries, $skipped skipped');
      return leaderboard;
    } catch (e, stackTrace) {
      print('[RewardsService] ❌ EXCEPTION in getMonthlyLeaderboard: $e');
      print('[RewardsService] ❌ Stack trace: $stackTrace');
      return [];
    }
  }
  
  // Get monthly leaderboard REAL-TIME stream (updates automatically)
  Stream<List<LeaderboardEntry>> getMonthlyLeaderboardStream() {
    print('[RewardsService] 🔄 getMonthlyLeaderboardStream CREATED');
    return _firestore
        .collection('rewards_stats')
        .orderBy('monthlyScore', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
          print('[RewardsService] 📡 Real-time update received: ${snapshot.docs.length} documents');
          List<LeaderboardEntry> leaderboard = [];
          int rank = 1;
          int skipped = 0;

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
            } else {
              print('[RewardsService] ⚠️ User document not found: ${stats.userId}');
              skipped++;
            }
          }

          print('[RewardsService] ✅ Real-time leaderboard updated: ${leaderboard.length} entries');
          return leaderboard;
        })
        .handleError((e, stackTrace) {
          print('[RewardsService] ❌ ERROR in leaderboard stream: $e');
          print('[RewardsService] ❌ Stack trace: $stackTrace');
          return [];
        });
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
    print('═══════════════════════════════════════════════════════════');
    print('[RewardsService] 🔄 awardMessagePoints STARTED');
    print('[RewardsService] userId: $userId');
    print('[RewardsService] conversationId: $conversationId');
    print('[RewardsService] messageText: $messageText');
    print('═══════════════════════════════════════════════════════════');
    
    try {
      // Check rate limits
      print('[RewardsService] 📊 Fetching message tracking...');
      final tracking = await _getMessageTracking(userId, conversationId);
      print('[RewardsService] ✅ Tracking fetched: ${tracking != null}');
      
      if (tracking != null) {
        if (tracking.hasExceededMessageLimit()) {
          print('[RewardsService] ❌ RATE LIMIT EXCEEDED: Message rate limit exceeded for user: $userId');
          debugPrint('❌ Message rate limit exceeded for user: $userId');
          return;
        }
        if (tracking.isTooQuick()) {
          print('[RewardsService] ❌ TOO QUICK: Messages sent too quickly for user: $userId');
          debugPrint('❌ Messages sent too quickly for user: $userId');
          return;
        }
      }

      // Analyze message quality
      print('[RewardsService] 🔍 Analyzing message quality...');
      final quality = MessageContentAnalyzer.analyzeMessage(messageText);
      print('[RewardsService] ✅ Quality score: ${quality.score}, isSpam: ${quality.isSpam}, isGibberish: ${quality.isGibberish}');
      
      // Check for spam/gibberish
      if (quality.isSpam || quality.isGibberish) {
        print('[RewardsService] ❌ SPAM/GIBBERISH: Spam/gibberish detected - no points awarded');
        debugPrint('❌ Spam/gibberish detected - no points awarded');
        await _applyPenalty(userId, ScoringRules.spamPenalty);
        return;
      }

      // Check for duplicates
      if (tracking != null && MessageContentAnalyzer.isDuplicate(messageText, tracking.recentMessages)) {
        print('[RewardsService] ❌ DUPLICATE: Duplicate message detected - penalty applied');
        debugPrint('❌ Duplicate message detected - penalty applied');
        await _applyPenalty(userId, ScoringRules.duplicatePenalty);
        return;
      }

      // Calculate points with quality multiplier
      final multiplier = MessageContentAnalyzer.getPointsMultiplier(quality.score);
      final points = (ScoringRules.messageSentPoints * multiplier).toInt();
      print('[RewardsService] 💰 Points calculated: $points (multiplier: $multiplier, base: ${ScoringRules.messageSentPoints})');

      if (points > 0) {
        print('[RewardsService] 📝 Calling _updateScore with $points points...');
        await _updateScore(userId, points, 'messagesSent');
        print('[RewardsService] ✅ _updateScore completed');
        
        print('[RewardsService] 📝 Updating message tracking...');
        await _updateMessageTracking(userId, conversationId, messageText, quality.score);
        print('[RewardsService] ✅ Message tracking updated');
        
        debugPrint('✅ Awarded $points points (quality: ${quality.score})');
        print('[RewardsService] 🎉 awardMessagePoints COMPLETED SUCCESSFULLY');
      } else {
        print('[RewardsService] ⚠️ ZERO POINTS: Low quality message - no points awarded (quality: ${quality.score})');
        debugPrint('⚠️ Low quality message - no points awarded');
      }
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('[RewardsService] ❌ EXCEPTION in awardMessagePoints: $e');
      print('[RewardsService] ❌ Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════════');
      debugPrint('❌ Error awarding message points: $e');
      rethrow;
    }
  }

  // Award points for reply given (with quality check)
  Future<void> awardReplyPoints(
    String userId,
    String conversationId,
    String messageText,
  ) async {
    print('[RewardsService] 🔄 awardReplyPoints STARTED for user: $userId');
    try {
      // Analyze message quality
      final quality = MessageContentAnalyzer.analyzeMessage(messageText);
      print('[RewardsService] ✅ Reply quality score: ${quality.score}');
      
      if (quality.isSpam || quality.isGibberish) {
        print('[RewardsService] ❌ SPAM REPLY: Spam reply detected - no points awarded');
        debugPrint('❌ Spam reply detected - no points awarded');
        return;
      }

      // Calculate points with quality multiplier
      final multiplier = MessageContentAnalyzer.getPointsMultiplier(quality.score);
      final points = (ScoringRules.replyGivenPoints * multiplier).toInt();
      print('[RewardsService] 💰 Reply points: $points');

      if (points > 0) {
        await _updateScore(userId, points, 'repliesGiven');
        debugPrint('✅ Awarded $points reply points (quality: ${quality.score})');
        print('[RewardsService] ✅ awardReplyPoints COMPLETED');
      }
    } catch (e, stackTrace) {
      print('[RewardsService] ❌ EXCEPTION in awardReplyPoints: $e');
      print('[RewardsService] ❌ Stack trace: $stackTrace');
      debugPrint('❌ Error awarding reply points: $e');
      rethrow;
    }
  }

  // Award points for image sent (with rate limiting and face verification)
  Future<void> awardImagePoints(
    String userId,
    String conversationId,
    String imagePath, {
    String? profileImagePath,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('[RewardsService] 🔄 awardImagePoints STARTED');
    print('[RewardsService] userId: $userId');
    print('[RewardsService] imagePath: $imagePath');
    print('═══════════════════════════════════════════════════════════');
    
    try {
      // Check image rate limits
      print('[RewardsService] 📊 Checking image rate limits...');
      final tracking = await _getMessageTracking(userId, conversationId);
      if (tracking != null && tracking.hasExceededImageLimit()) {
        print('[RewardsService] ❌ IMAGE RATE LIMIT: Image rate limit exceeded for user: $userId');
        debugPrint('❌ Image rate limit exceeded for user: $userId');
        return;
      }

      print('[RewardsService] 🎯 Verifying face in image for user: $userId');
      debugPrint('🎯 Verifying face in image for user: $userId');
      
      // Verify that image contains a face
      final faceDetectionService = FaceDetectionService();
      final faceResult = await faceDetectionService.detectFacesInImage(imagePath);
      print('[RewardsService] ✅ Face detection result: success=${faceResult.success}, faceCount=${faceResult.faceCount}');
      
      if (!faceResult.success || faceResult.faceCount == 0) {
        print('[RewardsService] ❌ NO FACE: No face detected in image - no points awarded');
        debugPrint('❌ No face detected in image - no points awarded');
        faceDetectionService.dispose();
        return;
      }

      // If profile image is provided, compare faces for similarity
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        try {
          print('[RewardsService] 🔍 Comparing faces with profile image...');
          final comparisonResult = await faceDetectionService.compareFaces(
            profileImagePath,
            imagePath,
          );
          print('[RewardsService] ✅ Face comparison result: isMatch=${comparisonResult.isMatch}, similarity=${comparisonResult.similarity}');
          
          if (!comparisonResult.isMatch) {
            print('[RewardsService] ❌ FACE MISMATCH: Face does not match profile - no points awarded (similarity: ${comparisonResult.similarity})');
            debugPrint('❌ Face does not match profile - no points awarded');
            debugPrint('   Similarity: ${comparisonResult.similarity}');
            faceDetectionService.dispose();
            return;
          }
          
          print('[RewardsService] ✅ FACE MATCH: Face matches profile! Similarity: ${comparisonResult.similarity}');
          debugPrint('✅ Face matches profile! Similarity: ${comparisonResult.similarity}');
        } catch (e) {
          print('[RewardsService] ❌ FACE COMPARISON ERROR: Error comparing faces - no points awarded');
          debugPrint('❌ Error comparing faces - no points awarded: $e');
          faceDetectionService.dispose();
          return;
        }
      } else {
        print('[RewardsService] ✅ Face detected in image (${faceResult.faceCount} face(s))');
        debugPrint('✅ Face detected in image (${faceResult.faceCount} face(s))');
      }

      faceDetectionService.dispose();

      print('[RewardsService] 💰 Awarding image points to user: $userId');
      debugPrint('🎯 Awarding image points to user: $userId');
      await _updateScore(userId, ScoringRules.imageSentPoints, 'imagesSent');
      print('[RewardsService] ✅ Score updated');
      
      await _updateImageTracking(userId, conversationId);
      print('[RewardsService] ✅ Image tracking updated');
      
      debugPrint('✅ Image points awarded successfully!');
      print('[RewardsService] 🎉 awardImagePoints COMPLETED SUCCESSFULLY');
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('[RewardsService] ❌ EXCEPTION in awardImagePoints: $e');
      print('[RewardsService] ❌ Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════════');
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
      print('[RewardsService] 📝 Starting score update for user: $userId');
      print('[RewardsService] 📝 Points: $points, Field: $statField');
      debugPrint('📝 Starting score update for user: $userId');
      debugPrint('📝 Points: $points, Field: $statField');
      
      final docRef = _firestore.collection('rewards_stats').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          print('[RewardsService] 🆕 Creating new stats document');
          debugPrint('🆕 Creating new stats document');
          
          // ✅ ENSURE SCORES NEVER GO BELOW 0
          final finalScore = points < 0 ? 0 : points;
          
          // Create new stats
          final newStats = UserRewardsStats(
            userId: userId,
            totalScore: finalScore,
            weeklyScore: finalScore,
            monthlyScore: finalScore,
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
          print('[RewardsService] ✅ New stats created with score: $finalScore');
          debugPrint('✅ New stats created: ${newStats.toMap()}');
        } else {
          print('[RewardsService] 📊 Updating existing stats');
          debugPrint('📊 Updating existing stats');
          final data = snapshot.data()!;
          final oldTotal = data['totalScore'] ?? 0;
          final oldMonthly = data['monthlyScore'] ?? 0;
          
          // ✅ ENSURE SCORES NEVER GO BELOW 0
          final newTotal = (oldTotal + points) < 0 ? 0 : (oldTotal + points);
          final newMonthly = (oldMonthly + points) < 0 ? 0 : (oldMonthly + points);
          final newWeekly = ((data['weeklyScore'] ?? 0) + points) < 0 ? 0 : ((data['weeklyScore'] ?? 0) + points);
          
          final updates = {
            'totalScore': newTotal,
            'weeklyScore': newWeekly,
            'monthlyScore': newMonthly,
            'lastUpdated': Timestamp.now(),
          };
          
          if (statField != null) {
            updates[statField] = (data[statField] ?? 0) + 1;
          }
          
          print('[RewardsService] 📈 Old total: $oldTotal → New total: $newTotal');
          print('[RewardsService] 📈 Old monthly: $oldMonthly → New monthly: $newMonthly');
          print('[RewardsService] 📝 Updates: $updates');
          debugPrint('📈 Old total: $oldTotal, New total: $newTotal');
          debugPrint('📈 Old monthly: $oldMonthly, New monthly: $newMonthly');
          debugPrint('📝 Updates: $updates');
          
          transaction.update(docRef, updates);
          print('[RewardsService] ✅ Stats updated successfully');
          debugPrint('✅ Stats updated successfully');
        }
      });
      
      print('[RewardsService] 🎉 Transaction completed successfully');
      debugPrint('🎉 Transaction completed successfully');
      
      // Check for milestones and send notifications
      await _checkMilestones(userId);
    } catch (e, stackTrace) {
      print('[RewardsService] ❌ ERROR updating score: $e');
      print('[RewardsService] ❌ Stack trace: $stackTrace');
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
      
      if (!doc.exists || doc.data() == null) return;
      
      final docData = doc.data();
      if (docData is! Map<String, dynamic>) return;
      final data = docData;
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

      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return MessageTracking.fromMap(data);
        }
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
        final docData = doc.data();
        if (docData is! Map<String, dynamic>) return;
        final data = docData;
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

      if (doc.exists && doc.data() != null) {
        final docData = doc.data();
        if (docData is! Map<String, dynamic>) return;
        final data = docData;
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
