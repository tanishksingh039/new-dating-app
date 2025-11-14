import 'package:cloud_firestore/cloud_firestore.dart';

/// User Analytics Model
class UserAnalytics {
  final int totalUsers;
  final int dailyActiveUsers;
  final int weeklyActiveUsers;
  final int monthlyActiveUsers;
  final int premiumUsers;
  final int verifiedUsers;
  final int flaggedUsers;

  UserAnalytics({
    required this.totalUsers,
    required this.dailyActiveUsers,
    required this.weeklyActiveUsers,
    required this.monthlyActiveUsers,
    required this.premiumUsers,
    required this.verifiedUsers,
    required this.flaggedUsers,
  });
}

/// Spotlight Analytics Model
class SpotlightAnalytics {
  final int totalBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalRevenue;
  final Map<String, int> dailyBookings;
  final Map<String, double> dailyRevenue;

  SpotlightAnalytics({
    required this.totalBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalRevenue,
    required this.dailyBookings,
    required this.dailyRevenue,
  });
}

/// Leaderboard User Model
class LeaderboardUser {
  final String userId;
  final String name;
  final int monthlyScore;
  final int totalScore;
  final String? photoUrl;

  LeaderboardUser({
    required this.userId,
    required this.name,
    required this.monthlyScore,
    required this.totalScore,
    this.photoUrl,
  });
}

/// Rewards Analytics Model
class RewardsAnalytics {
  final int totalUsers;
  final int activeUsers;
  final int totalPointsDistributed;
  final List<LeaderboardUser> topUsers;

  RewardsAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPointsDistributed,
    required this.topUsers,
  });
}

/// Payment Analytics Model
class PaymentAnalytics {
  final int totalTransactions;
  final int successfulTransactions;
  final int failedTransactions;
  final double totalRevenue;
  final Map<String, int> paymentMethods;
  final Map<String, double> dailyRevenue;

  PaymentAnalytics({
    required this.totalTransactions,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.totalRevenue,
    required this.paymentMethods,
    required this.dailyRevenue,
  });
}

/// Storage Analytics Model
class StorageAnalytics {
  final int totalFiles;
  final double totalSizeGB;
  final int userPhotos;
  final int chatImages;
  final double userPhotosSizeGB;
  final double chatImagesSizeGB;

  StorageAnalytics({
    required this.totalFiles,
    required this.totalSizeGB,
    required this.userPhotos,
    required this.chatImages,
    required this.userPhotosSizeGB,
    required this.chatImagesSizeGB,
  });
}

/// User Filter Enum
enum UserFilter {
  premium,
  verified,
  flagged,
  active,
}

/// Admin User Model
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final bool isPremium;
  final bool isVerified;
  final bool isFlagged;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime lastActive;
  final String? profilePhotoUrl;
  final List<String> photos; // Added photos property

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.isPremium,
    required this.isVerified,
    required this.isFlagged,
    required this.isBlocked,
    required this.createdAt,
    required this.lastActive,
    this.profilePhotoUrl,
    this.photos = const [], // Default empty list
  });

  /// Create AdminUser from Firestore document
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle photos array
    List<String> photos = [];
    if (data['photos'] != null && data['photos'] is List) {
      photos = List<String>.from(data['photos']);
    } else if (data['profilePhotoUrl'] != null) {
      photos = [data['profilePhotoUrl']];
    }
    
    return AdminUser(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      isPremium: data['isPremium'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isFlagged: data['isFlagged'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profilePhotoUrl: data['profilePhotoUrl'],
      photos: photos,
    );
  }
}

/// Users List Model for pagination
class UsersList {
  final List<AdminUser> users;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  UsersList({
    required this.users,
    this.lastDocument,
    required this.hasMore,
  });
}

/// User Growth Data for charts
class UserGrowthData {
  final DateTime date;
  final int count;

  UserGrowthData({
    required this.date,
    required this.count,
  });
}
