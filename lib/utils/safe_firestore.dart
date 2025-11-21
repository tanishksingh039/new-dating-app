import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Global safe Firestore helper to prevent ALL null errors
class SafeFirestore {
  /// Safely get document data - NEVER crashes
  static Map<String, dynamic>? getDocumentData(DocumentSnapshot? doc) {
    if (doc == null) {
      debugPrint('[SafeFirestore] Document is null');
      return null;
    }
    
    if (!doc.exists) {
      debugPrint('[SafeFirestore] Document does not exist: ${doc.id}');
      return null;
    }
    
    try {
      final data = doc.data();
      
      if (data == null) {
        debugPrint('[SafeFirestore] Document data is null: ${doc.id}');
        return null;
      }
      
      if (data is Map<String, dynamic>) {
        return data;
      }
      
      debugPrint('[SafeFirestore] Document data is not a Map: ${doc.id}, type: ${data.runtimeType}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[SafeFirestore] Error getting document data: $e');
      debugPrint('[SafeFirestore] Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Safely get query document data - NEVER crashes
  static Map<String, dynamic>? getQueryDocumentData(QueryDocumentSnapshot? doc) {
    if (doc == null) {
      debugPrint('[SafeFirestore] Query document is null');
      return null;
    }
    
    try {
      final data = doc.data();
      
      if (data is Map<String, dynamic>) {
        return data;
      }
      
      debugPrint('[SafeFirestore] Query document data is not a Map: ${doc.id}, type: ${data.runtimeType}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[SafeFirestore] Error getting query document data: $e');
      debugPrint('[SafeFirestore] Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Safely get a field from document data
  static T? getField<T>(Map<String, dynamic>? data, String fieldName, {T? defaultValue}) {
    if (data == null) return defaultValue;
    
    try {
      final value = data[fieldName];
      if (value == null) return defaultValue;
      if (value is T) return value;
      return defaultValue;
    } catch (e) {
      debugPrint('[SafeFirestore] Error getting field $fieldName: $e');
      return defaultValue;
    }
  }
}
