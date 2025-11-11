import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a spotlight booking for a specific date
class SpotlightBooking {
  final String id;
  final String userId;
  final DateTime date;
  final String status; // 'pending', 'active', 'completed', 'cancelled'
  final String paymentId;
  final int amount;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? completedAt;
  final int appearanceCount; // How many times shown so far
  final DateTime? lastShownAt;

  SpotlightBooking({
    required this.id,
    required this.userId,
    required this.date,
    required this.status,
    required this.paymentId,
    required this.amount,
    required this.createdAt,
    this.activatedAt,
    this.completedAt,
    this.appearanceCount = 0,
    this.lastShownAt,
  });

  /// Create from Firestore document
  factory SpotlightBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpotlightBooking(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      paymentId: data['paymentId'] ?? '',
      amount: data['amount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      activatedAt: data['activatedAt'] != null
          ? (data['activatedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      appearanceCount: data['appearanceCount'] ?? 0,
      lastShownAt: data['lastShownAt'] != null
          ? (data['lastShownAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'paymentId': paymentId,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'activatedAt': activatedAt != null ? Timestamp.fromDate(activatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'appearanceCount': appearanceCount,
      'lastShownAt': lastShownAt != null ? Timestamp.fromDate(lastShownAt!) : null,
    };
  }

  /// Check if booking is active for today
  bool get isActiveToday {
    if (status != 'active') return false;
    final now = DateTime.now();
    final bookingDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return bookingDate.isAtSameMomentAs(today);
  }

  /// Copy with updated fields
  SpotlightBooking copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? status,
    String? paymentId,
    int? amount,
    DateTime? createdAt,
    DateTime? activatedAt,
    DateTime? completedAt,
    int? appearanceCount,
    DateTime? lastShownAt,
  }) {
    return SpotlightBooking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      activatedAt: activatedAt ?? this.activatedAt,
      completedAt: completedAt ?? this.completedAt,
      appearanceCount: appearanceCount ?? this.appearanceCount,
      lastShownAt: lastShownAt ?? this.lastShownAt,
    );
  }
}

/// Represents a date's booking status in the calendar
class SpotlightDateStatus {
  final DateTime date;
  final bool isBooked;
  final bool isBookedByCurrentUser;
  final String? bookingId;

  SpotlightDateStatus({
    required this.date,
    required this.isBooked,
    required this.isBookedByCurrentUser,
    this.bookingId,
  });
}
