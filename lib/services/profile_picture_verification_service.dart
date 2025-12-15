import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage profile picture verification requirements
/// Ensures mandatory live verification when users change profile pictures
class ProfilePictureVerificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Check if user has a pending profile picture verification
  /// Returns true if user uploaded a new picture but hasn't verified it yet
  static Future<bool> hasPendingProfilePictureVerification() async {
    try {
      final user = _auth.currentUser;
      print('🟢 [ProfilePictureVerificationService] Checking pending verification...');
      print('🟢 [ProfilePictureVerificationService] Current user: ${user?.uid}');
      
      if (user == null) {
        print('🟢 [ProfilePictureVerificationService] ❌ No user logged in');
        return false;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      print('🟢 [ProfilePictureVerificationService] User doc exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        print('🟢 [ProfilePictureVerificationService] ❌ User document does not exist');
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      
      print('🟢 [ProfilePictureVerificationService] User data keys: ${data.keys.toList()}');
      print('🟢 [ProfilePictureVerificationService] Full user data: $data');
      
      // Check if there's a pending profile picture verification
      final hasPending = data['pendingProfilePictureVerification'] ?? false;
      final pendingUrl = data['pendingProfilePictureUrl'];
      
      print('🟢 [ProfilePictureVerificationService] pendingProfilePictureVerification: $hasPending');
      print('🟢 [ProfilePictureVerificationService] pendingProfilePictureUrl: $pendingUrl');
      print('🟢 [ProfilePictureVerificationService] ✅ Pending profile picture verification check: $hasPending');
      
      return hasPending;
    } catch (e) {
      print('🟢 [ProfilePictureVerificationService] ❌ Error checking pending verification: $e');
      print('🟢 [ProfilePictureVerificationService] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Get the pending profile picture URL that needs verification
  static Future<String?> getPendingProfilePictureUrl() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;
      
      // Get the pending picture URL
      final pendingUrl = data['pendingProfilePictureUrl'] as String?;
      
      return pendingUrl;
    } catch (e) {
      print('❌ Error getting pending picture URL: $e');
      return null;
    }
  }

  /// Mark a new profile picture as pending verification
  /// This is called when user uploads a new picture
  static Future<void> markProfilePictureAsPending(String newPictureUrl) async {
    try {
      final user = _auth.currentUser;
      print('🟢 [ProfilePictureVerificationService] markProfilePictureAsPending called');
      print('🟢 [ProfilePictureVerificationService] User: ${user?.uid}');
      print('🟢 [ProfilePictureVerificationService] Picture URL: $newPictureUrl');
      
      if (user == null) throw Exception('User not authenticated');

      print('🟢 [ProfilePictureVerificationService] Updating Firestore...');
      await _firestore.collection('users').doc(user.uid).update({
        'pendingProfilePictureVerification': true,
        'pendingProfilePictureUrl': newPictureUrl,
        'pendingProfilePictureUploadedAt': FieldValue.serverTimestamp(),
      });

      print('🟢 [ProfilePictureVerificationService] ✅ Profile picture marked as pending verification: $newPictureUrl');
    } catch (e) {
      print('🟢 [ProfilePictureVerificationService] ❌ Error marking picture as pending: $e');
      print('🟢 [ProfilePictureVerificationService] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Complete profile picture verification
  /// Called after user successfully completes live verification
  static Future<void> completeProfilePictureVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the pending picture URL
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) throw Exception('User document not found');

      final data = userDoc.data() as Map<String, dynamic>;
      final pendingUrl = data['pendingProfilePictureUrl'] as String?;

      if (pendingUrl == null) {
        throw Exception('No pending picture URL found');
      }

      // Get current photos list
      final currentPhotos = List<String>.from(data['photos'] ?? []);

      // Add pending picture to photos if not already there
      if (!currentPhotos.contains(pendingUrl)) {
        currentPhotos.insert(0, pendingUrl); // Add as first photo
      }

      // Clear pending verification
      await _firestore.collection('users').doc(user.uid).update({
        'photos': currentPhotos,
        'pendingProfilePictureVerification': false,
        'pendingProfilePictureUrl': FieldValue.delete(),
        'pendingProfilePictureUploadedAt': FieldValue.delete(),
        'lastProfilePictureVerifiedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Profile picture verification completed');
    } catch (e) {
      print('❌ Error completing verification: $e');
      rethrow;
    }
  }

  /// Discard pending profile picture
  /// Called when user chooses to revert to previous picture
  static Future<void> discardPendingProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Clear pending verification without adding the picture
      await _firestore.collection('users').doc(user.uid).update({
        'pendingProfilePictureVerification': false,
        'pendingProfilePictureUrl': FieldValue.delete(),
        'pendingProfilePictureUploadedAt': FieldValue.delete(),
      });

      print('✅ Pending profile picture discarded');
    } catch (e) {
      print('❌ Error discarding pending picture: $e');
      rethrow;
    }
  }

  /// Get verification details for UI display
  static Future<ProfilePictureVerificationStatus> getVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ProfilePictureVerificationStatus(
          hasPending: false,
          pendingUrl: null,
          reason: 'User not logged in',
        );
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return ProfilePictureVerificationStatus(
          hasPending: false,
          pendingUrl: null,
          reason: 'User profile not found',
        );
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final hasPending = data['pendingProfilePictureVerification'] ?? false;
      final pendingUrl = data['pendingProfilePictureUrl'] as String?;

      if (!hasPending) {
        return ProfilePictureVerificationStatus(
          hasPending: false,
          pendingUrl: null,
          reason: 'No pending verification',
        );
      }

      return ProfilePictureVerificationStatus(
        hasPending: true,
        pendingUrl: pendingUrl,
        reason: 'Pending profile picture verification required',
      );
    } catch (e) {
      print('❌ Error getting verification status: $e');
      return ProfilePictureVerificationStatus(
        hasPending: false,
        pendingUrl: null,
        reason: 'Error checking verification',
      );
    }
  }
}

/// Model for profile picture verification status
class ProfilePictureVerificationStatus {
  final bool hasPending;
  final String? pendingUrl;
  final String reason;

  ProfilePictureVerificationStatus({
    required this.hasPending,
    required this.pendingUrl,
    required this.reason,
  });
}
