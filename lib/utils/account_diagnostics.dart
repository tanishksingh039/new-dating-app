import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Diagnostic utility to check for account issues
class AccountDiagnostics {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AccountDiagnostics] $message');
    }
  }

  /// Check current user's account status
  static Future<void> checkCurrentUser() async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        _log('❌ No user is currently signed in');
        return;
      }

      _log('═══════════════════════════════════════');
      _log('🔍 ACCOUNT DIAGNOSTICS');
      _log('═══════════════════════════════════════');
      _log('Firebase Auth User:');
      _log('  UID: ${user.uid}');
      _log('  Email: ${user.email ?? "N/A"}');
      _log('  Phone: ${user.phoneNumber ?? "N/A"}');
      _log('  Display Name: ${user.displayName ?? "N/A"}');
      _log('  Email Verified: ${user.emailVerified}');
      _log('  Created: ${user.metadata.creationTime}');
      _log('  Last Sign In: ${user.metadata.lastSignInTime}');
      _log('───────────────────────────────────────');

      // Check Firestore document
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        _log('⚠️ WARNING: Firestore document does NOT exist!');
        _log('   This user needs to complete signup process.');
        _log('═══════════════════════════════════════');
        return;
      }

      final data = doc.data();
      if (data == null) {
        _log('⚠️ WARNING: Firestore document exists but has no data!');
        _log('═══════════════════════════════════════');
        return;
      }

      _log('Firestore Document:');
      _log('  Document ID: ${doc.id}');
      _log('  Email: ${data['email'] ?? "N/A"}');
      _log('  Phone: ${data['phoneNumber'] ?? "N/A"}');
      _log('  Name: ${data['name'] ?? "N/A"}');
      _log('  Onboarding Complete: ${data['isOnboardingComplete'] ?? false}');
      _log('  Onboarding Step: ${data['onboardingStep'] ?? "N/A"}');
      _log('  Profile Complete: ${data['profileComplete'] ?? 0}%');
      _log('  Created At: ${data['createdAt']}');
      _log('  Last Active: ${data['lastActive']}');
      _log('───────────────────────────────────────');

      // Check for potential issues
      final issues = <String>[];
      
      if (user.uid != data['uid']) {
        issues.add('❌ UID mismatch between Auth and Firestore!');
      }
      
      if (user.email != null && data['email'] != user.email) {
        issues.add('⚠️ Email mismatch between Auth and Firestore');
      }
      
      if (data['isOnboardingComplete'] != true && 
          data['onboardingCompleted'] != true &&
          data['profileComplete'] < 50) {
        issues.add('⚠️ Onboarding appears incomplete');
      }

      if (issues.isEmpty) {
        _log('✅ No issues detected - Account looks good!');
      } else {
        _log('⚠️ ISSUES DETECTED:');
        for (final issue in issues) {
          _log('  $issue');
        }
      }
      
      _log('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      _log('❌ Error during diagnostics: $e');
      _log('Stack trace: $stackTrace');
    }
  }

  /// Check for duplicate accounts by email
  static Future<void> checkForDuplicates() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        _log('Cannot check for duplicates - no email available');
        return;
      }

      _log('═══════════════════════════════════════');
      _log('🔍 CHECKING FOR DUPLICATE ACCOUNTS');
      _log('═══════════════════════════════════════');
      _log('Searching for email: ${user.email}');

      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isEmpty) {
        _log('⚠️ No documents found with this email!');
        _log('═══════════════════════════════════════');
        return;
      }

      if (snapshot.docs.length == 1) {
        _log('✅ Only ONE document found - No duplicates!');
        _log('   Document ID: ${snapshot.docs.first.id}');
        _log('═══════════════════════════════════════');
        return;
      }

      _log('❌ DUPLICATE ACCOUNTS DETECTED!');
      _log('   Found ${snapshot.docs.length} documents with same email:');
      _log('───────────────────────────────────────');

      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        _log('   Document ${i + 1}:');
        _log('     ID: ${doc.id}');
        _log('     Current: ${doc.id == user.uid ? "✅ YES" : "❌ NO"}');
        _log('     Name: ${data['name'] ?? "N/A"}');
        _log('     Onboarding: ${data['isOnboardingComplete'] == true ? "✅ Complete" : "❌ Incomplete"}');
        _log('     Profile: ${data['profileComplete'] ?? 0}%');
        _log('     Created: ${data['createdAt']}');
        _log('───────────────────────────────────────');
      }

      _log('⚠️ ACTION REQUIRED:');
      _log('   Delete duplicate accounts in Firebase Console');
      _log('   Keep the one with completed onboarding');
      _log('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      _log('❌ Error checking for duplicates: $e');
      _log('Stack trace: $stackTrace');
    }
  }

  /// Full diagnostic check (run both checks)
  static Future<void> runFullDiagnostics() async {
    _log('\n\n');
    _log('╔═══════════════════════════════════════╗');
    _log('║   RUNNING FULL ACCOUNT DIAGNOSTICS   ║');
    _log('╚═══════════════════════════════════════╝');
    _log('\n');
    
    await checkCurrentUser();
    await Future.delayed(const Duration(milliseconds: 500));
    await checkForDuplicates();
    
    _log('\n');
    _log('╔═══════════════════════════════════════╗');
    _log('║      DIAGNOSTICS COMPLETE             ║');
    _log('╚═══════════════════════════════════════╝');
    _log('\n\n');
  }
}
