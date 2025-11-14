import 'dart:math';
import '../models/admin_models.dart';

/// Mock Data Service for Admin Panel
/// Provides realistic mock data with optional real-time data integration
class AdminMockDataService {
  static final Random _random = Random();
  
  // Cache for real-time data integration
  static DateTime _lastUpdate = DateTime.now();
  static Map<String, dynamic> _cachedData = {};
  static bool _useRealTimeData = false; // Toggle for real-time data
  
  /// Enable/disable real-time data fetching
  static void setRealTimeMode(bool enabled) {
    _useRealTimeData = enabled;
  }
  
  /// Get mock user analytics with realistic data
  static Future<UserAnalytics> getUserAnalytics() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate realistic user data
    final totalUsers = 150 + _random.nextInt(50); // 150-200 users
    final dailyActive = (totalUsers * 0.15).round() + _random.nextInt(10); // ~15% daily active
    final weeklyActive = (totalUsers * 0.45).round() + _random.nextInt(15); // ~45% weekly active
    final monthlyActive = (totalUsers * 0.75).round() + _random.nextInt(20); // ~75% monthly active
    final premiumUsers = (totalUsers * 0.12).round() + _random.nextInt(5); // ~12% premium
    final verifiedUsers = (totalUsers * 0.35).round() + _random.nextInt(10); // ~35% verified
    final flaggedUsers = _random.nextInt(5); // 0-5 flagged users
    
    return UserAnalytics(
      totalUsers: totalUsers,
      dailyActiveUsers: dailyActive,
      weeklyActiveUsers: weeklyActive,
      monthlyActiveUsers: monthlyActive,
      premiumUsers: premiumUsers,
      verifiedUsers: verifiedUsers,
      flaggedUsers: flaggedUsers,
    );
  }
  
  /// Get mock spotlight analytics
  static Future<SpotlightAnalytics> getSpotlightAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final totalBookings = 25 + _random.nextInt(15); // 25-40 bookings
    final activeBookings = _random.nextInt(8); // 0-8 active
    final completedBookings = totalBookings - activeBookings - _random.nextInt(3);
    final cancelledBookings = totalBookings - activeBookings - completedBookings;
    final totalRevenue = (totalBookings * 299.0) + (_random.nextDouble() * 1000); // ~₹299 per booking
    
    // Generate daily data for last 7 days
    final dailyBookings = <String, int>{};
    final dailyRevenue = <String, double>{};
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final bookings = _random.nextInt(6); // 0-5 bookings per day
      dailyBookings[dateKey] = bookings;
      dailyRevenue[dateKey] = bookings * 299.0;
    }
    
    return SpotlightAnalytics(
      totalBookings: totalBookings,
      activeBookings: activeBookings,
      completedBookings: completedBookings,
      cancelledBookings: cancelledBookings,
      totalRevenue: totalRevenue,
      dailyBookings: dailyBookings,
      dailyRevenue: dailyRevenue,
    );
  }
  
  /// Get mock rewards analytics
  static Future<RewardsAnalytics> getRewardsAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final totalUsers = 45 + _random.nextInt(15); // 45-60 users in rewards
    final activeUsers = (totalUsers * 0.6).round() + _random.nextInt(5); // ~60% active
    final totalPoints = 15000 + _random.nextInt(5000); // 15k-20k points distributed
    
    // Generate top users leaderboard
    final topUsers = <LeaderboardUser>[
      LeaderboardUser(
        userId: 'user1', 
        name: 'Ajay Kumar', 
        monthlyScore: 850 + _random.nextInt(150), 
        totalScore: 2500 + _random.nextInt(500)
      ),
      LeaderboardUser(
        userId: 'user2', 
        name: 'Priya Sharma', 
        monthlyScore: 720 + _random.nextInt(100), 
        totalScore: 2100 + _random.nextInt(400)
      ),
      LeaderboardUser(
        userId: 'user3', 
        name: 'Rohit Singh', 
        monthlyScore: 650 + _random.nextInt(80), 
        totalScore: 1900 + _random.nextInt(300)
      ),
      LeaderboardUser(
        userId: 'user4', 
        name: 'Anita Patel', 
        monthlyScore: 580 + _random.nextInt(70), 
        totalScore: 1700 + _random.nextInt(250)
      ),
      LeaderboardUser(
        userId: 'user5', 
        name: 'Vikram Gupta', 
        monthlyScore: 520 + _random.nextInt(60), 
        totalScore: 1500 + _random.nextInt(200)
      ),
    ];
    
    return RewardsAnalytics(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      totalPointsDistributed: totalPoints,
      topUsers: topUsers,
    );
  }
  
  /// Get mock payment analytics
  static Future<PaymentAnalytics> getPaymentAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final totalTransactions = 180 + _random.nextInt(50); // 180-230 transactions
    final successfulTransactions = (totalTransactions * 0.85).round(); // 85% success rate
    final failedTransactions = totalTransactions - successfulTransactions;
    final totalRevenue = 45000.0 + (_random.nextDouble() * 15000); // ₹45k-60k
    
    // Payment method distribution
    final paymentMethods = {
      'PREMIUM': (totalTransactions * 0.6).round(), // 60% premium subscriptions
      'SPOTLIGHT': (totalTransactions * 0.35).round(), // 35% spotlight bookings
      'GIFTS': (totalTransactions * 0.05).round(), // 5% gifts
    };
    
    // Generate daily revenue for last 7 days
    final dailyRevenue = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyRevenue[dateKey] = 2000.0 + (_random.nextDouble() * 3000); // ₹2k-5k per day
    }
    
    return PaymentAnalytics(
      totalTransactions: totalTransactions,
      successfulTransactions: successfulTransactions,
      failedTransactions: failedTransactions,
      totalRevenue: totalRevenue,
      paymentMethods: paymentMethods,
      dailyRevenue: dailyRevenue,
    );
  }
  
  /// Get mock storage analytics
  static Future<StorageAnalytics> getStorageAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 350));
    
    final userPhotos = 450 + _random.nextInt(100); // 450-550 user photos
    final chatImages = 280 + _random.nextInt(80); // 280-360 chat images
    final totalFiles = userPhotos + chatImages + _random.nextInt(50); // some other files
    
    final userPhotosSizeGB = (userPhotos * 2.5) / 1000; // ~2.5MB per photo
    final chatImagesSizeGB = (chatImages * 1.8) / 1000; // ~1.8MB per chat image
    final totalSizeGB = userPhotosSizeGB + chatImagesSizeGB + (_random.nextDouble() * 0.5);
    
    return StorageAnalytics(
      totalFiles: totalFiles,
      totalSizeGB: double.parse(totalSizeGB.toStringAsFixed(2)),
      userPhotos: userPhotos,
      chatImages: chatImages,
      userPhotosSizeGB: double.parse(userPhotosSizeGB.toStringAsFixed(2)),
      chatImagesSizeGB: double.parse(chatImagesSizeGB.toStringAsFixed(2)),
    );
  }
  
  /// Get mock users list for user management
  static Future<UsersList> getUsers({
    int limit = 20,
    String? searchQuery,
    UserFilter? filter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate mock users
    final users = _generateMockUsers(limit);
    
    // Apply search filter
    List<AdminUser> filteredUsers = users;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredUsers = users.where((user) =>
        user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
        user.phoneNumber.contains(searchQuery)
      ).toList();
    }
    
    // Apply filter
    if (filter != null) {
      filteredUsers = filteredUsers.where((user) {
        switch (filter) {
          case UserFilter.premium:
            return user.isPremium;
          case UserFilter.verified:
            return user.isVerified;
          case UserFilter.flagged:
            return user.isFlagged;
          case UserFilter.active:
            final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
            return user.lastActive.isAfter(oneDayAgo);
        }
      }).toList();
    }
    
    return UsersList(
      users: filteredUsers,
      lastDocument: null, // Not needed for mock data
      hasMore: false, // For simplicity, return all at once
    );
  }
  
  /// Generate mock users
  static List<AdminUser> _generateMockUsers(int count) {
    final names = [
      'Ajay Kumar', 'Priya Sharma', 'Rohit Singh', 'Anita Patel', 'Vikram Gupta',
      'Sneha Reddy', 'Arjun Mehta', 'Kavya Nair', 'Ravi Agarwal', 'Pooja Jain',
      'Siddharth Rao', 'Meera Shah', 'Karan Malhotra', 'Divya Iyer', 'Nikhil Verma',
      'Shreya Kapoor', 'Aditya Pandey', 'Ritika Sinha', 'Varun Chopra', 'Nisha Goel'
    ];
    
    final domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com'];
    
    return List.generate(count, (index) {
      final name = names[index % names.length];
      final firstName = name.split(' ')[0].toLowerCase();
      final email = '$firstName${100 + index}@${domains[index % domains.length]}';
      final phone = '+91${9000000000 + index}';
      
      return AdminUser(
        id: 'user_${index + 1}',
        name: name,
        email: email,
        phoneNumber: phone,
        isPremium: _random.nextBool() && _random.nextDouble() < 0.15, // 15% premium
        isVerified: _random.nextDouble() < 0.4, // 40% verified
        isFlagged: _random.nextDouble() < 0.05, // 5% flagged
        isBlocked: _random.nextDouble() < 0.02, // 2% blocked
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
        lastActive: DateTime.now().subtract(Duration(hours: _random.nextInt(72))),
        profilePhotoUrl: null, // Can add mock URLs if needed
      );
    });
  }
  
  /// Simulate user management actions
  static Future<void> toggleUserBlock(String userId, bool block) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('Mock: ${block ? 'Blocked' : 'Unblocked'} user $userId');
  }
  
  static Future<void> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('Mock: Deleted user $userId');
  }
}
