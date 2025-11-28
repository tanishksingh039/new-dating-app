import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send notification to all users of a specific gender
  Future<Map<String, dynamic>> sendNotificationByGender({
    required String gender, // 'male', 'female', or 'all'
    required String title,
    required String body,
    required String notificationType, // 'promotional', 'reward', 'match', 'system'
    Map<String, String>? data,
    bool bypassAuthCheck = false, // ✅ NEW: Bypass auth check for admin panel
  }) async {
    try {
      // ========================================
      // LOGGING: Authentication Check
      // ========================================
      final currentUser = _auth.currentUser;
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('[PushNotificationService] 🔐 AUTHENTICATION CHECK');
      debugPrint('[PushNotificationService] Current User UID: ${currentUser?.uid ?? "NULL"}');
      debugPrint('[PushNotificationService] Is Authenticated: ${currentUser != null}');
      debugPrint('[PushNotificationService] User Email: ${currentUser?.email ?? "N/A"}');
      debugPrint('[PushNotificationService] Bypass Auth Check: $bypassAuthCheck');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      // ✅ NEW: If bypassAuthCheck is true, skip authentication validation
      if (!bypassAuthCheck && currentUser == null) {
        debugPrint('[PushNotificationService] ❌ CRITICAL: User is not authenticated!');
        return {
          'success': false,
          'message': 'User is not authenticated. Please login first.',
          'sentCount': 0,
          'error': 'NOT_AUTHENTICATED',
        };
      }
      
      // ✅ NEW: If bypassAuthCheck is true, set authenticated flag to true
      if (bypassAuthCheck) {
        debugPrint('[PushNotificationService] ✅ ADMIN PANEL BYPASS: Authentication check bypassed');
        debugPrint('[PushNotificationService] ✅ Proceeding with notification send...');
      }
      
      debugPrint('[PushNotificationService] 📤 Sending notification to $gender users');
      debugPrint('[PushNotificationService] Title: $title');
      debugPrint('[PushNotificationService] Body: $body');
      debugPrint('[PushNotificationService] Type: $notificationType');
      
      // ========================================
      // LOGGING: Step 1 - Query Users
      // ========================================
      debugPrint('[PushNotificationService] 📋 STEP 1: Querying users collection');
      
      QuerySnapshot<Map<String, dynamic>> snapshot;
      List<String> userIds = [];
      
      if (gender.toLowerCase() == 'all') {
        debugPrint('[PushNotificationService] Fetching all users (no gender filter)');
        snapshot = await _firestore.collection('users').get();
        userIds = snapshot.docs.map((doc) => doc.id).toList();
      } else {
        debugPrint('[PushNotificationService] Filtering by gender: $gender');
        
        // Try multiple gender variations to match different formats in database
        List<String> genderVariations = [];
        if (gender.toLowerCase() == 'male') {
          genderVariations = ['male', 'Male', 'man', 'Man', 'MALE'];
        } else if (gender.toLowerCase() == 'female') {
          genderVariations = ['female', 'Female', 'woman', 'Woman', 'FEMALE'];
        }
        
        debugPrint('[PushNotificationService] Trying gender variations: $genderVariations');
        
        // Get all users and filter client-side to handle case sensitivity
        snapshot = await _firestore.collection('users').get();
        
        for (var doc in snapshot.docs) {
          final userData = doc.data();
          final userGender = userData['gender'] as String?;
          
          if (userGender != null && genderVariations.contains(userGender)) {
            userIds.add(doc.id);
          }
        }
        
        debugPrint('[PushNotificationService] Matched users after filtering: ${userIds.length}');
      }
      
      debugPrint('[PushNotificationService] ✅ Query successful');
      debugPrint('[PushNotificationService] 📊 Found ${userIds.length} users with gender: $gender');
      
      if (userIds.isEmpty) {
        // Debug: Show what gender values actually exist in the database
        debugPrint('[PushNotificationService] ⚠️ No users found! Checking actual gender values in database...');
        final allUsers = await _firestore.collection('users').limit(10).get();
        final genderValues = <String>{};
        for (var doc in allUsers.docs) {
          final userGender = doc.data()['gender'];
          if (userGender != null) {
            genderValues.add(userGender.toString());
          }
        }
        debugPrint('[PushNotificationService] 📊 Gender values found in database: $genderValues');
        debugPrint('[PushNotificationService] 💡 Suggestion: Check if gender field exists and matches expected format');
        
        return {
          'success': false,
          'message': 'No users found with gender: $gender. Found gender values: $genderValues',
          'sentCount': 0,
        };
      }
      
      // ========================================
      // LOGGING: Step 2 - Send Notifications
      // ========================================
      debugPrint('[PushNotificationService] 📋 STEP 2: Sending notifications to users');
      int sentCount = 0;
      int failedCount = 0;
      List<String> failedUserIds = [];
      
      // Use batch writes for better performance
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      const int batchSize = 500; // Firestore batch limit
      
      for (final userId in userIds) {
        try {
          debugPrint('[PushNotificationService] 👤 Processing user: $userId');
          
          // Get user's FCM token
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final fcmToken = userDoc.data()?['fcmToken'] as String?;
          
          if (fcmToken == null) {
            debugPrint('[PushNotificationService] ⚠️ No FCM token for user: $userId');
            failedCount++;
            failedUserIds.add(userId);
            continue;
          }
          
          debugPrint('[PushNotificationService] ✅ FCM token found for user: $userId');
          
          // Create notification entry matching the actual schema
          final notifRef = _firestore.collection('notifications').doc();
          
          debugPrint('[PushNotificationService] 📝 Creating notification document: ${notifRef.id}');
          debugPrint('[PushNotificationService] Document path: notifications/${notifRef.id}');
          
          batch.set(notifRef, {
            'userId': userId,
            'title': title,
            'body': body,
            'type': notificationType,
            'data': {
              'screen': 'notifications',
              ...?data,
            },
            'fcmToken': fcmToken,
            'read': false,
            'createdAt': Timestamp.now(),
            'status': 'pending',
            'gender': gender,
          });
          
          debugPrint('[PushNotificationService] ✅ Added to batch for user: $userId');
          
          batchCount++;
          sentCount++;
          
          // Commit batch every 500 writes
          if (batchCount >= batchSize) {
            debugPrint('[PushNotificationService] 📦 BATCH COMMIT: Committing $batchCount writes');
            try {
              await batch.commit();
              debugPrint('[PushNotificationService] ✅ Batch committed successfully');
            } catch (batchError) {
              debugPrint('[PushNotificationService] ❌ BATCH COMMIT FAILED: $batchError');
              debugPrint('[PushNotificationService] Error type: ${batchError.runtimeType}');
              if (batchError.toString().contains('permission-denied')) {
                debugPrint('[PushNotificationService] 🔐 PERMISSION DENIED in batch commit');
                debugPrint('[PushNotificationService] Check Firestore rules for notifications collection');
                debugPrint('[PushNotificationService] Rule should be: allow create: if isAuthenticated();');
              }
              rethrow;
            }
            batch = _firestore.batch();
            batchCount = 0;
            debugPrint('[PushNotificationService] 📊 Total sent so far: $sentCount');
          }
        } catch (e) {
          debugPrint('[PushNotificationService] ❌ Error processing user $userId: $e');
          debugPrint('[PushNotificationService] Error type: ${e.runtimeType}');
          debugPrint('[PushNotificationService] Error details: ${e.toString()}');
          
          // Detailed permission error logging
          if (e.toString().contains('permission-denied')) {
            debugPrint('[PushNotificationService] 🔐 PERMISSION DENIED ERROR DETECTED');
            debugPrint('[PushNotificationService] ═══════════════════════════════════════');
            debugPrint('[PushNotificationService] TROUBLESHOOTING STEPS:');
            debugPrint('[PushNotificationService] 1. Check Firestore Rules are published');
            debugPrint('[PushNotificationService] 2. Verify rule: allow create: if isAuthenticated();');
            debugPrint('[PushNotificationService] 3. Verify collection: notifications');
            debugPrint('[PushNotificationService] 4. Verify user is authenticated: ${currentUser?.uid}');
            debugPrint('[PushNotificationService] 5. Check browser console for more details');
            debugPrint('[PushNotificationService] ═══════════════════════════════════════');
          }
          
          failedCount++;
          failedUserIds.add(userId);
        }
      }
      
      // Commit remaining batch
      if (batchCount > 0) {
        debugPrint('[PushNotificationService] 📦 FINAL BATCH COMMIT: Committing $batchCount writes');
        try {
          await batch.commit();
          debugPrint('[PushNotificationService] ✅ Final batch committed successfully');
        } catch (batchError) {
          debugPrint('[PushNotificationService] ❌ FINAL BATCH COMMIT FAILED: $batchError');
          debugPrint('[PushNotificationService] Error type: ${batchError.runtimeType}');
          if (batchError.toString().contains('permission-denied')) {
            debugPrint('[PushNotificationService] 🔐 PERMISSION DENIED in final batch commit');
          }
          rethrow;
        }
      }
      
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('[PushNotificationService] ✅ Notification sending completed');
      debugPrint('[PushNotificationService] 📊 Sent: $sentCount, Failed: $failedCount');
      debugPrint('[PushNotificationService] Failed users: $failedUserIds');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      return {
        'success': true,
        'message': 'Notification sent to $sentCount users',
        'sentCount': sentCount,
        'failedCount': failedCount,
        'totalUsers': userIds.length,
        'failedUserIds': failedUserIds,
      };
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('[PushNotificationService] ❌ CRITICAL ERROR');
      debugPrint('[PushNotificationService] Error: $e');
      debugPrint('[PushNotificationService] Error type: ${e.runtimeType}');
      debugPrint('[PushNotificationService] Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('═══════════════════════════════════════════════════════════');
      
      // Detailed error analysis
      if (e.toString().contains('permission-denied')) {
        debugPrint('[PushNotificationService] 🔐 PERMISSION DENIED - ROOT CAUSE ANALYSIS');
        debugPrint('[PushNotificationService] ═══════════════════════════════════════');
        debugPrint('[PushNotificationService] POSSIBLE CAUSES:');
        debugPrint('[PushNotificationService] 1. Firestore rules not published');
        debugPrint('[PushNotificationService] 2. Rules missing: allow create: if isAuthenticated();');
        debugPrint('[PushNotificationService] 3. User not authenticated (UID: ${_auth.currentUser?.uid})');
        debugPrint('[PushNotificationService] 4. Collection path incorrect (should be: notifications)');
        debugPrint('[PushNotificationService] 5. Database in test mode with restrictive rules');
        debugPrint('[PushNotificationService] ═══════════════════════════════════════');
      }
      
      return {
        'success': false,
        'message': 'Error sending notification: $e',
        'sentCount': 0,
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
    }
  }

  // Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[PushNotificationService] Error getting history: $e');
      return [];
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final snapshot = await _firestore.collection('notifications').get();
      
      int totalSent = 0;
      int totalFailed = 0;
      int totalNotifications = snapshot.docs.length;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalSent += (data['sentCount'] as int?) ?? 0;
        totalFailed += (data['failedCount'] as int?) ?? 0;
      }
      
      return {
        'totalNotifications': totalNotifications,
        'totalSent': totalSent,
        'totalFailed': totalFailed,
        'successRate': totalSent > 0 ? ((totalSent / (totalSent + totalFailed)) * 100).toStringAsFixed(2) : '0',
      };
    } catch (e) {
      debugPrint('[PushNotificationService] Error getting stats: $e');
      return {
        'totalNotifications': 0,
        'totalSent': 0,
        'totalFailed': 0,
        'successRate': '0',
      };
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      debugPrint('[PushNotificationService] Error deleting notification: $e');
      return false;
    }
  }
}
