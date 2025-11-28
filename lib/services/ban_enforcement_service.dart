import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BanEnforcementService {
  static final BanEnforcementService _instance = BanEnforcementService._internal();
  factory BanEnforcementService() => _instance;
  BanEnforcementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user is currently banned
  Future<Map<String, dynamic>> checkBanStatus(String userId) async {
    try {
      debugPrint('[BanEnforcementService] Checking ban status for: $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('[BanEnforcementService] User not found');
        return {'isBanned': false, 'reason': 'User not found'};
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('[BanEnforcementService] User data is null');
        return {'isBanned': false, 'reason': 'User data empty'};
      }

      // Check if account is deleted
      if (data['isDeleted'] == true || data['accountStatus'] == 'deleted') {
        debugPrint('[BanEnforcementService] ❌ Account is deleted');
        return {
          'isBanned': true,
          'banType': 'deleted',
          'reason': data['deletedReason'] ?? 'Account deleted by admin',
          'deletedAt': data['deletedAt'],
        };
      }

      // Check if account is banned
      if (data['isBanned'] == true || data['accountStatus'] == 'banned') {
        final banType = data['banType'] ?? 'permanent';
        final banReason = data['banReason'] ?? 'Violation of community guidelines';

        // Check if temporary ban has expired
        if (banType == 'temporary' && data['bannedUntil'] != null) {
          final bannedUntil = (data['bannedUntil'] as Timestamp).toDate();
          final now = DateTime.now();

          if (now.isAfter(bannedUntil)) {
            debugPrint('[BanEnforcementService] ✅ Temporary ban expired, unbanning user');
            // Ban has expired, unban the user
            await _firestore.collection('users').doc(userId).update({
              'isBanned': false,
              'accountStatus': 'active',
              'bannedUntil': null,
              'unbannedAt': FieldValue.serverTimestamp(),
            });
            return {'isBanned': false, 'reason': 'Ban expired'};
          } else {
            // Still banned
            final daysLeft = bannedUntil.difference(now).inDays;
            final hoursLeft = bannedUntil.difference(now).inHours;

            debugPrint('[BanEnforcementService] ⏳ User is temporarily banned for $daysLeft days');
            return {
              'isBanned': true,
              'banType': 'temporary',
              'reason': banReason,
              'bannedUntil': bannedUntil,
              'daysLeft': daysLeft,
              'hoursLeft': hoursLeft,
              'bannedAt': data['bannedAt'],
            };
          }
        } else if (banType == 'permanent') {
          debugPrint('[BanEnforcementService] ⛔ User is permanently banned');
          return {
            'isBanned': true,
            'banType': 'permanent',
            'reason': banReason,
            'bannedAt': data['bannedAt'],
          };
        }
      }

      // Check if user has warnings
      if (data['accountStatus'] == 'warned' || data['warningCount'] != null && data['warningCount'] > 0) {
        debugPrint('[BanEnforcementService] ⚠️ User has warnings: ${data['warningCount']}');
        return {
          'isBanned': false,
          'isWarned': true,
          'warningCount': data['warningCount'] ?? 0,
          'lastWarningReason': data['lastWarningReason'],
          'lastWarningAt': data['lastWarningAt'],
        };
      }

      debugPrint('[BanEnforcementService] ✅ User is not banned');
      return {'isBanned': false};
    } catch (e, stackTrace) {
      debugPrint('[BanEnforcementService] ❌ Error checking ban status: $e');
      debugPrint('[BanEnforcementService] Error type: ${e.runtimeType}');
      debugPrint('[BanEnforcementService] Stack trace: $stackTrace');
      
      if (e.toString().contains('permission-denied')) {
        debugPrint('[BanEnforcementService] 🔐 PERMISSION DENIED');
        debugPrint('[BanEnforcementService] ═══════════════════════════════════════');
        debugPrint('[BanEnforcementService] TROUBLESHOOTING:');
        debugPrint('[BanEnforcementService] 1. Check Firestore rules are published');
        debugPrint('[BanEnforcementService] 2. Verify rule: allow read: if true;');
        debugPrint('[BanEnforcementService] 3. Collection: users');
        debugPrint('[BanEnforcementService] 4. Copy rules from FIRESTORE_RULES_ADMIN_BYPASS.txt');
        debugPrint('[BanEnforcementService] ═══════════════════════════════════════');
      }
      
      // Return safe default - don't block user if there's an error
      debugPrint('[BanEnforcementService] ℹ️ Returning safe default (not banned)');
      return {'isBanned': false, 'error': e.toString()};
    }
  }

  /// Unban a user (for expired temporary bans)
  Future<void> unbanUser(String userId) async {
    try {
      debugPrint('[BanEnforcementService] Unbanning user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'accountStatus': 'active',
        'bannedUntil': null,
        'unbannedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[BanEnforcementService] ✅ User unbanned successfully');
    } catch (e) {
      debugPrint('[BanEnforcementService] ❌ Error unbanning user: $e');
      rethrow;
    }
  }

  /// Get formatted ban message
  String getBanMessage(Map<String, dynamic> banStatus) {
    if (banStatus['banType'] == 'deleted') {
      return 'Your account has been permanently deleted.\n\nReason: ${banStatus['reason']}';
    } else if (banStatus['banType'] == 'permanent') {
      return 'Your account has been permanently banned.\n\nReason: ${banStatus['reason']}\n\nThis action cannot be reversed.';
    } else if (banStatus['banType'] == 'temporary') {
      final daysLeft = banStatus['daysLeft'] ?? 0;
      final hoursLeft = banStatus['hoursLeft'] ?? 0;
      final timeLeft = daysLeft > 0 ? '$daysLeft days' : '$hoursLeft hours';
      return 'Your account has been temporarily suspended for 7 days.\n\nReason: ${banStatus['reason']}\n\nTime remaining: $timeLeft\n\nYou can use your account again after the suspension period ends.';
    }
    return 'Your account is restricted.';
  }

  /// Get warning message
  String getWarningMessage(Map<String, dynamic> warningStatus) {
    final warningCount = warningStatus['warningCount'] ?? 0;
    final reason = warningStatus['lastWarningReason'] ?? 'Violation of community guidelines';
    return '⚠️ Warning Issued\n\nYou have received a warning for: $reason\n\nWarnings: $warningCount\n\nPlease review our community guidelines. Repeated violations may result in account suspension.';
  }
}
