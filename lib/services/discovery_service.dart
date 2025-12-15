import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/discovery_filters.dart';
import '../utils/firestore_extensions.dart';
import 'user_safety_service.dart';
import 'notification_service.dart';
import '../firebase_services.dart';
import 'cache_service.dart';

class DiscoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Get discovery profiles based on user preferences
  /// OPTIMIZED: Uses aggressive caching to reduce Firestore reads by 90%
  Future<List<UserModel>> getDiscoveryProfiles(
    String currentUserId, {
    DiscoveryFilters? filters,
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedProfiles = await CacheService.getCachedDiscoveryProfiles();
        if (cachedProfiles != null && cachedProfiles.isNotEmpty) {
          debugPrint('💰 [COST SAVE] Using cached discovery profiles: ${cachedProfiles.length} profiles');
          return cachedProfiles;
        }
      }
      
      debugPrint('📡 [FIRESTORE READ] Fetching fresh discovery profiles...');
      
      // Get current user's data and preferences
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) {
        debugPrint('Current user document does not exist');
        return [];
      }

      final currentUser = UserModel.fromMap(currentUserDoc.data()!);
      final prefs = currentUser.preferences;
      final currentUserGender = currentUser.gender.trim().toLowerCase();

      debugPrint('🔍 Current user gender: "$currentUserGender" (raw: "${currentUser.gender}")');
      debugPrint('🔍 Filters applied: ${filters?.toMap()}');
      debugPrint('🔍 Has active filters: ${filters?.hasActiveFilters}');

      // Get user's swipe history to exclude already swiped profiles
      final swipeHistory = await _getSwipeHistory(currentUserId);
      
      // Build query - no gender filter in query (will filter in code for case-insensitive matching)
      Query query = _firestore.collection('users');

      // Get potential matches
      debugPrint('Fetching users from Firestore...');
      final snapshot = await query.limit(200).get();
      debugPrint('Found ${snapshot.docs.length} potential users');

      // Convert to UserModel and apply additional filters
      List<UserModel> profiles = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.safeData();
          if (data == null) {
            debugPrint('Skipping document ${doc.id}: null or invalid data');
            continue;
          }
          final user = UserModel.fromMap(data);

          // Skip current user
          if (user.uid == currentUserId) {
            debugPrint('Skipping user ${user.uid}: current user');
            continue;
          }

          // AUTOMATIC FILTER: Show opposite gender only (case-insensitive)
          final userGender = user.gender.trim().toLowerCase();
          if (currentUserGender == 'male' && userGender != 'female') {
            debugPrint('Skipping user ${user.uid}: gender mismatch (male user needs female)');
            continue;
          } else if (currentUserGender == 'female' && userGender != 'male') {
            debugPrint('Skipping user ${user.uid}: gender mismatch (female user needs male)');
            continue;
          }
          debugPrint('✅ Gender match: $currentUserGender ↔ $userGender');
          
          // VERIFICATION FILTER: Males see only verified females, females see only verified males
          final isUserVerified = data['isVerified'] ?? false;
          if (currentUserGender == 'male' && userGender == 'female' && !isUserVerified) {
            debugPrint('Skipping user ${user.uid}: female not verified (male users see verified females only)');
            continue;
          } else if (currentUserGender == 'female' && userGender == 'male' && !isUserVerified) {
            debugPrint('Skipping user ${user.uid}: male not verified (female users see verified males only)');
            continue;
          }
          debugPrint('✅ Verification check passed: isVerified=$isUserVerified');

          // Skip if already swiped
          if (swipeHistory.contains(user.uid)) {
            debugPrint('Skipping user ${user.uid}: already swiped');
            continue;
          }

          // Skip if no date of birth
          if (user.dateOfBirth == null) {
            debugPrint('Skipping user ${user.uid}: no date of birth');
            continue;
          }

          // Filter by age range ONLY if filters are explicitly provided and have active filters
          if (filters != null && filters.hasActiveFilters) {
            final userAge = _calculateAge(user.dateOfBirth!);
            if (userAge < filters.minAge || userAge > filters.maxAge) {
              debugPrint('Skipping user ${user.uid}: age $userAge not in range ${filters.minAge}-${filters.maxAge}');
              continue;
            }
          }

          // Filter by course/stream - STRICT matching
          if (filters?.courseStream != null) {
            final userCourseStream = data['courseStream'] as String?;
            debugPrint('Course filter: user=$userCourseStream, filter=${filters!.courseStream}');
            
            // Skip if user doesn't have courseStream OR it doesn't match
            if (userCourseStream == null || userCourseStream != filters!.courseStream) {
              debugPrint('Skipping user ${user.uid}: course/stream mismatch ($userCourseStream != ${filters!.courseStream})');
              continue;
            }
            
            debugPrint('✅ Course/Stream match: $userCourseStream');
          }

          // Filter by interests - user must have at least one matching interest
          if (filters != null && filters.interests.isNotEmpty) {
            final hasMatchingInterest = filters.interests.any(
              (interest) => user.interests.contains(interest),
            );
            if (!hasMatchingInterest) {
              debugPrint('Skipping user ${user.uid}: no matching interests from filter');
              continue;
            }
            debugPrint('✅ Interest filter match: user has matching interests');
          }

          // TODO: Distance filtering would require location data
          // This would need geolocation implementation
          if (filters?.maxDistance != null) {
            // For now, we'll skip distance filtering
            // In production, you'd use GeoFlutterFire or similar
            debugPrint('Distance filtering not yet implemented');
          }

          // Show all profiles regardless of photos
          profiles.add(user);
        } catch (e) {
          debugPrint('Error processing user document ${doc.id}: $e');
          continue;
        }
      }

      debugPrint('Filtered down to ${profiles.length} valid profiles');

      // Filter out blocked users
      final filteredProfiles = await UserSafetyService.filterBlockedUsers(
        currentUserId: currentUserId,
        users: profiles,
      );

      debugPrint('After blocking filter: ${filteredProfiles.length} profiles');

      // Sort by interest matching - profiles with matching interests first
      if (currentUser.interests.isNotEmpty) {
        filteredProfiles.sort((a, b) {
          // Count matching interests for each profile
          final aMatches = a.interests.where((interest) => currentUser.interests.contains(interest)).length;
          final bMatches = b.interests.where((interest) => currentUser.interests.contains(interest)).length;
          
          // Sort descending (more matches first)
          return bMatches.compareTo(aMatches);
        });
        debugPrint('✅ Sorted by interest matching - current user has ${currentUser.interests.length} interests');
      } else {
        // No interests to match, just shuffle
        filteredProfiles.shuffle();
      }
      
      // Cache the results for 1 hour to reduce future reads
      await CacheService.cacheDiscoveryProfiles(filteredProfiles);
      debugPrint('💾 Cached ${filteredProfiles.length} discovery profiles');
      
      // Log interest matching stats
      if (currentUser.interests.isNotEmpty && filteredProfiles.isNotEmpty) {
        final topProfile = filteredProfiles.first;
        final matchCount = topProfile.interests.where((i) => currentUser.interests.contains(i)).length;
        debugPrint('📊 Top profile has $matchCount matching interests');
      }

      return filteredProfiles;
    } catch (e) {
      debugPrint('Error getting discovery profiles: $e');
      return [];
    }
  }

  /// Get user's swipe history from both centralized and subcollection structures
  /// OPTIMIZED: Uses caching to avoid repeated queries
  Future<Set<String>> _getSwipeHistory(String userId) async {
    // Try cache first
    final cachedHistory = await CacheService.getCachedSwipeHistory(userId);
    if (cachedHistory != null) {
      debugPrint('💰 [COST SAVE] Using cached swipe history: ${cachedHistory.length} swipes');
      return cachedHistory;
    }
    
    debugPrint('📡 [FIRESTORE READ] Fetching swipe history...');
    final swipedUserIds = <String>{};
    
    try {
      // Method 1: Get from centralized swipes collection (your current structure)
      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .get();

      swipedUserIds.addAll(
        swipesSnapshot.docs.map((doc) => doc['targetUserId'] as String)
      );

      // Method 2: Get from subcollections (for likes feature compatibility)
      try {
        // Get likes
        final likesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('likes')
            .get();
        swipedUserIds.addAll(likesSnapshot.docs.map((doc) => doc.id));

        // Get passes
        final passesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('passes')
            .get();
        swipedUserIds.addAll(passesSnapshot.docs.map((doc) => doc.id));

        // Get super likes
        final superLikesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('superLikes')
            .get();
        swipedUserIds.addAll(superLikesSnapshot.docs.map((doc) => doc.id));
      } catch (e) {
        debugPrint('Note: Subcollections not found (normal for older data): $e');
      }

      debugPrint('Total swiped users: ${swipedUserIds.length}');
      
      // Cache for future use
      await CacheService.cacheSwipeHistory(userId, swipedUserIds);
      debugPrint('💾 Cached swipe history');
      
      return swipedUserIds;
    } catch (e) {
      debugPrint('Error getting swipe history: $e');
      return {};
    }
  }

  /// Record a swipe action (supports both centralized and subcollection structures)
  /// OPTIMIZED: Updates cache to avoid re-fetching swipe history
  Future<void> recordSwipe(
    String userId,
    String targetUserId,
    String action, // 'like', 'pass', or 'superlike'
  ) async {
    try {
      // Update cache immediately for instant UI updates
      await CacheService.addToSwipeHistoryCache(userId, targetUserId);
      
      final timestamp = FieldValue.serverTimestamp();

      // Method 1: Record in centralized swipes collection (your current structure)
      await _firestore.collection('swipes').add({
        'userId': userId,
        'targetUserId': targetUserId,
        'action': action,
        'timestamp': timestamp,
      });

      // Method 2: Record in subcollections (for likes feature)
      switch (action.toLowerCase()) {
        case 'like':
          // Use FirebaseServices for bidirectional like recording
          await FirebaseServices.recordLike(
            currentUserId: userId,
            likedUserId: targetUserId,
          );
          
          // Send like notification
          await _sendLikeNotification(userId, targetUserId);
          break;

        case 'superlike':
          // Record super like in both user's collections
          final batch = _firestore.batch();
          
          // Add to sender's superLikes
          final superLikeRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('superLikes')
              .doc(targetUserId);
          
          batch.set(superLikeRef, {
            'userId': targetUserId,
            'timestamp': timestamp,
          });

          // Add to receiver's receivedSuperLikes
          final receivedSuperLikeRef = _firestore
              .collection('users')
              .doc(targetUserId)
              .collection('receivedSuperLikes')
              .doc(userId);
          
          batch.set(receivedSuperLikeRef, {
            'userId': userId,
            'timestamp': timestamp,
          });

          await batch.commit();
          debugPrint('Super like recorded: $userId -> $targetUserId');
          break;

        case 'pass':
          // Record pass in subcollection
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('passes')
              .doc(targetUserId)
              .set({
            'userId': targetUserId,
            'timestamp': timestamp,
          });
          debugPrint('Pass recorded: $userId -> $targetUserId');
          break;

        default:
          debugPrint('Unknown action: $action');
      }

      // Update user's daily swipe count (for free tier limits)
      await _updateDailySwipeCount(userId);
      
      debugPrint('Swipe recorded successfully: $action on $targetUserId');
    } catch (e) {
      debugPrint('Error recording swipe: $e');
      rethrow;
    }
  }

  /// Update daily swipe count for rate limiting
  Future<void> _updateDailySwipeCount(String userId) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore.collection('users').doc(userId).update({
        'dailySwipes.$dateKey': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error updating daily swipe count: $e');
    }
  }

  /// Check if user has reached daily swipe limit (for free users)
  Future<bool> hasReachedDailyLimit(String userId, {int limit = 100}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data();

      // Premium users have unlimited swipes
      if (userData?['isPremium'] == true) return false;

      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final dailySwipes = userData?['dailySwipes'] as Map<String, dynamic>?;

      if (dailySwipes == null) return false;

      final rawCount = dailySwipes[dateKey];
      int todayCount;
      if (rawCount is int) {
        todayCount = rawCount;
      } else if (rawCount is double) {
        todayCount = rawCount.toInt();
      } else if (rawCount is String) {
        todayCount = int.tryParse(rawCount) ?? 0;
      } else {
        todayCount = 0;
      }
      return todayCount >= limit; // Default: 100 swipes per day for free users
    } catch (e) {
      debugPrint('Error checking daily limit: $e');
      return false;
    }
  }

  /// Get remaining swipes for today
  Future<int> getRemainingSwipes(String userId, {int limit = 100}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return limit;
      
      final userData = userDoc.data();

      // Premium users have unlimited swipes
      if (userData?['isPremium'] == true) return 999;

      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final dailySwipes = userData?['dailySwipes'] as Map<String, dynamic>?;

      if (dailySwipes == null) return limit;

      final rawCount = dailySwipes[dateKey];
      int todayCount;
      if (rawCount is int) {
        todayCount = rawCount;
      } else if (rawCount is double) {
        todayCount = rawCount.toInt();
      } else if (rawCount is String) {
        todayCount = int.tryParse(rawCount) ?? 0;
      } else {
        todayCount = 0;
      }

      final remaining = limit - todayCount;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      debugPrint('Error getting remaining swipes: $e');
      return 0;
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

  /// Get recommended profiles (featured/daily picks)
  Future<List<UserModel>> getRecommendedProfiles(String currentUserId) async {
    try {
      // Get profiles with high compatibility scores
      // This is a simplified version - can be enhanced with ML algorithms
      final profiles = await getDiscoveryProfiles(currentUserId);
      
      // Return top 10 profiles
      return profiles.take(10).toList();
    } catch (e) {
      debugPrint('Error getting recommended profiles: $e');
      return [];
    }
  }

  /// Undo last swipe (premium feature)
  Future<UserModel?> undoLastSwipe(String currentUserId) async {
    try {
      // Get the most recent swipe from centralized collection
      final swipeSnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (swipeSnapshot.docs.isEmpty) {
        debugPrint('No swipes to undo');
        return null;
      }

      final lastSwipe = swipeSnapshot.docs.first;
      final targetUserId = lastSwipe['targetUserId'] as String;
      final action = lastSwipe['action'] as String;

      // Delete the centralized swipe record
      await lastSwipe.reference.delete();

      // Delete from subcollections based on action type
      switch (action.toLowerCase()) {
        case 'like':
          await FirebaseServices.removeLike(
            currentUserId: currentUserId,
            likedUserId: targetUserId,
          );
          break;

        case 'superlike':
          final batch = _firestore.batch();
          
          batch.delete(_firestore
              .collection('users')
              .doc(currentUserId)
              .collection('superLikes')
              .doc(targetUserId));
          
          batch.delete(_firestore
              .collection('users')
              .doc(targetUserId)
              .collection('receivedSuperLikes')
              .doc(currentUserId));
          
          await batch.commit();
          break;

        case 'pass':
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('passes')
              .doc(targetUserId)
              .delete();
          break;
      }

      // Decrement daily swipe count
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore.collection('users').doc(currentUserId).update({
        'dailySwipes.$dateKey': FieldValue.increment(-1),
      });

      // Get and return the user that was un-swiped
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (userDoc.exists) {
        debugPrint('Undo successful for user: $targetUserId');
        return UserModel.fromMap(userDoc.data()!);
      }

      return null;
    } catch (e) {
      debugPrint('Error undoing swipe: $e');
      rethrow;
    }
  }

  /// Get user's swipe statistics
  Future<Map<String, int>> getSwipeStats(String userId) async {
    try {
      final stats = <String, int>{};

      // Count from centralized swipes collection
      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .get();

      int likesCount = 0;
      int passesCount = 0;
      int superLikesCount = 0;

      for (var doc in swipesSnapshot.docs) {
        final action = doc['action'] as String;
        switch (action.toLowerCase()) {
          case 'like':
            likesCount++;
            break;
          case 'pass':
            passesCount++;
            break;
          case 'superlike':
            superLikesCount++;
            break;
        }
      }

      stats['likes'] = likesCount;
      stats['passes'] = passesCount;
      stats['superLikes'] = superLikesCount;

      // Get received likes count
      try {
        final receivedLikesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('receivedLikes')
            .get();
        stats['receivedLikes'] = receivedLikesSnapshot.docs.length;
      } catch (e) {
        stats['receivedLikes'] = 0;
      }

      // Get matches count
      try {
        final matchesSnapshot = await _firestore
            .collection('matches')
            .where('users', arrayContains: userId)
            .get();
        stats['matches'] = matchesSnapshot.docs.length;
      } catch (e) {
        stats['matches'] = 0;
      }

      debugPrint('Swipe stats for $userId: $stats');
      return stats;
    } catch (e) {
      debugPrint('Error getting swipe stats: $e');
      return {};
    }
  }

  /// Check if a specific action was performed on a user
  Future<bool> hasSwipedOn(
    String userId,
    String targetUserId,
    String action,
  ) async {
    try {
      // Check centralized collection
      final swipeQuery = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .where('targetUserId', isEqualTo: targetUserId)
          .where('action', isEqualTo: action)
          .limit(1)
          .get();

      if (swipeQuery.docs.isNotEmpty) return true;

      // Check subcollections as fallback
      String collectionName;
      switch (action.toLowerCase()) {
        case 'like':
          collectionName = 'likes';
          break;
        case 'pass':
          collectionName = 'passes';
          break;
        case 'superlike':
          collectionName = 'superLikes';
          break;
        default:
          return false;
      }

      final subCollectionDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(targetUserId)
          .get();

      return subCollectionDoc.exists;
    } catch (e) {
      debugPrint('Error checking swipe: $e');
      return false;
    }
  }

  /// Send like notification to target user
  Future<void> _sendLikeNotification(String likerId, String targetUserId) async {
    try {
      // Get liker's name
      final likerDoc = await _firestore.collection('users').doc(likerId).get();
      final likerName = likerDoc.data()?['name'] ?? 'Someone';

      // Send notification
      await _notificationService.sendLikeNotification(
        targetUserId: targetUserId,
        likerName: likerName,
      );

      debugPrint('✅ Like notification sent to $targetUserId');
    } catch (e) {
      debugPrint('❌ Error sending like notification: $e');
    }
  }
}