import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DiscoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get discovery profiles based on user preferences
  Future<List<UserModel>> getDiscoveryProfiles(String currentUserId) async {
    try {
      // Get current user's data and preferences
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) return [];

      final currentUser = UserModel.fromMap(currentUserDoc.data()!);
      final prefs = currentUser.preferences;

      // Get user's swipe history to exclude already swiped profiles
      final swipeHistory = await _getSwipeHistory(currentUserId);
      
      // Build query based on preferences
    // Only include users who completed onboarding. Historically the
    // codebase used both 'isOnboardingComplete' and 'onboardingCompleted'
    // field names; onboarding writes (PreferencesScreen) set
    // 'onboardingCompleted'. Use that canonical field so the query
    // returns expected documents.
    Query query = _firestore
      .collection('users')
      .where('onboardingCompleted', isEqualTo: true)
      .where('uid', isNotEqualTo: currentUserId);

      // Filter by interested in gender
      if (prefs['interestedIn'] != null && prefs['interestedIn'] != 'Everyone') {
        query = query.where('gender', isEqualTo: prefs['interestedIn']);
      }

      // Get potential matches
      final snapshot = await query.limit(50).get();

      // Convert to UserModel and apply additional filters
      List<UserModel> profiles = [];
      for (var doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);

        // Skip if already swiped
        if (swipeHistory.contains(user.uid)) continue;

        // Filter by age range
        if (prefs['ageRange'] != null) {
          final ageRange = prefs['ageRange'] as Map<String, dynamic>;
          final minAge = ageRange['min'] ?? 18;
          final maxAge = ageRange['max'] ?? 100;
          final userAge = _calculateAge(user.dateOfBirth!);

          if (userAge < minAge || userAge > maxAge) continue;
        }

        // TODO: Filter by distance when location is implemented
        // if (prefs['maxDistance'] != null) {
        //   final distance = _calculateDistance(currentUser, user);
        //   if (distance > prefs['maxDistance']) continue;
        // }

        profiles.add(user);
      }

      // Shuffle for variety
      profiles.shuffle();

      return profiles;
    } catch (e) {
      print('Error getting discovery profiles: $e');
      return [];
    }
  }

  /// Get user's swipe history
  Future<Set<String>> _getSwipeHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => doc['targetUserId'] as String).toSet();
    } catch (e) {
      print('Error getting swipe history: $e');
      return {};
    }
  }

  /// Record a swipe action
  Future<void> recordSwipe(
    String userId,
    String targetUserId,
    String action, // 'like', 'pass', or 'superlike'
  ) async {
    try {
      await _firestore.collection('swipes').add({
        'userId': userId,
        'targetUserId': targetUserId,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user's daily swipe count (for free tier limits)
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';

      await _firestore.collection('users').doc(userId).update({
        'dailySwipes.$dateKey': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error recording swipe: $e');
      throw e;
    }
  }

  /// Check if user has reached daily swipe limit (for free users)
  Future<bool> hasReachedDailyLimit(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      // Premium users have unlimited swipes
      if (userData?['isPremium'] == true) return false;

      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final dailySwipes = userData?['dailySwipes'] as Map<String, dynamic>?;

      if (dailySwipes == null) return false;

      final todayCount = dailySwipes[dateKey] ?? 0;
      return todayCount >= 100; // Free users get 100 swipes per day
    } catch (e) {
      print('Error checking daily limit: $e');
      return false;
    }
  }

  /// Calculate age from date of birth
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // TODO: Implement distance calculation using geolocation
  // double _calculateDistance(UserModel user1, UserModel user2) {
  //   // Use geolocation package to calculate distance
  //   return 0.0;
  // }

  /// Get recommended profiles (featured/daily picks)
  Future<List<UserModel>> getRecommendedProfiles(String currentUserId) async {
    try {
      // Get profiles with high compatibility scores
      // This is a simplified version - can be enhanced with ML algorithms
      final profiles = await getDiscoveryProfiles(currentUserId);
      
      // Return top 10 profiles
      return profiles.take(10).toList();
    } catch (e) {
      print('Error getting recommended profiles: $e');
      return [];
    }
  }
}