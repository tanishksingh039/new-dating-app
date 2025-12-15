import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Service to manage screenshot protection with real-time admin control
/// Listens to admin settings and applies screenshot protection globally
class ScreenshotProtectionService {
  static final ScreenshotProtectionService _instance = ScreenshotProtectionService._internal();
  factory ScreenshotProtectionService() => _instance;
  ScreenshotProtectionService._internal() {
    _initializeListener();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isProtectionEnabled = false;
  bool _adminSettingEnabled = true; // Default: screenshots disabled
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

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
  
  /// Check admin setting for screenshots
  bool get areScreenshotsAllowedByAdmin => _adminSettingEnabled;
  
  /// Initialize real-time listener for admin settings
  void _initializeListener() {
    debugPrint('📡 [ScreenshotProtection] Initializing real-time listener for admin settings');
    
    _settingsSubscription = _firestore
        .collection('admin_settings')
        .doc('app_settings')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data();
              final screenshotsEnabled = data?['screenshotsEnabled'] ?? true;
              
              debugPrint('📡 [ScreenshotProtection] Admin setting changed: screenshotsEnabled = $screenshotsEnabled');
              
              _adminSettingEnabled = screenshotsEnabled;
              
              // Apply the setting immediately
              if (screenshotsEnabled) {
                // Admin enabled screenshots - disable protection
                _applyGlobalProtectionOff();
              } else {
                // Admin disabled screenshots - enable protection
                _applyGlobalProtectionOn();
              }
            } else {
              debugPrint('⚠️ [ScreenshotProtection] Admin settings document does not exist, using default (disabled)');
              _adminSettingEnabled = true;
            }
          },
          onError: (error) {
            debugPrint('❌ [ScreenshotProtection] Error listening to admin settings: $error');
          },
        );
  }
  
  /// Apply screenshot protection globally (called when admin disables screenshots)
  Future<void> _applyGlobalProtectionOn() async {
    try {
      await ScreenProtector.protectDataLeakageOn();
      _isProtectionEnabled = true;
      debugPrint('🔒 [ScreenshotProtection] GLOBAL protection enabled - screenshots BLOCKED');
    } catch (e) {
      debugPrint('❌ [ScreenshotProtection] Error enabling global protection: $e');
    }
  }
  
  /// Remove screenshot protection globally (called when admin enables screenshots)
  Future<void> _applyGlobalProtectionOff() async {
    try {
      await ScreenProtector.protectDataLeakageOff();
      _isProtectionEnabled = false;
      debugPrint('🔓 [ScreenshotProtection] GLOBAL protection disabled - screenshots ALLOWED');
    } catch (e) {
      debugPrint('❌ [ScreenshotProtection] Error disabling global protection: $e');
    }
  }

  /// Enable protection for sensitive screens (profiles, photos, chats)
  /// Now respects admin settings - only protects if admin has disabled screenshots
  Future<void> protectSensitiveContent() async {
    if (!_adminSettingEnabled) {
      // Admin has disabled screenshots, apply protection
      await enableProtection();
    } else {
      debugPrint('ℹ️ [ScreenshotProtection] Screenshots allowed by admin, skipping protection');
    }
  }

  /// Disable protection for non-sensitive screens
  /// Only disables if not globally enforced by admin
  Future<void> unprotectContent() async {
    if (_adminSettingEnabled) {
      // Only disable if admin allows screenshots
      await disableProtection();
    }
  }
  
  /// Dispose the listener when service is no longer needed
  void dispose() {
    _settingsSubscription?.cancel();
    debugPrint('🔌 [ScreenshotProtection] Listener disposed');
  }
}
