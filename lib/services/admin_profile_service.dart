import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AdminProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin user IDs that can bypass verification
  static const List<String> adminUserIds = [
    'admin_user',
    'tanishk_admin',
    'shooluv_admin',
    'dev_admin',
  ];

  // Check if current user is admin
  bool isAdmin(String userId) {
    return adminUserIds.contains(userId);
  }

  // Upload photo without verification (admin bypass)
  Future<String> uploadAdminPhoto(File imageFile, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'admin_photos/$userId/$timestamp.jpg';
      
      final ref = _storage.ref().child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      debugPrint('[AdminProfileService] Photo uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[AdminProfileService] Error uploading photo: $e');
      rethrow;
    }
  }

  // Update admin profile with photos (bypass verification)
  Future<void> updateAdminProfile({
    required String userId,
    required String name,
    required List<String> photoUrls,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      if (!isAdmin(userId)) {
        throw Exception('User is not an admin');
      }

      final updateData = <String, dynamic>{
        'name': name,
        'photos': photoUrls,
        'isVerified': true, // Auto-verify admin profiles
        'isPremium': true, // Auto-premium for admins
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (bio != null) updateData['bio'] = bio;
      if (interests != null) updateData['interests'] = interests;
      if (dateOfBirth != null) updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      if (gender != null) updateData['gender'] = gender;

      await _firestore.collection('users').doc(userId).update(updateData);
      
      debugPrint('[AdminProfileService] Admin profile updated: $userId');
    } catch (e) {
      debugPrint('[AdminProfileService] Error updating profile: $e');
      rethrow;
    }
  }

  // Create or update admin user document
  Future<void> createAdminUser({
    required String userId,
    required String name,
    required String phoneNumber,
    List<String>? photoUrls,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      if (!isAdmin(userId)) {
        throw Exception('User ID is not in admin list');
      }

      final userData = {
        'uid': userId,
        'name': name,
        'phoneNumber': phoneNumber,
        'photos': photoUrls ?? [],
        'bio': bio ?? 'Admin User',
        'interests': interests ?? ['Admin', 'Management'],
        'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
        'gender': gender ?? 'Female',
        'isVerified': true,
        'isPremium': true,
        'matches': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true),
      );
      
      debugPrint('[AdminProfileService] Admin user created/updated: $userId');
    } catch (e) {
      debugPrint('[AdminProfileService] Error creating admin user: $e');
      rethrow;
    }
  }

  // Get admin profile
  Future<Map<String, dynamic>?> getAdminProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('[AdminProfileService] Error getting admin profile: $e');
      return null;
    }
  }

  // Update admin leaderboard entry (integrates with rewards system)
  Future<void> updateAdminLeaderboard({
    required String userId,
    required int points,
    int? rank,
    String? badge,
  }) async {
    try {
      if (!isAdmin(userId)) {
        throw Exception('User is not an admin');
      }

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Admin user profile not found');
      }

      final userData = userDoc.data()!;

      // Update rewards_stats collection (this is what the actual leaderboard reads from)
      final rewardsStatsData = {
        'userId': userId,
        'totalScore': points,
        'weeklyScore': points,
        'monthlyScore': points, // This is what shows on leaderboard
        'messagesSent': 0,
        'repliesGiven': 0,
        'imagesSent': 0,
        'positiveFeedbackRatio': 1.0,
        'currentStreak': 0,
        'longestStreak': 0,
        'weeklyRank': rank ?? 0,
        'monthlyRank': rank ?? 0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isAdmin': true,
      };

      await _firestore
          .collection('rewards_stats')
          .doc(userId)
          .set(rewardsStatsData, SetOptions(merge: true));
      
      debugPrint('[AdminProfileService] Admin rewards stats updated: $userId with $points points');
    } catch (e) {
      debugPrint('[AdminProfileService] Error updating leaderboard: $e');
      rethrow;
    }
  }

  // Get admin leaderboard entry (from rewards_stats)
  Future<Map<String, dynamic>?> getAdminLeaderboardEntry(String userId) async {
    try {
      final doc = await _firestore.collection('rewards_stats').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('[AdminProfileService] Error getting leaderboard entry: $e');
      return null;
    }
  }

  // Delete admin photo
  Future<void> deleteAdminPhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      debugPrint('[AdminProfileService] Photo deleted: $photoUrl');
    } catch (e) {
      debugPrint('[AdminProfileService] Error deleting photo: $e');
      rethrow;
    }
  }

  // Remove admin from leaderboard
  Future<void> removeFromLeaderboard(String userId) async {
    try {
      if (!isAdmin(userId)) {
        throw Exception('User is not an admin');
      }

      await _firestore.collection('rewards_stats').doc(userId).delete();
      debugPrint('[AdminProfileService] Admin removed from leaderboard: $userId');
    } catch (e) {
      debugPrint('[AdminProfileService] Error removing from leaderboard: $e');
      rethrow;
    }
  }

  // Stream admin profile
  Stream<DocumentSnapshot> streamAdminProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Stream admin leaderboard entry
  Stream<DocumentSnapshot> streamAdminLeaderboardEntry(String userId) {
    return _firestore.collection('rewards_stats').doc(userId).snapshots();
  }
}
