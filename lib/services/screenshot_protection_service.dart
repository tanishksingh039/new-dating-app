import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';

/// Service to manage screenshot protection
class ScreenshotProtectionService {
  static final ScreenshotProtectionService _instance = ScreenshotProtectionService._internal();
  factory ScreenshotProtectionService() => _instance;
  ScreenshotProtectionService._internal();

  bool _isProtectionEnabled = false;

  /// Enable screenshot protection
  /// This prevents users from taking screenshots of the app
  Future<void> enableProtection() async {
    if (_isProtectionEnabled) return;

    try {
      await ScreenProtector.protectDataLeakageOn();
      _isProtectionEnabled = true;
      debugPrint('✅ Screenshot protection enabled');
    } catch (e) {
      debugPrint('❌ Error enabling screenshot protection: $e');
    }
  }

  /// Disable screenshot protection
  /// Allows users to take screenshots again
  Future<void> disableProtection() async {
    if (!_isProtectionEnabled) return;

    try {
      await ScreenProtector.protectDataLeakageOff();
      _isProtectionEnabled = false;
      debugPrint('✅ Screenshot protection disabled');
    } catch (e) {
      debugPrint('❌ Error disabling screenshot protection: $e');
    }
  }

  /// Check if protection is currently enabled
  bool get isProtectionEnabled => _isProtectionEnabled;

  /// Enable protection for sensitive screens (profiles, photos, chats)
  Future<void> protectSensitiveContent() async {
    await enableProtection();
  }

  /// Disable protection for non-sensitive screens
  Future<void> unprotectContent() async {
    await disableProtection();
  }
}
