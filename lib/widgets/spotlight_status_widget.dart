import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spotlight_booking.dart';
import '../screens/spotlight/spotlight_booking_screen.dart';

/// Widget to display user's spotlight booking status
class SpotlightStatusWidget extends StatelessWidget {
  const SpotlightStatusWidget({Key? key}) : super(key: key);

  Future<List<SpotlightBooking>> _getActiveBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get active and pending bookings
      final snapshot = await FirebaseFirestore.instance
          .collection('spotlight_bookings')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'active']).get();

      final bookings = snapshot.docs
          .map((doc) => SpotlightBooking.fromFirestore(doc))
          .where((booking) {
            final bookingDate = DateTime(
              booking.date.year,
              booking.date.month,
              booking.date.day,
            );
            return bookingDate.isAfter(today) || bookingDate.isAtSameMomentAs(today);
          })
          .toList();
      
      // Sort by date
      bookings.sort((a, b) => a.date.compareTo(b.date));
      
      // Limit to 5 bookings
      return bookings.take(5).toList();
    } catch (e) {
      print('Error loading spotlight bookings: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SpotlightBooking>>(
      future: _getActiveBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA500).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spotlight Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your profile is featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SpotlightBookingScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white, thickness: 0.5),
              const SizedBox(height: 8),
              ...bookings.map((booking) => _buildBookingItem(booking)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingItem(SpotlightBooking booking) {
    final dateStr = '${booking.date.day}/${booking.date.month}/${booking.date.year}';
    final isToday = _isToday(booking.date);
    final statusText = booking.status == 'active' ? 'Active Now' : 'Scheduled';
    final statusColor = booking.status == 'active' ? Colors.greenAccent : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (booking.status == 'active')
            Expanded(
              child: Text(
                '  ${booking.appearanceCount}/10 shown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
