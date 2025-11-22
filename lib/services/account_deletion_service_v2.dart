import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Comprehensive account deletion service V2
/// Handles deletion of user data across all Firebase services
class AccountDeletionServiceV2 {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AccountDeletionServiceV2] $message');
    }
  }

  /// Delete user account and all associated data
  /// Returns true if successful, throws exception on error
  static Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final userId = user.uid;
      _log('Starting account deletion for user: $userId');

      // Step 1: Re-authenticate user (required for account deletion)
      await _reauthenticateUser(user);

      // Step 2: Delete all user data from Firestore
      await _deleteFirestoreData(userId);

      // Step 3: Delete user photos from Storage
      await _deleteStorageData(userId);

      // Step 4: Clean up references in other users' documents
      await _cleanupUserReferences(userId);

      // Step 5: Delete Firebase Auth account
      _log('Deleting Firebase Auth account...');
      await user.delete();

      // Step 6: Sign out from Google
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        _log('Google sign out error (non-critical): $e');
      }

      _log('Account deletion completed successfully');
      return true;
    } catch (e) {
      _log('Error during account deletion: $e');
      rethrow;
    }
  }

  /// Re-authenticate user based on their sign-in method
  static Future<void> _reauthenticateUser(User user) async {
    _log('Re-authenticating user...');

    // Get the sign-in method
    final providerData = user.providerData;
    if (providerData.isEmpty) {
      throw Exception('No provider data found for user');
    }

    final providerId = providerData.first.providerId;
    _log('Sign-in provider: $providerId');

    try {
      if (providerId == 'google.com') {
        // Re-authenticate with Google
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          throw Exception('Google sign-in cancelled');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await user.reauthenticateWithCredential(credential);
        _log('Re-authenticated with Google');
      } else if (providerId == 'phone') {
        // For phone auth, we can't easily re-authenticate
        // User might need to verify via OTP again
        throw Exception('Phone authentication requires OTP verification. Please contact support.');
      } else if (providerId == 'password') {
        // For email/password, we need the password
        // This should be handled by the UI before calling this service
        throw Exception('Email/password authentication requires password confirmation');
      } else {
        throw Exception('Unsupported authentication provider: $providerId');
      }
    } catch (e) {
      _log('Re-authentication failed: $e');
      rethrow;
    }
  }

  /// Delete all user data from Firestore collections
  static Future<void> _deleteFirestoreData(String userId) async {
    _log('Deleting Firestore data...');

    try {
      // Delete data in smaller batches to avoid permission issues
      
      // 1. Delete user subcollections first
      await _deleteUserSubcollections(userId);
      
      // 2. Delete swipes
      await _deleteCollection('swipes', 'userId', userId);
      
      // 3. Delete matches (where user is a participant)
      await _deleteMatchesForUser(userId);
      
      // 4. Delete chats and messages
      await _deleteChatsForUser(userId);
      
      // 5. Delete reports made by user
      await _deleteCollection('reports', 'reporterId', userId);
      
      // 6. Delete reports against user
      await _deleteCollection('reports', 'reportedUserId', userId);
      
      // 7. Delete blocks made by user
      await _deleteCollection('blocks', 'blockerId', userId);
      
      // 8. Delete blocks against user
      await _deleteCollection('blocks', 'blockedUserId', userId);
      
      // 9. Delete notifications
      await _deleteCollection('notifications', 'userId', userId);
      
      // 10. Delete swipe stats
      await _deleteDocument('swipe_stats', userId);
      
      // 11. Delete rewards stats
      await _deleteDocument('rewards_stats', userId);
      
      // 12. Delete reward history
      await _deleteCollection('reward_history', 'userId', userId);
      
      // 13. Delete payment orders
      await _deleteCollection('payment_orders', 'userId', userId);
      
      // 14. Delete payment transactions
      await _deleteCollection('payment_transactions', 'userId', userId);
      
      // 15. Delete subscription
      await _deleteDocument('subscriptions', userId);
      
      // 16. Delete spotlight bookings
      await _deleteCollection('spotlight_bookings', 'userId', userId);
      
      // 17. Delete spotlight transactions
      await _deleteCollection('spotlight_transactions', 'userId', userId);
      
      // 18. Delete verification requests
      await _deleteCollection('verification_requests', 'userId', userId);
      
      // 19. Delete verification photos
      await _deleteCollection('verification_photos', 'userId', userId);
      
      // 20. Delete daily conversations
      await _deleteUserSubcollectionPath('daily_conversations', userId);
      
      // 21. Finally, delete user document
      _log('Deleting user document...');
      await _firestore.collection('users').doc(userId).delete();

      _log('Firestore data deleted successfully');
    } catch (e) {
      _log('Error deleting Firestore data: $e');
      rethrow;
    }
  }

  /// Delete user subcollections (likes, receivedLikes, etc.)
  static Future<void> _deleteUserSubcollections(String userId) async {
    _log('Deleting user subcollections...');
    
    final subcollections = [
      'likes',
      'receivedLikes',
      'superLikes',
      'receivedSuperLikes',
      'passes',
    ];
    
    for (final subcollection in subcollections) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection(subcollection)
            .get();
        
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
        _log('Deleted $subcollection: ${snapshot.docs.length} documents');
      } catch (e) {
        _log('Error deleting $subcollection: $e');
      }
    }
  }

  /// Delete a collection based on a field query
  static Future<void> _deleteCollection(
    String collectionName,
    String fieldName,
    String fieldValue,
  ) async {
    try {
      _log('Deleting from $collectionName where $fieldName = $fieldValue...');
      final snapshot = await _firestore
          .collection(collectionName)
          .where(fieldName, isEqualTo: fieldValue)
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _log('Deleted from $collectionName: ${snapshot.docs.length} documents');
    } catch (e) {
      _log('Error deleting from $collectionName: $e');
      // Don't rethrow - continue with other deletions
    }
  }

  /// Delete a single document
  static Future<void> _deleteDocument(String collectionName, String docId) async {
    try {
      _log('Deleting document $collectionName/$docId...');
      await _firestore.collection(collectionName).doc(docId).delete();
      _log('Deleted document $collectionName/$docId');
    } catch (e) {
      _log('Error deleting document $collectionName/$docId: $e');
      // Don't rethrow - continue with other deletions
    }
  }

  /// Delete matches where user is a participant
  static Future<void> _deleteMatchesForUser(String userId) async {
    try {
      _log('Deleting matches for user...');
      final snapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _log('Deleted matches: ${snapshot.docs.length} documents');
    } catch (e) {
      _log('Error deleting matches: $e');
    }
  }

  /// Delete chats and messages for user
  static Future<void> _deleteChatsForUser(String userId) async {
    try {
      _log('Deleting chats for user...');
      
      // Get all chats where user is a participant
      final allChats = await _firestore.collection('chats').get();
      
      for (final chatDoc in allChats.docs) {
        final chatId = chatDoc.id;
        // Check if user is part of this chat (chatId format: userId1_userId2)
        if (chatId.contains(userId)) {
          // Delete all messages in this chat
          final messagesSnapshot = await chatDoc.reference
              .collection('messages')
              .get();
          
          for (final messageDoc in messagesSnapshot.docs) {
            await messageDoc.reference.delete();
          }
          
          // Delete the chat document
          await chatDoc.reference.delete();
          _log('Deleted chat: $chatId with ${messagesSnapshot.docs.length} messages');
        }
      }
    } catch (e) {
      _log('Error deleting chats: $e');
    }
  }

  /// Delete user subcollection path (for collections like daily_conversations/{userId})
  static Future<void> _deleteUserSubcollectionPath(
    String collectionName,
    String userId,
  ) async {
    try {
      _log('Deleting $collectionName for user...');
      final snapshot = await _firestore
          .collection(collectionName)
          .doc(userId)
          .collection('conversations')
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete the parent document
      await _firestore.collection(collectionName).doc(userId).delete();
      _log('Deleted $collectionName: ${snapshot.docs.length} documents');
    } catch (e) {
      _log('Error deleting $collectionName: $e');
    }
  }

  /// Delete all user photos from Firebase Storage
  static Future<void> _deleteStorageData(String userId) async {
    _log('Deleting Storage data...');

    try {
      // Delete user photos folder
      final userPhotosRef = _storage.ref().child('users/$userId');
      
      try {
        final listResult = await userPhotosRef.listAll();
        
        for (var item in listResult.items) {
          _log('Deleting file: ${item.fullPath}');
          await item.delete();
        }

        // Delete subfolders if any
        for (var prefix in listResult.prefixes) {
          await _deleteFolder(prefix);
        }

        _log('Storage data deleted successfully');
      } catch (e) {
        // If folder doesn't exist or is empty, that's fine
        _log('No storage data found or error deleting: $e');
      }
    } catch (e) {
      _log('Error deleting Storage data: $e');
      // Don't rethrow - storage deletion is not critical
    }
  }

  /// Recursively delete a folder in Firebase Storage
  static Future<void> _deleteFolder(Reference folderRef) async {
    final listResult = await folderRef.listAll();
    
    for (var item in listResult.items) {
      await item.delete();
    }

    for (var prefix in listResult.prefixes) {
      await _deleteFolder(prefix);
    }
  }

  /// Update other users' data to remove references to deleted user
  static Future<void> _cleanupUserReferences(String userId) async {
    _log('Cleaning up user references...');

    try {
      // Remove user from other users' blocked lists
      final usersWithBlocks = await _firestore
          .collection('users')
          .where('blockedUsers', arrayContains: userId)
          .get();

      for (var doc in usersWithBlocks.docs) {
        await doc.reference.update({
          'blockedUsers': FieldValue.arrayRemove([userId]),
        });
      }

      // Remove user from other users' blockedBy lists
      final usersBlockedBy = await _firestore
          .collection('users')
          .where('blockedBy', arrayContains: userId)
          .get();

      for (var doc in usersBlockedBy.docs) {
        await doc.reference.update({
          'blockedBy': FieldValue.arrayRemove([userId]),
        });
      }

      // Remove user from other users' matches lists
      final usersWithMatches = await _firestore
          .collection('users')
          .where('matches', arrayContains: userId)
          .get();

      for (var doc in usersWithMatches.docs) {
        await doc.reference.update({
          'matches': FieldValue.arrayRemove([userId]),
          'matchCount': FieldValue.increment(-1),
        });
      }

      _log('User references cleaned up successfully');
    } catch (e) {
      _log('Error cleaning up user references: $e');
      // Don't rethrow - this is cleanup, not critical
    }
  }
}
