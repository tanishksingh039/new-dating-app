import 'package:flutter/foundation.dart';
import '../services/icebreaker_service.dart';

/// Utility function to initialize icebreaker prompts in Firestore
/// Call this once during app setup or from admin panel
Future<void> initializeIcebreakers() async {
  try {
    debugPrint('[InitializeIcebreakers] Starting initialization...');
    
    final icebreakerService = IcebreakerService();
    await icebreakerService.initializeDefaultPrompts();
    
    debugPrint('[InitializeIcebreakers] ✅ Icebreakers initialized successfully!');
  } catch (e) {
    debugPrint('[InitializeIcebreakers] ❌ Error: $e');
    rethrow;
  }
}
