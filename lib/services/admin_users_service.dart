import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/firestore_logger.dart';

/// Admin service to fetch and cache all users
/// Bypasses real-time listener permission issues
class AdminUsersService {
  static final AdminUsersService _instance = AdminUsersService._internal();
  factory AdminUsersService() => _instance;
  AdminUsersService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cached users list
  List<UserModel> _cachedUsers = [];
  DateTime? _lastFetchTime;
  bool _isFetching = false;

  // Admin session flag (set when logged in via admin login screen)
  static bool _isAdminLoggedIn = false;
  
  /// Set admin login status (called from admin login screen)
  static void setAdminLoggedIn(bool status) {
    _isAdminLoggedIn = status;
    print('═══════════════════════════════════════');
    print('[AdminUsersService] 🔐 Admin Login Status Set: $status');
    print('═══════════════════════════════════════');
  }
  
  /// Check if current user is admin
  /// Returns true if logged in via admin login screen
  bool isCurrentUserAdmin() {
    print('═══════════════════════════════════════');
    print('[AdminUsersService] 🔐 Checking Admin Status');
    print('[AdminUsersService] ✅ Is Admin: $_isAdminLoggedIn');
    print('═══════════════════════════════════════');
    
    return _isAdminLoggedIn;
  }

  /// Get all users (with caching)
  Future<List<UserModel>> getAllUsers({bool forceRefresh = false}) async {
    print('═══════════════════════════════════════');
    print('[AdminUsersService] 📊 Getting all users');
    print('[AdminUsersService] Force Refresh: $forceRefresh');
    print('[AdminUsersService] Cached Users: ${_cachedUsers.length}');
    print('[AdminUsersService] Is Admin: ${isCurrentUserAdmin()}');

    // Check if user is admin
    if (!isCurrentUserAdmin()) {
      print('[AdminUsersService] ❌ User is not admin');
      print('═══════════════════════════════════════');
      throw Exception('User is not authorized as admin');
    }

    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedUsers.isNotEmpty && _lastFetchTime != null) {
      final cacheAge = DateTime.now().difference(_lastFetchTime!);
      if (cacheAge.inMinutes < 5) {
        print('[AdminUsersService] ✅ Returning cached data (age: ${cacheAge.inSeconds}s)');
        print('═══════════════════════════════════════');
        return _cachedUsers;
      }
    }

    // Prevent multiple simultaneous fetches
    if (_isFetching) {
      print('[AdminUsersService] ⏳ Already fetching, waiting...');
      // Wait for current fetch to complete
      while (_isFetching) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print('[AdminUsersService] ✅ Fetch completed, returning data');
      print('═══════════════════════════════════════');
      return _cachedUsers;
    }

    _isFetching = true;

    try {
      print('[AdminUsersService] 🔄 Fetching users from Firestore...');
      
      // Use simple get() instead of snapshots() to avoid listener issues
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .get();

      print('[AdminUsersService] ✅ Fetched ${snapshot.docs.length} documents');

      // Convert to UserModel list
      final List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data);
          users.add(user);
        } catch (e) {
          print('[AdminUsersService] ⚠️ Error parsing user ${doc.id}: $e');
          // Continue with other users
        }
      }

      // Sort by createdAt (newest first)
      users.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      // Update cache
      _cachedUsers = users;
      _lastFetchTime = DateTime.now();

      print('[AdminUsersService] ✅ Successfully cached ${users.length} users');
      print('═══════════════════════════════════════');

      FirestoreLogger.logSuccess(
        operation: 'Fetch all users',
        collection: 'users',
        count: users.length,
      );

      return users;
    } catch (e, stackTrace) {
      print('[AdminUsersService] ❌ Error fetching users: $e');
      print('═══════════════════════════════════════');

      FirestoreLogger.logFirestoreError(
        error: e,
        operation: 'Fetch all users',
        collection: 'users',
        stackTrace: stackTrace,
      );

      // Return cached data if available, even if stale
      if (_cachedUsers.isNotEmpty) {
        print('[AdminUsersService] ⚠️ Returning stale cached data');
        return _cachedUsers;
      }

      rethrow;
    } finally {
      _isFetching = false;
    }
  }

  /// Search users by name or phone
  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _cachedUsers;

    final lowerQuery = query.toLowerCase();
    return _cachedUsers.where((user) {
      final name = user.name.toLowerCase();
      final phone = user.phoneNumber?.toLowerCase() ?? '';
      return name.contains(lowerQuery) || phone.contains(lowerQuery);
    }).toList();
  }

  /// Filter users by category
  List<UserModel> filterUsers(String category) {
    switch (category) {
      case 'Premium':
        return _cachedUsers.where((user) => user.isPremium == true).toList();
      case 'Verified':
        return _cachedUsers.where((user) => user.isVerified == true).toList();
      case 'Flagged':
        // For now, return empty list for flagged users
        // You can add isFlagged and reportCount fields to UserModel later
        return [];
      default:
        return _cachedUsers;
    }
  }

  /// Clear cache
  void clearCache() {
    print('[AdminUsersService] 🗑️ Clearing cache');
    _cachedUsers.clear();
    _lastFetchTime = null;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    return {
      'cachedCount': _cachedUsers.length,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'cacheAge': _lastFetchTime != null
          ? DateTime.now().difference(_lastFetchTime!).inSeconds
          : null,
      'isFetching': _isFetching,
    };
  }
}
