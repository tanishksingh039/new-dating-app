import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Real-time presence service to track user online/offline status
/// Updates lastActive timestamp automatically while app is active
/// Provides real-time online status for all users
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _presenceTimer;
  bool _isTracking = false;
  String? _currentUserId;

  /// Start tracking user presence (call when app becomes active)
  /// Updates lastActive every 30 seconds while app is in foreground
  Future<void> startPresenceTracking() async {
    if (_isTracking) {
      debugPrint('⚠️ [Presence] Already tracking presence');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ [Presence] No authenticated user, cannot track presence');
      return;
    }

    _currentUserId = user.uid;
    _isTracking = true;

    debugPrint('✅ [Presence] Starting presence tracking for user: ${user.uid}');

    // Update immediately
    await _updatePresence();

    // Update every 30 seconds while app is active
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updatePresence();
    });

    debugPrint('📡 [Presence] Presence tracking started - updating every 30 seconds');
  }

  /// Stop tracking user presence (call when app goes to background or user logs out)
  Future<void> stopPresenceTracking() async {
    if (!_isTracking) return;

    debugPrint('🛑 [Presence] Stopping presence tracking');

    _presenceTimer?.cancel();
    _presenceTimer = null;
    _isTracking = false;

    // Final update before stopping
    await _updatePresence();

    debugPrint('✅ [Presence] Presence tracking stopped');
  }

  /// Update user's lastActive timestamp in Firestore
  Future<void> _updatePresence() async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      debugPrint('💚 [Presence] Updated lastActive for user: $_currentUserId');
    } catch (e) {
      debugPrint('❌ [Presence] Error updating presence: $e');
    }
  }

  /// Manually update presence (call on important user actions)
  Future<void> updatePresenceNow() async {
    await _updatePresence();
  }

  /// Check if a user is currently online (active within last 5 minutes)
  static bool isUserOnline(DateTime? lastActive) {
    if (lastActive == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    return difference.inMinutes < 5;
  }

  /// Get formatted last seen text
  static String getLastSeenText(DateTime? lastActive) {
    if (lastActive == null) return 'Last seen: Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen long ago';
    }
  }

  /// Get real-time stream of user's online status
  /// Returns a stream that emits true when user is online, false when offline
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          
          final data = snapshot.data();
          final lastActive = (data?['lastActive'] as Timestamp?)?.toDate();
          
          return isUserOnline(lastActive);
        });
  }

  /// Get real-time stream of user's last active time
  Stream<DateTime?> getUserLastActiveStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          
          final data = snapshot.data();
          return (data?['lastActive'] as Timestamp?)?.toDate();
        });
  }

  /// Check if user allows showing online status (privacy setting)
  static Future<bool> canShowOnlineStatus(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!doc.exists) return true;
      
      final data = doc.data();
      final privacy = data?['privacySettings'] as Map<String, dynamic>?;
      return privacy?['showOnlineStatus'] ?? true;
    } catch (e) {
      debugPrint('Error checking online status privacy: $e');
      return true; // Default to showing
    }
  }

  /// Dispose the service (cleanup)
  void dispose() {
    stopPresenceTracking();
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;
}
