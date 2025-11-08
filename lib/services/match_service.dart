import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Check if both users liked each other and create a match
  /// UPDATED: Now checks subcollections for accurate match detection
  Future<bool> checkAndCreateMatch(String userId, String targetUserId) async {
    try {
      // Check if target user has liked current user
      // Check both centralized collection and subcollections
      final targetLikedUser = await _hasUserLiked(targetUserId, userId);

      if (targetLikedUser) {
        // Create match
        await _createMatch(userId, targetUserId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking match: $e');
      return false;
    }
  }

  /// Check if user has liked another user
  /// UPDATED: Checks both centralized collection and subcollections
  Future<bool> _hasUserLiked(String userId, String targetUserId) async {
    try {
      // Method 1: Check centralized swipes collection
      final snapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .where('targetUserId', isEqualTo: targetUserId)
          .where('action', whereIn: ['like', 'superlike'])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) return true;

      // Method 2: Check subcollections (more reliable)
      final likeDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('likes')
          .doc(targetUserId)
          .get();

      if (likeDoc.exists) return true;

      final superLikeDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('superLikes')
          .doc(targetUserId)
          .get();

      return superLikeDoc.exists;
    } catch (e) {
      debugPrint('Error checking if user liked: $e');
      return false;
    }
  }

  /// Create a match between two users
  /// UPDATED: Uses batch writes for atomic operations
  Future<void> _createMatch(String user1Id, String user2Id) async {
    try {
      // Create a unique match ID (sorted to ensure consistency)
      final matchId = _generateMatchId(user1Id, user2Id);

      // Check if match already exists
      final existingMatch = await _firestore.collection('matches').doc(matchId).get();
      if (existingMatch.exists) {
        debugPrint('Match already exists: $matchId');
        return;
      }

      final batch = _firestore.batch();

      // 1. Create match document
      final matchRef = _firestore.collection('matches').doc(matchId);
      batch.set(matchRef, {
        'users': [user1Id, user2Id],
        'matchedAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'lastMessage': null,
        'isActive': true,
      });

      // 2. Update both users' match lists
      final user1Ref = _firestore.collection('users').doc(user1Id);
      batch.update(user1Ref, {
        'matches': FieldValue.arrayUnion([user2Id]),
        'matchCount': FieldValue.increment(1),
      });

      final user2Ref = _firestore.collection('users').doc(user2Id);
      batch.update(user2Ref, {
        'matches': FieldValue.arrayUnion([user1Id]),
        'matchCount': FieldValue.increment(1),
      });

      // Commit all changes atomically
      await batch.commit();
      debugPrint('Match created successfully: $matchId');

      // Send push notifications to both users
      await _sendMatchNotifications(user1Id, user2Id);
    } catch (e) {
      debugPrint('Error creating match: $e');
      rethrow; // Rethrow so caller can handle the error
    }
  }

  /// Generate a consistent match ID for two users
  String _generateMatchId(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Get all matches for a user
  /// UPDATED: Removed problematic orderBy to avoid index requirement
  Future<List<UserModel>> getMatches(String userId) async {
    try {
      // Get user's match list from user document (simpler approach)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final matchIds = List<String>.from(userDoc.data()?['matches'] ?? []);

      if (matchIds.isEmpty) return [];

      // Get matched users' data with their match timestamps
      List<Map<String, dynamic>> matchData = [];
      
      for (String matchId in matchIds) {
        // Get user data
        final userDocSnapshot = await _firestore.collection('users').doc(matchId).get();
        if (!userDocSnapshot.exists) continue;

        // Get match document to get timestamp
        final matchDocId = _generateMatchId(userId, matchId);
        final matchDoc = await _firestore.collection('matches').doc(matchDocId).get();
        
        if (matchDoc.exists) {
          matchData.add({
            'user': UserModel.fromMap(userDocSnapshot.data()!),
            'lastMessageAt': matchDoc.data()?['lastMessageAt'],
            'matchedAt': matchDoc.data()?['matchedAt'],
          });
        } else {
          // If no match document, just add user without timestamp
          matchData.add({
            'user': UserModel.fromMap(userDocSnapshot.data()!),
            'lastMessageAt': null,
            'matchedAt': null,
          });
        }
      }

      // Sort by last message time, then by matched time (most recent first)
      matchData.sort((a, b) {
        final aTime = a['lastMessageAt'] as Timestamp? ?? a['matchedAt'] as Timestamp?;
        final bTime = b['lastMessageAt'] as Timestamp? ?? b['matchedAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime); // Descending order (newest first)
      });

      // Return sorted list of users
      return matchData.map((data) => data['user'] as UserModel).toList();
    } catch (e) {
      debugPrint('Error getting matches: $e');
      rethrow; // Let the UI handle the error
    }
  }

  /// Get match details
  Future<Map<String, dynamic>?> getMatchDetails(String user1Id, String user2Id) async {
    try {
      final matchId = _generateMatchId(user1Id, user2Id);
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();

      if (!matchDoc.exists) return null;

      return matchDoc.data();
    } catch (e) {
      debugPrint('Error getting match details: $e');
      return null;
    }
  }

  /// Check if two users are matched
  Future<bool> areUsersMatched(String user1Id, String user2Id) async {
    try {
      final matchId = _generateMatchId(user1Id, user2Id);
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();

      return matchDoc.exists && matchDoc.data()?['isActive'] == true;
    } catch (e) {
      debugPrint('Error checking if users are matched: $e');
      return false;
    }
  }

  /// Unmatch users
  /// UPDATED: Uses batch writes and removes likes/superLikes
  Future<void> unmatch(String user1Id, String user2Id) async {
    try {
      final matchId = _generateMatchId(user1Id, user2Id);
      final batch = _firestore.batch();

      // 1. Mark match as inactive
      final matchRef = _firestore.collection('matches').doc(matchId);
      batch.update(matchRef, {
        'isActive': false,
        'unmatchedAt': FieldValue.serverTimestamp(),
      });

      // 2. Remove from both users' match lists
      final user1Ref = _firestore.collection('users').doc(user1Id);
      batch.update(user1Ref, {
        'matches': FieldValue.arrayRemove([user2Id]),
        'matchCount': FieldValue.increment(-1),
      });

      final user2Ref = _firestore.collection('users').doc(user2Id);
      batch.update(user2Ref, {
        'matches': FieldValue.arrayRemove([user1Id]),
        'matchCount': FieldValue.increment(-1),
      });

      // 3. Delete likes/superLikes to prevent immediate rematching
      batch.delete(_firestore
          .collection('users')
          .doc(user1Id)
          .collection('likes')
          .doc(user2Id));
      
      batch.delete(_firestore
          .collection('users')
          .doc(user1Id)
          .collection('superLikes')
          .doc(user2Id));
      
      batch.delete(_firestore
          .collection('users')
          .doc(user2Id)
          .collection('likes')
          .doc(user1Id));
      
      batch.delete(_firestore
          .collection('users')
          .doc(user2Id)
          .collection('superLikes')
          .doc(user1Id));

      await batch.commit();
      debugPrint('Users unmatched successfully: $matchId');

      // TODO: Delete chat messages or mark as deleted
    } catch (e) {
      debugPrint('Error unmatching users: $e');
      rethrow;
    }
  }

  /// Get users who liked current user (premium feature)
  /// UPDATED: Now checks subcollections for better accuracy
  Future<List<UserModel>> getUsersWhoLikedMe(String userId) async {
    try {
      // Check receivedLikes subcollection (more reliable)
      final receivedLikesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('receivedLikes')
          .get();

      // Also check receivedSuperLikes
      final receivedSuperLikesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('receivedSuperLikes')
          .get();

      Set<String> likerIds = {};
      likerIds.addAll(receivedLikesSnapshot.docs.map((doc) => doc.id));
      likerIds.addAll(receivedSuperLikesSnapshot.docs.map((doc) => doc.id));

      List<UserModel> users = [];
      for (String likerUserId in likerIds) {
        // Check if not already matched
        final isMatched = await areUsersMatched(userId, likerUserId);
        if (isMatched) continue;

        // Get user data
        final userDoc = await _firestore.collection('users').doc(likerUserId).get();
        if (userDoc.exists && userDoc.data() != null) {
          users.add(UserModel.fromMap(userDoc.data()!));
        }
      }

      return users;
    } catch (e) {
      debugPrint('Error getting users who liked me: $e');
      rethrow;
    }
  }

  /// Get match statistics
  /// UPDATED: Uses subcollections for accurate counts
  Future<Map<String, int>> getMatchStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      // Get counts from subcollections
      final likesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('likes')
          .get();

      final passesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('passes')
          .get();

      final superLikesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('superLikes')
          .get();

      final receivedLikesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('receivedLikes')
          .get();

      final receivedSuperLikesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('receivedSuperLikes')
          .get();

      return {
        'matches': userData?['matchCount'] ?? 0,
        'likes': likesSnapshot.docs.length,
        'passes': passesSnapshot.docs.length,
        'superlikes': superLikesSnapshot.docs.length,
        'receivedLikes': receivedLikesSnapshot.docs.length + receivedSuperLikesSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting match stats: $e');
      return {};
    }
  }

  /// Send match notifications to both users
  Future<void> _sendMatchNotifications(String user1Id, String user2Id) async {
    try {
      // Get both users' data
      final user1Doc = await _firestore.collection('users').doc(user1Id).get();
      final user2Doc = await _firestore.collection('users').doc(user2Id).get();

      final user1Name = user1Doc.data()?['name'] ?? 'Someone';
      final user2Name = user2Doc.data()?['name'] ?? 'Someone';

      // Send notification to user1
      await _notificationService.sendMatchNotification(
        targetUserId: user1Id,
        matchedUserName: user2Name,
      );

      // Send notification to user2
      await _notificationService.sendMatchNotification(
        targetUserId: user2Id,
        matchedUserName: user1Name,
      );

      debugPrint('✅ Match notifications sent to both users');
    } catch (e) {
      debugPrint('❌ Error sending match notifications: $e');
    }
  }
}