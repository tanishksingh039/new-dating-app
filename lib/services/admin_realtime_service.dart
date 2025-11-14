import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_models.dart';

/// Real-Time Admin Data Service
/// Provides live data from Firestore with streaming updates
class AdminRealTimeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for real-time updates
  static final StreamController<UserAnalytics> _userAnalyticsController = 
      StreamController<UserAnalytics>.broadcast();
  static final StreamController<List<AdminUser>> _usersController = 
      StreamController<List<AdminUser>>.broadcast();
  
  /// Stream of real-time user analytics
  static Stream<UserAnalytics> get userAnalyticsStream => _userAnalyticsController.stream;
  
  /// Stream of real-time users list
  static Stream<List<AdminUser>> get usersStream => _usersController.stream;
  
  /// Start real-time monitoring
  static void startRealTimeMonitoring() {
    // Monitor users collection for changes
    _firestore.collection('users').snapshots().listen((snapshot) {
      _updateUserAnalytics(snapshot);
      _updateUsersList(snapshot);
    });
    
    // Monitor other collections as needed
    _monitorPaymentTransactions();
    _monitorSpotlightBookings();
  }
  
  /// Update user analytics from snapshot
  static void _updateUserAnalytics(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    int totalUsers = snapshot.docs.length;
    int dailyActive = 0;
    int weeklyActive = 0;
    int monthlyActive = 0;
    int premiumUsers = 0;
    int verifiedUsers = 0;
    int flaggedUsers = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Count premium users
      if (data['isPremium'] == true) premiumUsers++;
      
      // Count verified users
      if (data['isVerified'] == true) verifiedUsers++;
      
      // Count flagged users
      if (data['isFlagged'] == true) flaggedUsers++;
      
      // Count active users
      final lastActive = data['lastActive'] as Timestamp?;
      if (lastActive != null) {
        final lastActiveDate = lastActive.toDate();
        
        if (lastActiveDate.isAfter(oneDayAgo)) dailyActive++;
        if (lastActiveDate.isAfter(sevenDaysAgo)) weeklyActive++;
        if (lastActiveDate.isAfter(thirtyDaysAgo)) monthlyActive++;
      }
    }
    
    final analytics = UserAnalytics(
      totalUsers: totalUsers,
      dailyActiveUsers: dailyActive,
      weeklyActiveUsers: weeklyActive,
      monthlyActiveUsers: monthlyActive,
      premiumUsers: premiumUsers,
      verifiedUsers: verifiedUsers,
      flaggedUsers: flaggedUsers,
    );
    
    _userAnalyticsController.add(analytics);
  }
  
  /// Update users list from snapshot
  static void _updateUsersList(QuerySnapshot snapshot) {
    final users = snapshot.docs
        .map((doc) => AdminUser.fromFirestore(doc))
        .toList();
    
    _usersController.add(users);
  }
  
  /// Monitor payment transactions
  static void _monitorPaymentTransactions() {
    _firestore.collection('payment_transactions').snapshots().listen((snapshot) {
      // Update payment analytics in real-time
      print('Payment transactions updated: ${snapshot.docs.length} transactions');
    });
  }
  
  /// Monitor spotlight bookings
  static void _monitorSpotlightBookings() {
    _firestore.collection('spotlight_bookings').snapshots().listen((snapshot) {
      // Update spotlight analytics in real-time
      print('Spotlight bookings updated: ${snapshot.docs.length} bookings');
    });
  }
  
  /// Get real-time user count
  static Future<int> getRealTimeUserCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }
  
  /// Get real-time active users (last 24 hours)
  static Future<int> getRealTimeActiveUsers() async {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    final snapshot = await _firestore
        .collection('users')
        .where('lastActive', isGreaterThan: Timestamp.fromDate(oneDayAgo))
        .get();
    return snapshot.docs.length;
  }
  
  /// Get real-time premium users
  static Future<int> getRealTimePremiumUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('isPremium', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }
  
  /// Stop real-time monitoring
  static void stopRealTimeMonitoring() {
    _userAnalyticsController.close();
    _usersController.close();
  }
}
