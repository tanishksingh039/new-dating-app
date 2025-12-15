import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LeaderboardAntiArmingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constants
  static const int WINDOW_DURATION_HOURS = 6;
  static const int MAX_POINTS_MINUTES_PER_USER_PER_WINDOW = 35;
  static const int WINDOWS_PER_DAY = 4;
  static const int MAX_POINTS_MINUTES_PER_DAY = MAX_POINTS_MINUTES_PER_USER_PER_WINDOW * WINDOWS_PER_DAY; // 140 minutes

  // Get current 6-hour window start time
  DateTime _getCurrentWindowStart() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Determine which window we're in
    int windowStartHour;
    if (hour < 6) {
      windowStartHour = 0; // Window 1: 12:00 AM - 6:00 AM
    } else if (hour < 12) {
      windowStartHour = 6; // Window 2: 6:00 AM - 12:00 PM
    } else if (hour < 18) {
      windowStartHour = 12; // Window 3: 12:00 PM - 6:00 PM
    } else {
      windowStartHour = 18; // Window 4: 6:00 PM - 12:00 AM
    }
    
    return DateTime(now.year, now.month, now.day, windowStartHour, 0, 0);
  }

  // Get window ID for tracking (e.g., "2024-12-14_window_1")
  String _getWindowId(DateTime windowStart) {
    final dateStr = '${windowStart.year}-${windowStart.month.toString().padLeft(2, '0')}-${windowStart.day.toString().padLeft(2, '0')}';
    final windowNum = (windowStart.hour ~/ 6) + 1;
    return '${dateStr}_window_$windowNum';
  }

  // Check if a female user can earn points with a specific male user in current window
  Future<bool> canEarnPointsWithUser(
    String femaleUserId,
    String maleUserId,
  ) async {
    try {
      final windowStart = _getCurrentWindowStart();
      final windowId = _getWindowId(windowStart);
      
      print('[AntiArmingService] 🔍 Checking points eligibility');
      print('[AntiArmingService] Female: $femaleUserId, Male: $maleUserId');
      print('[AntiArmingService] Window: $windowId');

      // Get interaction tracking document
      final trackingDoc = await _firestore
          .collection('interaction_tracking')
          .doc('${femaleUserId}_${maleUserId}_$windowId')
          .get();

      if (!trackingDoc.exists) {
        print('[AntiArmingService] ✅ No prior interactions in this window - can earn points');
        return true;
      }

      final data = trackingDoc.data()!;
      final pointsMinutesUsed = (data['pointsMinutesUsed'] as num?)?.toInt() ?? 0;
      
      print('[AntiArmingService] 📊 Points minutes used: $pointsMinutesUsed / $MAX_POINTS_MINUTES_PER_USER_PER_WINDOW');

      if (pointsMinutesUsed >= MAX_POINTS_MINUTES_PER_USER_PER_WINDOW) {
        print('[AntiArmingService] ❌ Points cap reached for this user in this window');
        return false;
      }

      print('[AntiArmingService] ✅ Can still earn points (${MAX_POINTS_MINUTES_PER_USER_PER_WINDOW - pointsMinutesUsed} minutes remaining)');
      return true;
    } catch (e) {
      print('[AntiArmingService] ❌ Error checking eligibility: $e');
      // Default to allowing points if there's an error (fail-open)
      return true;
    }
  }

  // Record interaction and update points minutes used
  Future<void> recordInteraction(
    String femaleUserId,
    String maleUserId,
    int durationSeconds,
  ) async {
    try {
      final windowStart = _getCurrentWindowStart();
      final windowId = _getWindowId(windowStart);
      final durationMinutes = (durationSeconds / 60).ceil();

      print('[AntiArmingService] 📝 Recording interaction');
      print('[AntiArmingService] Female: $femaleUserId, Male: $maleUserId');
      print('[AntiArmingService] Duration: $durationSeconds seconds ($durationMinutes minutes)');
      print('[AntiArmingService] Window: $windowId');

      final trackingRef = _firestore
          .collection('interaction_tracking')
          .doc('${femaleUserId}_${maleUserId}_$windowId');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(trackingRef);
        
        int currentMinutes = 0;
        if (doc.exists) {
          currentMinutes = (doc.data()!['pointsMinutesUsed'] as num?)?.toInt() ?? 0;
        }

        final newMinutes = (currentMinutes + durationMinutes).clamp(0, MAX_POINTS_MINUTES_PER_USER_PER_WINDOW);
        final minutesAdded = newMinutes - currentMinutes;

        transaction.set(trackingRef, {
          'femaleUserId': femaleUserId,
          'maleUserId': maleUserId,
          'windowId': windowId,
          'windowStart': Timestamp.fromDate(windowStart),
          'pointsMinutesUsed': newMinutes,
          'lastUpdated': FieldValue.serverTimestamp(),
          'interactions': FieldValue.arrayUnion([{
            'timestamp': FieldValue.serverTimestamp(),
            'durationSeconds': durationSeconds,
            'durationMinutes': durationMinutes,
          }]),
        }, SetOptions(merge: true));

        print('[AntiArmingService] ✅ Recorded $minutesAdded minutes (Total: $newMinutes / $MAX_POINTS_MINUTES_PER_USER_PER_WINDOW)');
      });
    } catch (e) {
      print('[AntiArmingService] ❌ Error recording interaction: $e');
      rethrow;
    }
  }

  // Get remaining points minutes for a user pair in current window
  Future<int> getRemainingPointsMinutes(
    String femaleUserId,
    String maleUserId,
  ) async {
    try {
      final windowStart = _getCurrentWindowStart();
      final windowId = _getWindowId(windowStart);

      final trackingDoc = await _firestore
          .collection('interaction_tracking')
          .doc('${femaleUserId}_${maleUserId}_$windowId')
          .get();

      if (!trackingDoc.exists) {
        return MAX_POINTS_MINUTES_PER_USER_PER_WINDOW;
      }

      final pointsMinutesUsed = (trackingDoc.data()!['pointsMinutesUsed'] as num?)?.toInt() ?? 0;
      return MAX_POINTS_MINUTES_PER_USER_PER_WINDOW - pointsMinutesUsed;
    } catch (e) {
      print('[AntiArmingService] ❌ Error getting remaining minutes: $e');
      return MAX_POINTS_MINUTES_PER_USER_PER_WINDOW;
    }
  }

  // Get daily stats for a female user (across all male users)
  Future<Map<String, dynamic>> getDailyStats(String femaleUserId) async {
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      
      // Get all windows for today
      final windows = <String>[];
      for (int i = 0; i < WINDOWS_PER_DAY; i++) {
        final windowStart = dayStart.add(Duration(hours: i * 6));
        windows.add(_getWindowId(windowStart));
      }

      print('[AntiArmingService] 📊 Getting daily stats for $femaleUserId');
      print('[AntiArmingService] Windows: $windows');

      int totalPointsMinutes = 0;
      int totalInteractions = 0;
      final userInteractions = <String, int>{}; // maleUserId -> minutes

      for (final windowId in windows) {
        final snapshot = await _firestore
            .collection('interaction_tracking')
            .where('femaleUserId', isEqualTo: femaleUserId)
            .where('windowId', isEqualTo: windowId)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final maleUserId = data['maleUserId'] as String;
          final minutes = (data['pointsMinutesUsed'] as num?)?.toInt() ?? 0;
          
          totalPointsMinutes += minutes;
          totalInteractions += (data['interactions'] as List?)?.length ?? 0;
          userInteractions[maleUserId] = (userInteractions[maleUserId] ?? 0) + minutes;
        }
      }

      return {
        'totalPointsMinutes': totalPointsMinutes,
        'maxPointsMinutes': MAX_POINTS_MINUTES_PER_DAY,
        'remainingMinutes': MAX_POINTS_MINUTES_PER_DAY - totalPointsMinutes,
        'totalInteractions': totalInteractions,
        'userInteractions': userInteractions,
        'uniqueUsers': userInteractions.length,
      };
    } catch (e) {
      print('[AntiArmingService] ❌ Error getting daily stats: $e');
      return {
        'totalPointsMinutes': 0,
        'maxPointsMinutes': MAX_POINTS_MINUTES_PER_DAY,
        'remainingMinutes': MAX_POINTS_MINUTES_PER_DAY,
        'totalInteractions': 0,
        'userInteractions': {},
        'uniqueUsers': 0,
      };
    }
  }

  // Clean up old tracking records (older than 7 days)
  Future<void> cleanupOldRecords() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      print('[AntiArmingService] 🧹 Cleaning up records older than 7 days');

      final snapshot = await _firestore
          .collection('interaction_tracking')
          .where('windowStart', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      print('[AntiArmingService] Found ${snapshot.docs.length} old records to delete');

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('[AntiArmingService] ✅ Cleanup completed');
    } catch (e) {
      print('[AntiArmingService] ❌ Error cleaning up records: $e');
    }
  }
}
