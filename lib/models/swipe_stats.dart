import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking user's swipe statistics
class SwipeStats {
  final String userId;
  final int totalSwipes;
  final int freeSwipesUsed;
  final int purchasedSwipesRemaining;
  final DateTime lastResetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  SwipeStats({
    required this.userId,
    required this.totalSwipes,
    required this.freeSwipesUsed,
    required this.purchasedSwipesRemaining,
    required this.lastResetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory SwipeStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwipeStats(
      userId: doc.id,
      totalSwipes: data['totalSwipes'] ?? 0,
      freeSwipesUsed: data['freeSwipesUsed'] ?? 0,
      purchasedSwipesRemaining: data['purchasedSwipesRemaining'] ?? 0,
      lastResetDate: (data['lastResetDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'totalSwipes': totalSwipes,
      'freeSwipesUsed': freeSwipesUsed,
      'purchasedSwipesRemaining': purchasedSwipesRemaining,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if user has swipes available
  bool hasSwipesAvailable(int freeSwipesLimit) {
    // Check if free swipes are available
    if (freeSwipesUsed < freeSwipesLimit) {
      return true;
    }
    // Check if purchased swipes are available
    return purchasedSwipesRemaining > 0;
  }

  /// Get remaining free swipes
  int getRemainingFreeSwipes(int freeSwipesLimit) {
    return (freeSwipesLimit - freeSwipesUsed).clamp(0, freeSwipesLimit);
  }

  /// Get total remaining swipes
  int getTotalRemainingSwipes(int freeSwipesLimit) {
    return getRemainingFreeSwipes(freeSwipesLimit) + purchasedSwipesRemaining;
  }

  /// Check if daily reset is needed
  bool needsDailyReset() {
    final now = DateTime.now();
    final lastReset = DateTime(
      lastResetDate.year,
      lastResetDate.month,
      lastResetDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(lastReset);
  }

  /// Create a copy with updated values
  SwipeStats copyWith({
    int? totalSwipes,
    int? freeSwipesUsed,
    int? purchasedSwipesRemaining,
    DateTime? lastResetDate,
    DateTime? updatedAt,
  }) {
    return SwipeStats(
      userId: userId,
      totalSwipes: totalSwipes ?? this.totalSwipes,
      freeSwipesUsed: freeSwipesUsed ?? this.freeSwipesUsed,
      purchasedSwipesRemaining: purchasedSwipesRemaining ?? this.purchasedSwipesRemaining,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
