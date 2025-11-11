import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/spotlight_config.dart';

/// Service to manage spotlight profile rotation in discovery
class SpotlightDiscoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if it's time to show a spotlight profile
  /// Returns true if spotlight should be shown based on interval
  Future<bool> shouldShowSpotlight({
    required int profilesShownCount,
  }) async {
    // Show spotlight every N profiles
    // For example, every 5 profiles, show 1 spotlight
    const int profilesBetweenSpotlight = 5;
    return profilesShownCount > 0 && profilesShownCount % profilesBetweenSpotlight == 0;
  }

  /// Get a spotlight profile to show
  /// Returns null if no spotlight profiles available
  Future<DocumentSnapshot?> getSpotlightProfile({
    required List<String> excludeUserIds,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get active spotlight bookings for today
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final bookingsSnapshot = await _firestore
          .collection('spotlight_bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'active')
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return null;
      }

      // Filter out already shown users and current user
      final availableBookings = bookingsSnapshot.docs.where((doc) {
        final userId = doc.data()['userId'] as String;
        return userId != user.uid && !excludeUserIds.contains(userId);
      }).toList();

      if (availableBookings.isEmpty) {
        return null;
      }

      // Select booking with least appearances today (fair rotation)
      availableBookings.sort((a, b) {
        final aCount = a.data()['appearanceCount'] as int? ?? 0;
        final bCount = b.data()['appearanceCount'] as int? ?? 0;
        return aCount.compareTo(bCount);
      });

      final selectedBooking = availableBookings.first;
      final spotlightUserId = selectedBooking.data()['userId'] as String;

      // Check if this user can be shown again (respect interval)
      final lastShownAt = selectedBooking.data()['lastShownAt'] as Timestamp?;
      if (lastShownAt != null) {
        final lastShown = lastShownAt.toDate();
        final minutesSinceLastShown = now.difference(lastShown).inMinutes;
        
        if (minutesSinceLastShown < SpotlightConfig.appearanceIntervalMinutes) {
          // Too soon, try next booking
          if (availableBookings.length > 1) {
            final nextBooking = availableBookings[1];
            final nextUserId = nextBooking.data()['userId'] as String;
            
            // Record appearance
            await _recordAppearance(nextBooking.id);
            
            // Get user profile
            return await _firestore.collection('users').doc(nextUserId).get();
          }
          return null;
        }
      }

      // Record appearance
      await _recordAppearance(selectedBooking.id);

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(spotlightUserId).get();
      
      return userDoc.exists ? userDoc : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting spotlight profile: $e');
      }
      return null;
    }
  }

  /// Record that a spotlight profile was shown
  Future<void> _recordAppearance(String bookingId) async {
    try {
      await _firestore.collection('spotlight_bookings').doc(bookingId).update({
        'appearanceCount': FieldValue.increment(1),
        'lastShownAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error recording appearance: $e');
      }
    }
  }

  /// Activate pending spotlight bookings for today
  /// This should be called periodically (e.g., via Cloud Function or on app start)
  Future<void> activateTodaySpotlights() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Find pending bookings for today
      final pendingSnapshot = await _firestore
          .collection('spotlight_bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'pending')
          .get();

      // Activate them
      final batch = _firestore.batch();
      for (var doc in pendingSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'active',
          'activatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (kDebugMode) {
        print('Activated ${pendingSnapshot.docs.length} spotlight bookings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error activating spotlights: $e');
      }
    }
  }

  /// Complete spotlight bookings from yesterday
  /// This should be called periodically
  Future<void> completeExpiredSpotlights() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

      // Find active bookings from yesterday
      final activeSnapshot = await _firestore
          .collection('spotlight_bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfYesterday))
          .where('status', isEqualTo: 'active')
          .get();

      // Complete them
      final batch = _firestore.batch();
      for (var doc in activeSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (kDebugMode) {
        print('Completed ${activeSnapshot.docs.length} expired spotlights');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error completing expired spotlights: $e');
      }
    }
  }

  /// Get spotlight statistics for a user
  Future<Map<String, dynamic>> getUserSpotlightStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('spotlight_bookings')
          .where('userId', isEqualTo: userId)
          .get();

      int totalBookings = snapshot.docs.length;
      int activeBookings = 0;
      int completedBookings = 0;
      int totalAppearances = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final appearances = data['appearanceCount'] as int? ?? 0;

        if (status == 'active') activeBookings++;
        if (status == 'completed') completedBookings++;
        totalAppearances += appearances;
      }

      return {
        'totalBookings': totalBookings,
        'activeBookings': activeBookings,
        'completedBookings': completedBookings,
        'totalAppearances': totalAppearances,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting spotlight stats: $e');
      }
      return {
        'totalBookings': 0,
        'activeBookings': 0,
        'completedBookings': 0,
        'totalAppearances': 0,
      };
    }
  }
}
