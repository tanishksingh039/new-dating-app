import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if both users liked each other and create a match
  Future<bool> checkAndCreateMatch(String userId, String targetUserId) async {
    try {
      // Check if target user has liked current user
      final targetLikedUser = await _hasUserLiked(targetUserId, userId);

      if (targetLikedUser) {
        // Create match
        await _createMatch(userId, targetUserId);
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking match: $e');
      return false;
    }
  }

  /// Check if user has liked another user
  Future<bool> _hasUserLiked(String userId, String targetUserId) async {
    try {
      final snapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .where('targetUserId', isEqualTo: targetUserId)
          .where('action', whereIn: ['like', 'superlike'])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user liked: $e');
      return false;
    }
  }

  /// Create a match between two users
  Future<void> _createMatch(String user1Id, String user2Id) async {
    try {
      // Create a unique match ID (sorted to ensure consistency)
      final matchId = _generateMatchId(user1Id, user2Id);

      // Check if match already exists
      final existingMatch = await _firestore.collection('matches').doc(matchId).get();
      if (existingMatch.exists) return;

      // Create match document
      await _firestore.collection('matches').doc(matchId).set({
        'users': [user1Id, user2Id],
        'matchedAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'lastMessage': null,
        'isActive': true,
      });

      // Update both users' match lists
      await _firestore.collection('users').doc(user1Id).update({
        'matches': FieldValue.arrayUnion([user2Id]),
        'matchCount': FieldValue.increment(1),
      });

      await _firestore.collection('users').doc(user2Id).update({
        'matches': FieldValue.arrayUnion([user1Id]),
        'matchCount': FieldValue.increment(1),
      });

      // TODO: Send push notifications to both users
      // await _sendMatchNotification(user1Id, user2Id);
      // await _sendMatchNotification(user2Id, user1Id);
    } catch (e) {
      print('Error creating match: $e');
      throw e;
    }
  }

  /// Generate a consistent match ID for two users
  String _generateMatchId(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Get all matches for a user
  Future<List<UserModel>> getMatches(String userId) async {
    try {
      // Get user's match list
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final matchIds = List<String>.from(userDoc.data()?['matches'] ?? []);

      if (matchIds.isEmpty) return [];

      // Get matched users' data
      List<UserModel> matches = [];
      for (String matchId in matchIds) {
        final matchDoc = await _firestore.collection('users').doc(matchId).get();
        if (matchDoc.exists) {
          matches.add(UserModel.fromMap(matchDoc.data()!));
        }
      }

      // Sort by last message time (most recent first)
      // This will be enhanced when we implement the messaging system
      return matches;
    } catch (e) {
      print('Error getting matches: $e');
      return [];
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
      print('Error getting match details: $e');
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
      print('Error checking if users are matched: $e');
      return false;
    }
  }

  /// Unmatch users
  Future<void> unmatch(String user1Id, String user2Id) async {
    try {
      final matchId = _generateMatchId(user1Id, user2Id);

      // Mark match as inactive
      await _firestore.collection('matches').doc(matchId).update({
        'isActive': false,
        'unmatchedAt': FieldValue.serverTimestamp(),
      });

      // Remove from both users' match lists
      await _firestore.collection('users').doc(user1Id).update({
        'matches': FieldValue.arrayRemove([user2Id]),
        'matchCount': FieldValue.increment(-1),
      });

      await _firestore.collection('users').doc(user2Id).update({
        'matches': FieldValue.arrayRemove([user1Id]),
        'matchCount': FieldValue.increment(-1),
      });

      // TODO: Delete chat messages or mark as deleted
    } catch (e) {
      print('Error unmatching users: $e');
      throw e;
    }
  }

  /// Get users who liked current user (premium feature)
  Future<List<UserModel>> getUsersWhoLikedMe(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('swipes')
          .where('targetUserId', isEqualTo: userId)
          .where('action', whereIn: ['like', 'superlike'])
          .get();

      List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        final likerUserId = doc['userId'] as String;
        
        // Check if not already matched
        final isMatched = await areUsersMatched(userId, likerUserId);
        if (isMatched) continue;

        // Get user data
        final userDoc = await _firestore.collection('users').doc(likerUserId).get();
        if (userDoc.exists) {
          users.add(UserModel.fromMap(userDoc.data()!));
        }
      }

      return users;
    } catch (e) {
      print('Error getting users who liked me: $e');
      return [];
    }
  }

  /// Get match statistics
  Future<Map<String, int>> getMatchStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      // Get swipe counts
      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .get();

      int likes = 0, passes = 0, superlikes = 0;
      for (var doc in swipesSnapshot.docs) {
        final action = doc['action'] as String;
        if (action == 'like') likes++;
        if (action == 'pass') passes++;
        if (action == 'superlike') superlikes++;
      }

      // Get received likes count
      final receivedLikesSnapshot = await _firestore
          .collection('swipes')
          .where('targetUserId', isEqualTo: userId)
          .where('action', whereIn: ['like', 'superlike'])
          .get();

      return {
        'matches': userData?['matchCount'] ?? 0,
        'likes': likes,
        'passes': passes,
        'superlikes': superlikes,
        'receivedLikes': receivedLikesSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting match stats: $e');
      return {};
    }
  }
}