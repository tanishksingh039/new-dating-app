import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Aggressive caching service to minimize Firestore reads
/// Target: Reduce reads by 90% through intelligent caching
class CacheService {
  static const String _prefix = 'cache_';
  
  // Cache durations (in seconds)
  static const int _profileCacheDuration = 86400; // 24 hours
  static const int _discoveryCacheDuration = 3600; // 1 hour
  static const int _leaderboardCacheDuration = 1800; // 30 minutes
  static const int _statsCacheDuration = 300; // 5 minutes
  
  /// Save user profile to cache
  static Future<void> cacheUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefix}profile_${user.uid}';
      final data = {
        'data': user.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      print('Error caching user profile: $e');
    }
  }
  
  /// Get cached user profile
  static Future<UserModel?> getCachedUserProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefix}profile_$userId';
      final cachedData = prefs.getString(key);
      
      if (cachedData == null) return null;
      
      final data = json.decode(cachedData);
      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid
      if (now - timestamp > _profileCacheDuration * 1000) {
        await prefs.remove(key);
        return null;
      }
      
      return UserModel.fromMap(data['data']);
    } catch (e) {
      print('Error getting cached profile: $e');
      return null;
    }
  }
  
  /// Cache discovery profiles list
  static Future<void> cacheDiscoveryProfiles(List<UserModel> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefix}discovery_profiles';
      final data = {
        'profiles': profiles.map((p) => p.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      print('Error caching discovery profiles: $e');
    }
  }
  
  /// Get cached discovery profiles
  static Future<List<UserModel>?> getCachedDiscoveryProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefix}discovery_profiles';
      final cachedData = prefs.getString(key);
      
      if (cachedData == null) return null;
      
      final data = json.decode(cachedData);
      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid
      if (now - timestamp > _discoveryCacheDuration * 1000) {
        await prefs.remove(key);
        return null;
      }
      
      final profilesList = data['profiles'] as List;
      return profilesList.map((p) => UserModel.fromMap(p)).toList();
    } catch (e) {
      print('Error getting cached discovery profiles: $e');
      return null;
    }
  }
  
  /// Clear discovery profiles cache (useful after filter changes or verification updates)
  static Future<void> clearDiscoveryCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefix}discovery_profiles';
      await prefs.remove(key);
      print('Discovery cache cleared');
    } catch (e) {
      print('Error clearing discovery cache: $e');
    }
  }
  
  /// Cache generic data with custom key and duration
  static Future<void> cacheData(String key, Map<String, dynamic> data, {int? durationSeconds}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_prefix$key';
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'duration': durationSeconds ?? _statsCacheDuration,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      print('Error caching data: $e');
    }
  }
  
  /// Get cached generic data
  static Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_prefix$key';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) return null;
      
      final cache = json.decode(cachedData);
      final timestamp = cache['timestamp'] as int;
      final duration = cache['duration'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid
      if (now - timestamp > duration * 1000) {
        await prefs.remove(cacheKey);
        return null;
      }
      
      return cache['data'] as Map<String, dynamic>;
    } catch (e) {
      print('Error getting cached data: $e');
      return null;
    }
  }
  
  /// Clear specific cache
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
  
  /// Clear all caches
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing all caches: $e');
    }
  }
  
  /// Cache swipe history to avoid repeated queries
  static Future<void> cacheSwipeHistory(String userId, Set<String> swipedUserIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefix}swipe_history_$userId';
      final data = {
        'userIds': swipedUserIds.toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      print('Error caching swipe history: $e');
    }
  }
  
  /// Get cached swipe history
  static Future<Set<String>?> getCachedSwipeHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefix}swipe_history_$userId';
      final cachedData = prefs.getString(key);
      
      if (cachedData == null) return null;
      
      final data = json.decode(cachedData);
      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Cache valid for 1 hour
      if (now - timestamp > 3600 * 1000) {
        await prefs.remove(key);
        return null;
      }
      
      final userIds = (data['userIds'] as List).cast<String>();
      return userIds.toSet();
    } catch (e) {
      print('Error getting cached swipe history: $e');
      return null;
    }
  }
  
  /// Add to swipe history cache (for real-time updates)
  static Future<void> addToSwipeHistoryCache(String userId, String swipedUserId) async {
    try {
      final cached = await getCachedSwipeHistory(userId);
      if (cached != null) {
        cached.add(swipedUserId);
        await cacheSwipeHistory(userId, cached);
      }
    } catch (e) {
      print('Error adding to swipe history cache: $e');
    }
  }
}
