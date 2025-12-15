import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LeaderboardOptOutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user has opted out of leaderboard
  Future<bool> isOptedOut(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final isOptedOut = (data?['isOptedOutOfLeaderboard'] as bool?) ?? false;
      
      print('[LeaderboardOptOutService] User $userId opted out: $isOptedOut');
      return isOptedOut;
    } catch (e) {
      print('[LeaderboardOptOutService] ❌ Error checking opt-out status: $e');
      return false;
    }
  }

  // Opt user out of leaderboard
  Future<void> optOut(String userId) async {
    try {
      print('[LeaderboardOptOutService] 🔇 Opting out user: $userId');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'isOptedOutOfLeaderboard': true,
            'optedOutAt': FieldValue.serverTimestamp(),
          });

      print('[LeaderboardOptOutService] ✅ User $userId opted out successfully');
    } catch (e) {
      print('[LeaderboardOptOutService] ❌ Error opting out: $e');
      rethrow;
    }
  }

  // Opt user back in to leaderboard
  Future<void> optIn(String userId) async {
    try {
      print('[LeaderboardOptOutService] 🔊 Opting in user: $userId');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'isOptedOutOfLeaderboard': false,
            'optedInAt': FieldValue.serverTimestamp(),
          });

      print('[LeaderboardOptOutService] ✅ User $userId opted in successfully');
    } catch (e) {
      print('[LeaderboardOptOutService] ❌ Error opting in: $e');
      rethrow;
    }
  }

  // Get opt-out status stream (real-time updates)
  Stream<bool> getOptOutStatusStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return false;
          }
          final data = snapshot.data() as Map<String, dynamic>?;
          return (data?['isOptedOutOfLeaderboard'] as bool?) ?? false;
        })
        .handleError((e) {
          print('[LeaderboardOptOutService] ❌ Error in stream: $e');
          return false;
        });
  }

  // Get opt-out timestamp
  Future<DateTime?> getOptOutTimestamp(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final timestamp = data?['optedOutAt'] as Timestamp?;
      
      return timestamp?.toDate();
    } catch (e) {
      print('[LeaderboardOptOutService] ❌ Error getting opt-out timestamp: $e');
      return null;
    }
  }

  // Get opt-in timestamp
  Future<DateTime?> getOptInTimestamp(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final timestamp = data?['optedInAt'] as Timestamp?;
      
      return timestamp?.toDate();
    } catch (e) {
      print('[LeaderboardOptOutService] ❌ Error getting opt-in timestamp: $e');
      return null;
    }
  }
}
