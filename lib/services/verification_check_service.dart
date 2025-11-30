import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to check if user is verified before allowing premium purchases
class VerificationCheckService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Check if current user is verified
  /// Returns: true if verified, false if not verified
  static Future<bool> isUserVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return false;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print('❌ User document does not exist');
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      
      // Check verification status - only isVerified field is required
      final isVerified = data['isVerified'] ?? false;
      
      print('✅ Verification check - isVerified: $isVerified');
      
      return isVerified;
    } catch (e) {
      print('❌ Error checking verification: $e');
      return false;
    }
  }

  /// Get verification status details for UI
  static Future<VerificationStatus> getVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return VerificationStatus(
          isVerified: false,
          reason: 'User not logged in',
        );
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return VerificationStatus(
          isVerified: false,
          reason: 'User profile not found',
        );
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final isVerified = data['isVerified'] ?? false;

      if (!isVerified) {
        return VerificationStatus(
          isVerified: false,
          reason: 'Please verify your account to purchase premium',
        );
      }

      return VerificationStatus(
        isVerified: true,
        reason: 'Verified',
      );
    } catch (e) {
      print('❌ Error getting verification status: $e');
      return VerificationStatus(
        isVerified: false,
        reason: 'Error checking verification',
      );
    }
  }
}

/// Model for verification status
class VerificationStatus {
  final bool isVerified;
  final String reason;

  VerificationStatus({
    required this.isVerified,
    required this.reason,
  });
}
