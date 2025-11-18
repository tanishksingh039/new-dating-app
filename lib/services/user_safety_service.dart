import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../models/block_model.dart';
import '../models/user_model.dart';

class UserSafetyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Block a user
  static Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    String? reason,
  }) async {
    try {
      final blockId = '${blockerId}_$blockedUserId';
      
      final blockModel = BlockModel(
        id: blockId,
        blockerId: blockerId,
        blockedUserId: blockedUserId,
        createdAt: DateTime.now(),
        reason: reason,
      );

      // Create block document
      await _firestore
          .collection('blocks')
          .doc(blockId)
          .set(blockModel.toMap());

      // Update blocker's blocked list
      await _firestore
          .collection('users')
          .doc(blockerId)
          .update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });

      // Update blocked user's blocked by list
      await _firestore
          .collection('users')
          .doc(blockedUserId)
          .update({
        'blockedBy': FieldValue.arrayUnion([blockerId]),
      });

      // Remove any existing match between users
      await _removeMatch(blockerId, blockedUserId);

      debugPrint('User $blockedUserId blocked by $blockerId');
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock a user
  static Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      final blockId = '${blockerId}_$blockedUserId';

      // Delete block document
      await _firestore
          .collection('blocks')
          .doc(blockId)
          .delete();

      // Update blocker's blocked list
      await _firestore
          .collection('users')
          .doc(blockerId)
          .update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });

      // Update blocked user's blocked by list
      await _firestore
          .collection('users')
          .doc(blockedUserId)
          .update({
        'blockedBy': FieldValue.arrayRemove([blockerId]),
      });

      debugPrint('User $blockedUserId unblocked by $blockerId');
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }

  // Check if a user is blocked
  static Future<bool> isUserBlocked({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final blockedUsers = List<String>.from(userData['blockedUsers'] ?? []);
      final blockedBy = List<String>.from(userData['blockedBy'] ?? []);

      return blockedUsers.contains(otherUserId) || blockedBy.contains(otherUserId);
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Get blocked users list
  static Future<List<UserModel>> getBlockedUsers(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final blockedUserIds = List<String>.from(userData['blockedUsers'] ?? []);

      if (blockedUserIds.isEmpty) return [];

      List<UserModel> blockedUsers = [];
      for (String blockedUserId in blockedUserIds) {
        final blockedUserDoc = await _firestore
            .collection('users')
            .doc(blockedUserId)
            .get();

        if (blockedUserDoc.exists) {
          blockedUsers.add(UserModel.fromMap(blockedUserDoc.data()!));
        }
      }

      return blockedUsers;
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  // Report a user
  static Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required ReportReason reason,
    required String description,
  }) async {
    try {
      final reportId = _firestore.collection('reports').doc().id;
      
      final reportModel = ReportModel(
        id: reportId,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('reports')
          .doc(reportId)
          .set(reportModel.toMap());

      debugPrint('User $reportedUserId reported by $reporterId for ${reason.name}');
    } catch (e) {
      debugPrint('Error reporting user: $e');
      rethrow;
    }
  }

  // Get reports for admin panel
  static Future<List<ReportModel>> getReports({
    ReportStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.limit(limit).get();
      
      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting reports: $e');
      return [];
    }
  }

  // Update report status (admin function)
  static Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNotes,
    String? adminId,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'resolvedAt': status == ReportStatus.resolved || status == ReportStatus.dismissed
            ? Timestamp.fromDate(DateTime.now())
            : null,
      };

      if (adminNotes != null) updateData['adminNotes'] = adminNotes;
      if (adminId != null) updateData['adminId'] = adminId;

      await _firestore
          .collection('reports')
          .doc(reportId)
          .update(updateData);

      debugPrint('Report $reportId status updated to ${status.name}');
    } catch (e) {
      debugPrint('Error updating report status: $e');
      rethrow;
    }
  }

  // Get user reports count
  static Future<int> getUserReportsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting user reports count: $e');
      return 0;
    }
  }

  // Helper method to remove match when blocking
  static Future<void> _removeMatch(String user1Id, String user2Id) async {
    try {
      final matchId = _generateMatchId(user1Id, user2Id);
      
      // Delete match document
      await _firestore
          .collection('matches')
          .doc(matchId)
          .delete();

      // Remove from both users' matches arrays
      await _firestore
          .collection('users')
          .doc(user1Id)
          .update({
        'matches': FieldValue.arrayRemove([user2Id]),
      });

      await _firestore
          .collection('users')
          .doc(user2Id)
          .update({
        'matches': FieldValue.arrayRemove([user1Id]),
      });

      debugPrint('Match removed between $user1Id and $user2Id');
    } catch (e) {
      debugPrint('Error removing match: $e');
      // Don't rethrow as this is a helper operation
    }
  }

  // Generate consistent match ID
  static String _generateMatchId(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Filter out blocked users from discovery
  static Future<List<UserModel>> filterBlockedUsers({
    required String currentUserId,
    required List<UserModel> users,
  }) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userDoc.exists) return users;

      final userData = userDoc.data()!;
      final blockedUsers = List<String>.from(userData['blockedUsers'] ?? []);
      final blockedBy = List<String>.from(userData['blockedBy'] ?? []);

      return users.where((user) {
        return !blockedUsers.contains(user.uid) && !blockedBy.contains(user.uid);
      }).toList();
    } catch (e) {
      debugPrint('Error filtering blocked users: $e');
      return users;
    }
  }
}
