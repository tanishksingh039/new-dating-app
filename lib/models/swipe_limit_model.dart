import 'package:cloud_firestore/cloud_firestore.dart';

/// Swipe Limit Model - Tracks user's daily swipes
class SwipeLimit {
  final String userId;
  final int totalSwipesAllowed; // Total swipes for the day
  final int swipesUsed; // Swipes already used
  final int swipesRemaining; // Swipes left
  final bool isPremium; // Is user premium?
  final DateTime lastResetDate; // When swipes were last reset
  final DateTime createdAt;

  SwipeLimit({
    required this.userId,
    required this.totalSwipesAllowed,
    required this.swipesUsed,
    required this.isPremium,
    required this.lastResetDate,
    required this.createdAt,
  }) : swipesRemaining = totalSwipesAllowed - swipesUsed;

  /// Check if user can swipe
  bool canSwipe() {
    return swipesRemaining > 0;
  }

  /// Get swipes remaining
  int getSwipesRemaining() {
    return swipesRemaining;
  }

  /// Check if swipes should be reset (new day)
  bool shouldResetSwipes() {
    final now = DateTime.now();
    final lastReset = lastResetDate;
    
    // Reset if it's a new day
    return now.day != lastReset.day ||
        now.month != lastReset.month ||
        now.year != lastReset.year;
  }

  factory SwipeLimit.fromMap(Map<String, dynamic> map) {
    return SwipeLimit(
      userId: map['userId'] ?? '',
      totalSwipesAllowed: map['totalSwipesAllowed'] ?? 0,
      swipesUsed: map['swipesUsed'] ?? 0,
      isPremium: map['isPremium'] ?? false,
      lastResetDate: (map['lastResetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalSwipesAllowed': totalSwipesAllowed,
      'swipesUsed': swipesUsed,
      'swipesRemaining': swipesRemaining,
      'isPremium': isPremium,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() {
    return 'SwipeLimit: $swipesRemaining/$totalSwipesAllowed remaining (Premium: $isPremium)';
  }
}

/// Swipe Limit Configuration
class SwipeLimitConfig {
  // Free user limits
  static const int freeUserDailySwipes = 10;
  static const int freeUserMaxSwipes = 10;

  // Premium user limits
  static const int premiumUserDailySwipes = 999; // Unlimited
  static const int premiumUserMaxSwipes = 999;

  // Bonus swipes for actions
  static const int bonusSwipesPerLike = 1;
  static const int bonusSwipesPerMatch = 2;
  static const int bonusSwipesPerMessage = 1;

  // Reset time (daily)
  static const String resetTime = "00:00"; // Midnight
}
