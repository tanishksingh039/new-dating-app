import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'services/notification_service.dart';

/// Firebase Services - All Firestore operations in one place
class FirebaseServices {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final NotificationService _notificationService = NotificationService();

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

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      final baseData = {
        'uid': user.uid,
        'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
        'lastActive': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      };

      if (!doc.exists) {
        // New user - initialize with defaults including Phase 2 settings
        final userData = {
          ...baseData,
          'name': '',
          'dateOfBirth': null,
          'gender': '',
          'photos': [],
          'interests': [],
          'bio': '',
          'preferences': {},
          'isOnboardingComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false,
          'isPremium': false,
          'matches': [],
          'matchCount': 0,
          'dailySwipes': {},
          // Phase 2: Privacy settings (defaults)
          'privacySettings': {
            'showOnlineStatus': true,
            'showDistance': true,
            'showAge': true,
            'showLastActive': false,
            'allowMessagesFromMatches': true,
            'incognitoMode': false,
          },
          // Phase 2: Notification settings (defaults)
          'notificationSettings': {
            'pushEnabled': true,
            'newMatchNotif': true,
            'messageNotif': true,
            'likeNotif': true,
            'superLikeNotif': true,
            'emailEnabled': false,
            'emailMatches': false,
            'emailMessages': false,
            'emailPromotions': false,
          },
        };

        await docRef.set(userData, SetOptions(merge: true));
        _log('New user data saved to Firestore');
      } else {
        // Existing user - merge without touching sensitive fields
        await docRef.set(baseData, SetOptions(merge: true));
        _log('Existing user data merged to Firestore');
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
        return data?['isOnboardingComplete'] ?? false;
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
        'isOnboardingComplete': true,
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
        .where('isOnboardingComplete', isEqualTo: true)
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
        .where('isOnboardingComplete', isEqualTo: true);

    if (interestedIn != null) {
      query = query.where('gender', isEqualTo: interestedIn);
    }

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
      final timestamp = FieldValue.serverTimestamp();
      
      // Add message to chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': currentUserId,
        'timestamp': timestamp,
      });

      // Update match document with last message info
      await _updateMatchLastMessage(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        lastMessage: messageText,
      );

      // Send message notification
      await _sendMessageNotification(currentUserId, otherUserId, messageText);

      _log('Message sent successfully');
    } catch (e) {
      _log('Error sending message: $e');
      rethrow;
    }
  }

  /// Update match document with last message and unread count
  static Future<void> _updateMatchLastMessage({
    required String currentUserId,
    required String otherUserId,
    required String lastMessage,
  }) async {
    try {
      final matchId = _getChatId(currentUserId, otherUserId);
      final matchRef = _firestore.collection('matches').doc(matchId);
      final matchDoc = await matchRef.get();

      if (!matchDoc.exists) {
        // Create match if it doesn't exist
        await matchRef.set({
          'users': [currentUserId, otherUserId],
          'lastMessage': lastMessage,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
          'unreadCount_$currentUserId': 0,
          'unreadCount_$otherUserId': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing match
        await matchRef.update({
          'lastMessage': lastMessage,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
          'unreadCount_$otherUserId': FieldValue.increment(1),
          'unreadCount_$currentUserId': 0,
        });
      }

      _log('Match document updated with last message');
    } catch (e) {
      _log('Error updating match last message: $e');
    }
  }

  /// Mark messages as read (reset unread count)
  static Future<void> markMessagesAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final matchId = _getChatId(currentUserId, otherUserId);
      await _firestore.collection('matches').doc(matchId).update({
        'unreadCount_$currentUserId': 0,
      });
      _log('Messages marked as read');
    } catch (e) {
      _log('Error marking messages as read: $e');
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

  /// Update last active timestamp
  static Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log('Error updating last active: $e');
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

  // ============================================================================
  // LIKES FUNCTIONALITY - NEW METHODS
  // ============================================================================

  /// Record a like from current user to another user
  /// This creates entries in both 'likes' and 'receivedLikes' collections
  static Future<void> recordLike({
    required String currentUserId,
    required String likedUserId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Add to current user's likes collection
      final likeRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .doc(likedUserId);
      
      batch.set(likeRef, {
        'userId': likedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add to liked user's receivedLikes collection
      final receivedLikeRef = _firestore
          .collection('users')
          .doc(likedUserId)
          .collection('receivedLikes')
          .doc(currentUserId);
      
      batch.set(receivedLikeRef, {
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _log('Like recorded: $currentUserId liked $likedUserId');
    } catch (e) {
      _log('Error recording like: $e');
      rethrow;
    }
  }

  /// Check if current user has liked another user
  static Future<bool> hasLiked({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .doc(otherUserId)
          .get();
      
      return doc.exists;
    } catch (e) {
      _log('Error checking if liked: $e');
      return false;
    }
  }

  /// Check if another user has liked the current user
  static Future<bool> hasReceivedLikeFrom({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('receivedLikes')
          .doc(otherUserId)
          .get();
      
      return doc.exists;
    } catch (e) {
      _log('Error checking received like: $e');
      return false;
    }
  }

  /// Remove a like (unlike)
  static Future<void> removeLike({
    required String currentUserId,
    required String likedUserId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Remove from current user's likes collection
      final likeRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .doc(likedUserId);
      
      batch.delete(likeRef);

      // Remove from liked user's receivedLikes collection
      final receivedLikeRef = _firestore
          .collection('users')
          .doc(likedUserId)
          .collection('receivedLikes')
          .doc(currentUserId);
      
      batch.delete(receivedLikeRef);

      await batch.commit();
      _log('Like removed: $currentUserId unliked $likedUserId');
    } catch (e) {
      _log('Error removing like: $e');
      rethrow;
    }
  }

  /// Get stream of users who liked current user
  static Stream<QuerySnapshot> getReceivedLikes(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('receivedLikes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get stream of users current user has liked
  static Stream<QuerySnapshot> getSentLikes(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('likes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get count of received likes
  static Future<int> getReceivedLikesCount(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('receivedLikes')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      _log('Error getting received likes count: $e');
      return 0;
    }
  }

  /// Get count of sent likes
  static Future<int> getSentLikesCount(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      _log('Error getting sent likes count: $e');
      return 0;
    }
  }

  /// Check if two users have mutually liked each other
  static Future<bool> isMutualLike({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final currentLikedOther = await hasLiked(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      
      final otherLikedCurrent = await hasLiked(
        currentUserId: otherUserId,
        otherUserId: currentUserId,
      );
      
      return currentLikedOther && otherLikedCurrent;
    } catch (e) {
      _log('Error checking mutual like: $e');
      return false;
    }
  }

  // ============================================================================
  // DEPRECATED METHODS (kept for backward compatibility)
  // ============================================================================

  /// Like a user (swipe right) - Use Discovery/Match services instead
  @Deprecated('Use recordLike() and MatchService.checkAndCreateMatch() instead')
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

      final otherUserLiked = await _firestore
          .collection('users')
          .doc(likedUserId)
          .collection('likes')
          .doc(currentUserId)
          .get();

      if (otherUserLiked.exists) {
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
        'matchedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_$userId1': 0,
        'unreadCount_$userId2': 0,
        'isActive': true,
      });
      _log('Match created: $matchId');
    } catch (e) {
      _log('Error creating match: $e');
    }
  }

  /// Pass on a user (swipe left) - Use Discovery service instead
  @Deprecated('Use DiscoveryService.recordSwipe instead')
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

  /// Update privacy settings (Phase 2)
  static Future<void> updatePrivacySettings({
    required String userId,
    required Map<String, dynamic> privacySettings,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'privacySettings': privacySettings,
      });
      _log('Privacy settings updated');
    } catch (e) {
      _log('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Update notification settings (Phase 2)
  static Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, dynamic> notificationSettings,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationSettings': notificationSettings,
      });
      _log('Notification settings updated');
    } catch (e) {
      _log('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Send message notification
  static Future<void> _sendMessageNotification(
    String senderId,
    String receiverId,
    String messageText,
  ) async {
    try {
      // Get sender's name
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['name'] ?? 'Someone';

      // Truncate message for preview
      final messagePreview = messageText.length > 50
          ? '${messageText.substring(0, 50)}...'
          : messageText;

      // Send notification
      await _notificationService.sendMessageNotification(
        targetUserId: receiverId,
        senderName: senderName,
        messagePreview: messagePreview,
      );

      _log('✅ Message notification sent to $receiverId');
    } catch (e) {
      _log('❌ Error sending message notification: $e');
    }
  }
}