import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Monitor all Firestore operations to track document creation
class FirestoreMonitor {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FirestoreMonitor] $message');
    }
  }

  /// Monitor all user documents in real-time
  static void startMonitoring() {
    _log('🔍 Starting Firestore monitoring...');
    
    // Listen to all changes in users collection
    _firestore.collection('users').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final user = _auth.currentUser;
        final docId = change.doc.id;
        final data = change.doc.data();
        
        // Only log changes for current user
        if (user != null && docId == user.uid) {
          switch (change.type) {
            case DocumentChangeType.added:
              _log('═══════════════════════════════════════');
              _log('🆕 DOCUMENT CREATED!');
              _log('Document ID: $docId');
              _log('Current User ID: ${user.uid}');
              _log('Match: ${docId == user.uid ? "✅ SAME" : "❌ DIFFERENT!"}');
              _log('Email: ${data?['email'] ?? "N/A"}');
              _log('Name: ${data?['name'] ?? "N/A"}');
              _log('Onboarding Step: ${data?['onboardingStep'] ?? "N/A"}');
              _log('Stack trace:');
              _log(StackTrace.current.toString());
              _log('═══════════════════════════════════════');
              break;
              
            case DocumentChangeType.modified:
              _log('───────────────────────────────────────');
              _log('📝 DOCUMENT UPDATED');
              _log('Document ID: $docId');
              _log('Fields updated: ${data?.keys.join(', ') ?? "unknown"}');
              _log('Onboarding Step: ${data?['onboardingStep'] ?? "N/A"}');
              _log('Profile Complete: ${data?['profileComplete'] ?? 0}%');
              _log('───────────────────────────────────────');
              break;
              
            case DocumentChangeType.removed:
              _log('❌ DOCUMENT DELETED: $docId');
              break;
          }
        }
      }
    }, onError: (error) {
      _log('❌ Monitoring error: $error');
    });
    
    _log('✅ Monitoring started successfully');
  }

  /// Check for duplicate documents with same email
  static Future<void> checkForDuplicates() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        _log('No user or email to check');
        return;
      }

      _log('═══════════════════════════════════════');
      _log('🔍 CHECKING FOR DUPLICATE DOCUMENTS');
      _log('Current User ID: ${user.uid}');
      _log('Email: ${user.email}');
      _log('───────────────────────────────────────');

      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isEmpty) {
        _log('⚠️ NO documents found with email: ${user.email}');
      } else if (snapshot.docs.length == 1) {
        _log('✅ Only ONE document found');
        _log('Document ID: ${snapshot.docs.first.id}');
        _log('Matches current user: ${snapshot.docs.first.id == user.uid ? "✅ YES" : "❌ NO"}');
      } else {
        _log('❌ DUPLICATE DOCUMENTS DETECTED!');
        _log('Found ${snapshot.docs.length} documents:');
        for (var i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          _log('');
          _log('Document ${i + 1}:');
          _log('  ID: ${doc.id}');
          _log('  Current: ${doc.id == user.uid ? "✅ YES" : "❌ NO"}');
          _log('  Name: ${data['name'] ?? "N/A"}');
          _log('  Onboarding: ${data['isOnboardingComplete'] ?? false}');
          _log('  Created: ${data['createdAt']}');
        }
      }
      _log('═══════════════════════════════════════');
    } catch (e) {
      _log('❌ Error checking duplicates: $e');
    }
  }

  /// List all documents in users collection (for debugging)
  static Future<void> listAllUserDocuments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _log('No user signed in');
        return;
      }

      _log('═══════════════════════════════════════');
      _log('📋 LISTING ALL USER DOCUMENTS');
      _log('Current User ID: ${user.uid}');
      _log('───────────────────────────────────────');

      final snapshot = await _firestore.collection('users').get();
      
      _log('Total documents in users collection: ${snapshot.docs.length}');
      _log('');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final email = data['email'] ?? '';
        
        // Only show documents related to current user's email
        if (email == user.email) {
          _log('Document ID: ${doc.id}');
          _log('  Current: ${doc.id == user.uid ? "✅ YES" : "❌ NO"}');
          _log('  Email: $email');
          _log('  Name: ${data['name'] ?? "N/A"}');
          _log('  Onboarding Complete: ${data['isOnboardingComplete'] ?? false}');
          _log('  Profile Complete: ${data['profileComplete'] ?? 0}%');
          _log('  Created: ${data['createdAt']}');
          _log('───────────────────────────────────────');
        }
      }
      _log('═══════════════════════════════════════');
    } catch (e) {
      _log('❌ Error listing documents: $e');
    }
  }
}
