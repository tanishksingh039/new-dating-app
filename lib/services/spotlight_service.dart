import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/spotlight_booking.dart';
import '../config/spotlight_config.dart';

/// Service to manage spotlight bookings and payments
class SpotlightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if a date is already booked
  Future<bool> isDateBooked(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('spotlight_bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'active']).get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking date availability: $e');
      }
      return false;
    }
  }

  /// Get booking status for a date range (for calendar)
  Future<List<SpotlightDateStatus>> getDateStatuses(
    DateTime startDate,
    DateTime endDate,
  ) async {
    print('\n🔍 ===== GET DATE STATUSES =====');
    print('📅 Range: ${startDate.day}/${startDate.month} to ${endDate.day}/${endDate.month}');
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return [];
      }
      print('✅ User: ${user.uid}');

      print('\n📡 Querying Firestore (WORKAROUND - no composite index)...');
      
      // WORKAROUND: Query without status filter to avoid composite index requirement
      // Filter by status in code instead
      final snapshot = await _firestore
          .collection('spotlight_bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      print('✅ Query returned ${snapshot.docs.length} documents (before filtering)');

      // Only return statuses for dates that actually have bookings
      final List<SpotlightDateStatus> statuses = [];
      int filteredCount = 0;
      
      for (var doc in snapshot.docs) {
        final booking = SpotlightBooking.fromFirestore(doc);
        
        // Filter by status in code (pending or active only)
        if (booking.status != 'pending' && booking.status != 'active') {
          filteredCount++;
          print('   ⏭️  Skipping ${doc.id}: status=${booking.status}');
          continue;
        }
        
        final isYours = booking.userId == user.uid;
        
        print('   📄 Doc ${doc.id}:');
        print('      Date: ${booking.date.day}/${booking.date.month}/${booking.date.year}');
        print('      User: ${booking.userId}');
        print('      Status: ${booking.status}');
        print('      Yours: $isYours');
        
        statuses.add(SpotlightDateStatus(
          date: booking.date,
          isBooked: true,
          isBookedByCurrentUser: isYours,
          bookingId: booking.id,
        ));
      }

      print('\n✅ Filtered out $filteredCount bookings (completed/cancelled)');
      print('✅ Returning ${statuses.length} date statuses');
      print('===============================\n');
      return statuses;
    } catch (e, stackTrace) {
      print('\n❌ Error getting date statuses: $e');
      print('Stack trace: $stackTrace');
      
      // Check if it's the index error
      if (e.toString().contains('failed-precondition') || 
          e.toString().contains('requires an index')) {
        print('⚠️  FIRESTORE INDEX MISSING!');
        print('⚠️  Create index at Firebase Console or use the link in the error');
      }
      
      print('===============================\n');
      return [];
    }
  }

  /// Get user's spotlight bookings
  Stream<List<SpotlightBooking>> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('spotlight_bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpotlightBooking.fromFirestore(doc))
            .toList());
  }

  /// Get active spotlight profiles for today
  Future<List<String>> getActiveSpotlightUserIds() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('spotlight_bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active spotlight users: $e');
      }
      return [];
    }
  }

  /// Create spotlight booking record (payment handled by Google Play Billing)
  /// Call this after successful Google Play purchase
  Future<String> createSpotlightBooking({
    required DateTime selectedDate,
    required String purchaseId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if date is already booked
      final isBooked = await isDateBooked(selectedDate);
      if (isBooked) {
        throw Exception('This date is already booked');
      }

      // Create spotlight booking
      final bookingRef = _firestore.collection('spotlight_bookings').doc();
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      final bookingData = {
        'userId': user.uid,
        'date': Timestamp.fromDate(startOfDay),
        'status': 'pending',
        'paymentId': purchaseId,
        'amount': SpotlightConfig.spotlightPriceInPaise,
        'createdAt': FieldValue.serverTimestamp(),
        'appearanceCount': 0,
      };

      await bookingRef.set(bookingData);
      
      // Log payment
      await _firestore.collection('payment_orders').add({
        'userId': user.uid,
        'purchaseId': purchaseId,
        'amount': SpotlightConfig.spotlightPriceInPaise,
        'type': 'spotlight',
        'spotlightDate': Timestamp.fromDate(startOfDay),
        'spotlightBookingId': bookingRef.id,
        'status': 'success',
        'platform': 'google_play',
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Spotlight booking created: ${bookingRef.id}');
      }
      
      return bookingRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating spotlight booking: $e');
      }
      rethrow;
    }
  }

  /// Handle successful spotlight payment
  Future<void> handleSpotlightPaymentSuccess({
    required String paymentId,
    required DateTime spotlightDate,
    String? orderId,
    String? signature,
  }) async {
    print('\n🎯 ===== SPOTLIGHT PAYMENT SUCCESS HANDLER =====');
    print('📅 Date: ${spotlightDate.day}/${spotlightDate.month}/${spotlightDate.year}');
    print('💳 Payment ID: $paymentId');
    print('📝 Order ID: $orderId');
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }
      print('✅ User authenticated: ${user.uid}');

      // Create spotlight booking
      final bookingRef = _firestore.collection('spotlight_bookings').doc();
      final startOfDay = DateTime(spotlightDate.year, spotlightDate.month, spotlightDate.day);
      
      print('\n📝 Creating booking document...');
      print('   Booking ID: ${bookingRef.id}');
      print('   Date: $startOfDay');
      print('   Status: pending');

      final bookingData = {
        'userId': user.uid,
        'date': Timestamp.fromDate(startOfDay),
        'status': 'pending',
        'paymentId': paymentId,
        'amount': SpotlightConfig.spotlightPriceInPaise,
        'createdAt': FieldValue.serverTimestamp(),
        'appearanceCount': 0,
      };

      await bookingRef.set(bookingData);
      print('✅ Booking document created successfully');
      
      // Verify booking was created
      final verifyBooking = await bookingRef.get();
      if (verifyBooking.exists) {
        print('✅ Booking verified in Firestore');
        final data = verifyBooking.data();
        print('   Stored data: ${data.toString()}');
      } else {
        print('❌ WARNING: Booking not found after creation!');
      }

      // Log payment success
      print('\n📝 Creating payment order record...');
      final paymentDoc = await _firestore.collection('payment_orders').add({
        'userId': user.uid,
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
        'amount': SpotlightConfig.spotlightPriceInPaise,
        'type': 'spotlight',
        'spotlightDate': Timestamp.fromDate(startOfDay),
        'spotlightBookingId': bookingRef.id,
        'status': 'success',
        'completedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Payment order created: ${paymentDoc.id}');

      print('\n🎉 ===== SPOTLIGHT BOOKING COMPLETED =====');
      print('   Booking ID: ${bookingRef.id}');
      print('   Date: ${startOfDay.day}/${startOfDay.month}/${startOfDay.year}');
      print('   User: ${user.uid}');
      print('=========================================\n');
      
    } catch (e, stackTrace) {
      print('\n❌ ===== SPOTLIGHT BOOKING FAILED =====');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('======================================\n');
      rethrow;
    }
  }

  /// Update spotlight appearance count
  Future<void> recordSpotlightAppearance(String bookingId) async {
    try {
      await _firestore.collection('spotlight_bookings').doc(bookingId).update({
        'appearanceCount': FieldValue.increment(1),
        'lastShownAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error recording spotlight appearance: $e');
      }
    }
  }

  /// Cancel a spotlight booking (only if not yet active)
  Future<void> cancelBooking(String bookingId) async {
    try {
      final booking = await _firestore
          .collection('spotlight_bookings')
          .doc(bookingId)
          .get();

      if (!booking.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = SpotlightBooking.fromFirestore(booking);
      if (bookingData.status == 'active') {
        throw Exception('Cannot cancel active booking');
      }

      await _firestore.collection('spotlight_bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling booking: $e');
      }
      rethrow;
    }
  }

  /// Helper to get date key for comparison
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

}
