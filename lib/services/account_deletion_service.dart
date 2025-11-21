import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Comprehensive account deletion service
/// Handles deletion of user data across all Firebase services
class AccountDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AccountDeletionService] $message');
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

      // Step 4: Delete Firebase Auth account
      _log('Deleting Firebase Auth account...');
      await user.delete();

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
      // Use batch for atomic operations
      WriteBatch batch = _firestore.batch();
      int operationCount = 0;

      // Helper function to commit batch when it reaches 500 operations
      Future<void> commitBatchIfNeeded() async {
        if (operationCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // 1. Delete user document
      _log('Deleting user document...');
      batch.delete(_firestore.collection('users').doc(userId));
      operationCount++;

      // 2. Delete swipes
      _log('Deleting swipes...');
      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in swipesSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 3. Delete matches (where user is a participant)
      _log('Deleting matches...');
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();
      for (var doc in matchesSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 4. Delete messages sent by user
      _log('Deleting messages...');
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 5. Delete reports made by user
      _log('Deleting reports...');
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .get();
      for (var doc in reportsSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 6. Delete reports against user
      final reportsAgainstSnapshot = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();
      for (var doc in reportsAgainstSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 7. Delete blocks made by user
      _log('Deleting blocks...');
      final blocksSnapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .get();
      for (var doc in blocksSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 8. Delete blocks against user
      final blocksAgainstSnapshot = await _firestore
          .collection('blocks')
          .where('blockedUserId', isEqualTo: userId)
          .get();
      for (var doc in blocksAgainstSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // 9. Delete notifications
      _log('Deleting notifications...');
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;
        await commitBatchIfNeeded();
      }

      // Commit final batch
      if (operationCount > 0) {
        await batch.commit();
      }

      _log('Firestore data deleted successfully');
    } catch (e) {
      _log('Error deleting Firestore data: $e');
      rethrow;
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
