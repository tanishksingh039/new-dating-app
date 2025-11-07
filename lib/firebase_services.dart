import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Firebase Services - All Firestore operations in one place
class FirebaseServices {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Helper method for logging (only in debug mode)
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FirebaseServices] $message');
    }
  }

  /// Save user data to Firestore after authentication
  static Future<void> saveUserData({
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      _log('Saving user data to Firestore...');
      _log('User ID: ${user.uid}');
      _log('Email: ${user.email}');
      _log('Name: ${user.displayName}');

      // Only set onboardingCompleted=false when creating a new user document.
      // If the user doc already exists we must NOT overwrite onboardingCompleted
      // because that would force returning users back into onboarding.
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      final baseData = {
        'uid': user.uid,
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'phone': phoneNumber ?? user.phoneNumber ?? '',
        'photoUrl': user.photoURL ?? '',
        // Update lastLogin on every save, but DO NOT touch createdAt here
        // because merging baseData into an existing document would overwrite
        // the original creation timestamp. createdAt must only be set at
        // creation time.
        'lastLogin': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      };

      if (!doc.exists) {
        // New user - provide sensible defaults including onboarding flag
        final userData = {
          ...baseData,
          'onboardingCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await docRef.set(userData, SetOptions(merge: true));
        _log('New user data saved to Firestore: ${userData.keys.join(', ')}');
      } else {
        // Existing user - merge without touching onboardingCompleted or createdAt
        await docRef.set(baseData, SetOptions(merge: true));
        _log('Existing user data merged to Firestore: ${baseData.keys.join(', ')}');
      }
    } catch (e) {
      _log('Error saving user data to Firestore: $e');
      rethrow;
    }
  }

  /// Check if user has completed onboarding
  static Future<bool> isOnboardingCompleted(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['onboardingCompleted'] ?? false;
      }
      return false;
    } catch (e) {
      _log('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Save onboarding step data (incremental save)
  static Future<void> saveOnboardingStep({
    required String userId,
    required Map<String, dynamic> stepData,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(stepData, SetOptions(merge: true));
      _log('Onboarding step saved: ${stepData.keys.join(', ')}');
    } catch (e) {
      _log('Error saving onboarding step: $e');
      rethrow;
    }
  }

  /// Complete onboarding (mark as done)
  static Future<void> completeOnboarding(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'onboardingCompleted': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      });
      _log('Onboarding completed for user: $userId');
    } catch (e) {
      _log('Error completing onboarding: $e');
      rethrow;
    }
  }

  /// Upload photo to Firebase Storage
  static Future<String> uploadPhoto({
    required String userId,
    required File imageFile,
    required int photoIndex,
  }) async {
    try {
      _log('Uploading photo $photoIndex for user $userId');
      
      final ref = _storage.ref().child('users/$userId/photos/photo_$photoIndex.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      _log('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Delete photo from Firebase Storage
  static Future<void> deletePhoto({
    required String userId,
    required int photoIndex,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/photos/photo_$photoIndex.jpg');
      await ref.delete();
      _log('Photo deleted successfully');
    } catch (e) {
      _log('Error deleting photo: $e');
      // Don't rethrow - photo might not exist
    }
  }

  /// Save photos URLs to Firestore
  static Future<void> savePhotos({
    required String userId,
    required List<String> photoUrls,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photos': photoUrls,
        'photoCount': photoUrls.length,
      });
      _log('Photos saved to Firestore: ${photoUrls.length} photos');
    } catch (e) {
      _log('Error saving photos: $e');
      rethrow;
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      _log('Error getting user data: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
      _log('User profile updated successfully');
    } catch (e) {
      _log('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Get all users except current user (for dating app discovery)
  static Stream<QuerySnapshot> getAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .where('onboardingCompleted', isEqualTo: true) // Only show completed profiles
        .snapshots();
  }

  /// Get users based on preferences (for matching)
  static Stream<QuerySnapshot> getMatchedUsers({
    required String currentUserId,
    String? interestedIn,
    int? minAge,
    int? maxAge,
  }) {
    Query query = _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .where('onboardingCompleted', isEqualTo: true);

    if (interestedIn != null) {
      query = query.where('gender', isEqualTo: interestedIn);
    }

    // Note: Age filtering needs to be done client-side or use Cloud Functions
    // because Firestore has limitations on range queries

    return query.snapshots();
  }

  /// Send message to chat
  static Future<void> sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String messageText,
  }) async {
    try {
      final chatId = _getChatId(currentUserId, otherUserId);
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _log('Message sent successfully');
    } catch (e) {
      _log('Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages for a chat
  static Stream<QuerySnapshot> getMessages(
    String currentUserId,
    String otherUserId,
  ) {
    final chatId = _getChatId(currentUserId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Helper function to generate consistent chat ID
  static String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  /// Delete user data (for account deletion)
  static Future<void> deleteUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      _log('User data deleted successfully');
    } catch (e) {
      _log('Error deleting user data: $e');
      rethrow;
    }
  }

  /// Update last login timestamp
  static Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log('Error updating last login: $e');
    }
  }

  /// Check if user document exists
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      _log('Error checking user existence: $e');
      return false;
    }
  }

  /// Like a user (swipe right)
  static Future<void> likeUser({
    required String currentUserId,
    required String likedUserId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .doc(likedUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Check if it's a match
      final otherUserLiked = await _firestore
          .collection('users')
          .doc(likedUserId)
          .collection('likes')
          .doc(currentUserId)
          .get();

      if (otherUserLiked.exists) {
        // It's a match! Create match document
        await _createMatch(currentUserId, likedUserId);
      }

      _log('User liked successfully');
    } catch (e) {
      _log('Error liking user: $e');
      rethrow;
    }
  }

  /// Create a match between two users
  static Future<void> _createMatch(String userId1, String userId2) async {
    try {
      final matchId = _getChatId(userId1, userId2);
      await _firestore.collection('matches').doc(matchId).set({
        'users': [userId1, userId2],
        'timestamp': FieldValue.serverTimestamp(),
      });
      _log('Match created: $matchId');
    } catch (e) {
      _log('Error creating match: $e');
    }
  }

  /// Pass on a user (swipe left)
  static Future<void> passUser({
    required String currentUserId,
    required String passedUserId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('passes')
          .doc(passedUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      _log('User passed successfully');
    } catch (e) {
      _log('Error passing user: $e');
      rethrow;
    }
  }
}