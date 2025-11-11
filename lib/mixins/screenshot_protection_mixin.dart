import 'package:flutter/widgets.dart';
import '../services/screenshot_protection_service.dart';

/// Mixin to automatically enable screenshot protection when screen is active
/// and disable it when screen is disposed
mixin ScreenshotProtectionMixin<T extends StatefulWidget> on State<T> {
  final ScreenshotProtectionService _screenshotProtection = ScreenshotProtectionService();

  @override
  void initState() {
    super.initState();
    // Enable protection when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenshotProtection.protectSensitiveContent();
    });
  }

  @override
  void dispose() {
    // Disable protection when screen closes
    _screenshotProtection.unprotectContent();
    super.dispose();
  }
}
