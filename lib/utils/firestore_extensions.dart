import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Extension methods for safe Firestore data access
extension SafeDocumentSnapshot on DocumentSnapshot {
  /// Safely get document data as Map<String, dynamic>
  /// Returns null if data is null or not a Map
  Map<String, dynamic>? safeData() {
    try {
      final data = this.data();
      if (data == null) {
        debugPrint('[SafeDocumentSnapshot] Document data is null for ${this.id}');
        return null;
      }
      if (data is Map<String, dynamic>) {
        return data;
      }
      debugPrint('[SafeDocumentSnapshot] Document data is not a Map for ${this.id}: ${data.runtimeType}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[SafeDocumentSnapshot] Error getting data for ${this.id}: $e');
      debugPrint('[SafeDocumentSnapshot] Stack trace: $stackTrace');
      return null;
    }
  }
}

/// Extension methods for safe QueryDocumentSnapshot data access
extension SafeQueryDocumentSnapshot on QueryDocumentSnapshot {
  /// Safely get document data as Map<String, dynamic>
  /// Returns null if data is not a Map
  Map<String, dynamic>? safeData() {
    try {
      final data = this.data();
      if (data is Map<String, dynamic>) {
        return data;
      }
      debugPrint('[SafeQueryDocumentSnapshot] Document data is not a Map for ${this.id}: ${data.runtimeType}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[SafeQueryDocumentSnapshot] Error getting data for ${this.id}: $e');
      debugPrint('[SafeQueryDocumentSnapshot] Stack trace: $stackTrace');
      return null;
    }
  }
}
