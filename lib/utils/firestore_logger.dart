import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive Firestore logging utility
class FirestoreLogger {
  static const String _tag = '[FirestoreLogger]';
  
  /// Log current user authentication status
  static Future<void> logAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('$_tag 🔐 AUTHENTICATION STATUS');
    debugPrint('$_tag Timestamp: ${DateTime.now()}');
    debugPrint('$_tag User ID: ${user?.uid ?? "NULL"}');
    debugPrint('$_tag Email: ${user?.email ?? "NULL"}');
    debugPrint('$_tag Display Name: ${user?.displayName ?? "NULL"}');
    debugPrint('$_tag Is Anonymous: ${user?.isAnonymous ?? "N/A"}');
    debugPrint('$_tag Email Verified: ${user?.emailVerified ?? "N/A"}');
    debugPrint('$_tag Provider: ${user?.providerData.map((e) => e.providerId).join(", ") ?? "NULL"}');
    debugPrint('$_tag Is Authenticated: ${user != null}');
    debugPrint('═══════════════════════════════════════');
  }
  
  /// Log Firestore query attempt
  static void logQueryAttempt({
    required String collection,
    String? orderBy,
    int? limit,
    Map<String, dynamic>? where,
  }) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('$_tag 📊 FIRESTORE QUERY ATTEMPT');
    debugPrint('$_tag Collection: $collection');
    if (orderBy != null) debugPrint('$_tag OrderBy: $orderBy');
    if (limit != null) debugPrint('$_tag Limit: $limit');
    if (where != null) debugPrint('$_tag Where: $where');
    debugPrint('$_tag Timestamp: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════');
  }
  
  /// Log Firestore error with full details
  static void logFirestoreError({
    required dynamic error,
    required String operation,
    String? collection,
    String? documentId,
    StackTrace? stackTrace,
  }) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('$_tag ❌ FIRESTORE ERROR');
    debugPrint('$_tag Operation: $operation');
    if (collection != null) debugPrint('$_tag Collection: $collection');
    if (documentId != null) debugPrint('$_tag Document ID: $documentId');
    debugPrint('$_tag Error: $error');
    debugPrint('$_tag Error Type: ${error.runtimeType}');
    
    if (error is FirebaseException) {
      debugPrint('$_tag Firebase Code: ${error.code}');
      debugPrint('$_tag Firebase Message: ${error.message}');
      debugPrint('$_tag Firebase Plugin: ${error.plugin}');
    }
    
    if (stackTrace != null) {
      debugPrint('$_tag Stack Trace:');
      debugPrint(stackTrace.toString());
    }
    
    debugPrint('$_tag Timestamp: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════');
  }
  
  /// Log successful Firestore operation
  static void logSuccess({
    required String operation,
    String? collection,
    String? documentId,
    int? count,
  }) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('$_tag ✅ FIRESTORE SUCCESS');
    debugPrint('$_tag Operation: $operation');
    if (collection != null) debugPrint('$_tag Collection: $collection');
    if (documentId != null) debugPrint('$_tag Document ID: $documentId');
    if (count != null) debugPrint('$_tag Document Count: $count');
    debugPrint('$_tag Timestamp: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════');
  }
  
  /// Check if user is admin (hardcoded list)
  static Future<void> logAdminCheck() async {
    final user = FirebaseAuth.instance.currentUser;
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('$_tag 👑 ADMIN CHECK');
    debugPrint('$_tag Current User ID: ${user?.uid ?? "NULL"}');
    
    final adminIds = [
      'xZ4gVEGSW8VzK03vywKxWxDtewt1',
      'mYCF1U576vM7BnQxNULaFkXQoRM2',
      'jwt1l3TLlLS1X6lGuMshBsW7fpf1',
      'PL60f1VkBcf8N1Wfm2ON1HnLX1Yb',
    ];
    
    final isAdmin = user != null && adminIds.contains(user.uid);
    
    debugPrint('$_tag Is Admin: $isAdmin');
    if (isAdmin) {
      debugPrint('$_tag ✅ USER IS ADMIN');
    } else {
      debugPrint('$_tag ❌ USER IS NOT ADMIN');
    }
    debugPrint('$_tag Timestamp: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════');
  }
  
  /// Log Firestore rules evaluation
  static void logRulesEvaluation({
    required String operation,
    required String collection,
    required bool allowed,
    String? reason,
  }) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('$_tag 📜 FIRESTORE RULES EVALUATION');
    debugPrint('$_tag Operation: $operation');
    debugPrint('$_tag Collection: $collection');
    debugPrint('$_tag Allowed: $allowed');
    if (reason != null) debugPrint('$_tag Reason: $reason');
    debugPrint('$_tag Timestamp: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════');
  }
  
  /// Log permission denied error with context
  static void logPermissionDenied({
    required String operation,
    required String collection,
    String? query,
  }) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('$_tag 🚫 PERMISSION DENIED');
    debugPrint('$_tag Operation: $operation');
    debugPrint('$_tag Collection: $collection');
    if (query != null) debugPrint('$_tag Query: $query');
    debugPrint('$_tag Timestamp: ${DateTime.now()}');
    debugPrint('');
    debugPrint('$_tag 🔍 TROUBLESHOOTING STEPS:');
    debugPrint('$_tag 1. Check if user is authenticated');
    debugPrint('$_tag 2. Check if Firestore rules are deployed');
    debugPrint('$_tag 3. Check if user has required permissions');
    debugPrint('$_tag 4. Check if indexes are created');
    debugPrint('$_tag 5. Check Firebase Console for rule errors');
    debugPrint('═══════════════════════════════════════');
  }
}
