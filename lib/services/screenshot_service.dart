import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ScreenshotService {
  static final ScreenshotService _instance = ScreenshotService._internal();
  static const platform = MethodChannel('com.campusbound.app/screenshot');
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _screenshotsEnabled = true;
  bool _isInitialized = false;
  bool _nativeMethodAvailable = false;
  String? _lastError;

  ScreenshotService._internal();

  factory ScreenshotService() {
    return _instance;
  }

  /// Initialize screenshot service and load settings
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[ScreenshotService] ℹ️ Already initialized, skipping...');
      return;
    }
    
    debugPrint('[ScreenshotService] 🚀 Starting initialization...');
    
    try {
      // Check if native method is available
      await _checkNativeMethodAvailability();
      
      // Load settings from Firestore
      await _loadScreenshotSettings();
      
      // Setup real-time listener
      _setupSettingsListener();
      
      _isInitialized = true;
      debugPrint('[ScreenshotService] ✅ Initialization successful');
      debugPrint('[ScreenshotService] Native method available: $_nativeMethodAvailable');
      debugPrint('[ScreenshotService] Screenshots enabled: $_screenshotsEnabled');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[ScreenshotService] ❌ Initialization error: $e');
      debugPrint('[ScreenshotService] Stack trace: ${StackTrace.current}');
      // Don't throw - allow app to continue with fallback
      _isInitialized = true;
    }
  }

  /// Check if native method channel is available
  Future<void> _checkNativeMethodAvailability() async {
    try {
      debugPrint('[ScreenshotService] 🔍 Checking native method availability...');
      await platform.invokeMethod('getScreenshotStatus');
      _nativeMethodAvailable = true;
      debugPrint('[ScreenshotService] ✅ Native method is available');
    } on PlatformException catch (e) {
      if (e.code == 'UNIMPLEMENTED') {
        debugPrint('[ScreenshotService] ⚠️ Native method not implemented: ${e.message}');
        _nativeMethodAvailable = false;
      } else {
        debugPrint('[ScreenshotService] ⚠️ Platform exception: ${e.code} - ${e.message}');
        _nativeMethodAvailable = false;
      }
    } catch (e) {
      debugPrint('[ScreenshotService] ⚠️ Error checking native method: $e');
      _nativeMethodAvailable = false;
    }
  }

  /// Load screenshot settings from Firestore
  Future<void> _loadScreenshotSettings() async {
    try {
      debugPrint('[ScreenshotService] 📥 Loading settings from Firestore...');
      
      final doc = await _firestore
          .collection('admin_settings')
          .doc('app_settings')
          .get(const GetOptions(source: Source.serverAndCache));
      
      if (!doc.exists) {
        debugPrint('[ScreenshotService] ℹ️ Document does not exist, using default (enabled)');
        _screenshotsEnabled = true;
        return;
      }
      
      final data = doc.data();
      debugPrint('[ScreenshotService] 📄 Document data: $data');
      
      _screenshotsEnabled = data?['screenshotsEnabled'] ?? true;
      debugPrint('[ScreenshotService] ✅ Loaded: screenshotsEnabled = $_screenshotsEnabled');
      
      if (!_screenshotsEnabled) {
        await _disableScreenshots();
      }
    } on FirebaseException catch (e) {
      _lastError = 'Firebase error: ${e.code} - ${e.message}';
      debugPrint('[ScreenshotService] ❌ Firebase error: ${e.code} - ${e.message}');
      debugPrint('[ScreenshotService] Falling back to enabled state');
      _screenshotsEnabled = true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[ScreenshotService] ❌ Error loading settings: $e');
      debugPrint('[ScreenshotService] Falling back to enabled state');
      _screenshotsEnabled = true;
    }
  }

  /// Setup real-time listener for screenshot settings changes
  void _setupSettingsListener() {
    debugPrint('[ScreenshotService] 👂 Setting up real-time listener...');
    
    _firestore
        .collection('admin_settings')
        .doc('app_settings')
        .snapshots()
        .listen(
      (snapshot) async {
        try {
          debugPrint('[ScreenshotService] 📡 Received snapshot update');
          
          if (!snapshot.exists) {
            debugPrint('[ScreenshotService] ℹ️ Document does not exist in snapshot');
            return;
          }
          
          final data = snapshot.data();
          debugPrint('[ScreenshotService] 📄 Snapshot data: $data');
          
          final enabled = data?['screenshotsEnabled'] ?? true;
          
          if (enabled != _screenshotsEnabled) {
            debugPrint('[ScreenshotService] 🔄 Settings changed: $_screenshotsEnabled → $enabled');
            _screenshotsEnabled = enabled;
            
            // Apply changes immediately without delay
            if (!_screenshotsEnabled) {
              debugPrint('[ScreenshotService] ⏱️ Applying disable immediately...');
              await _disableScreenshots();
              debugPrint('[ScreenshotService] ✅ Disable applied immediately');
            } else {
              debugPrint('[ScreenshotService] ⏱️ Applying enable immediately...');
              await _enableScreenshots();
              debugPrint('[ScreenshotService] ✅ Enable applied immediately');
            }
          } else {
            debugPrint('[ScreenshotService] ℹ️ Settings unchanged: $enabled');
          }
        } catch (e) {
          _lastError = 'Listener processing error: $e';
          debugPrint('[ScreenshotService] ❌ Error processing snapshot: $e');
        }
      },
      onError: (e) {
        _lastError = 'Listener error: $e';
        debugPrint('[ScreenshotService] ❌ Listener error: $e');
        debugPrint('[ScreenshotService] Real-time updates may not work, but app will continue');
      },
    );
  }

  /// Disable screenshots on the native side
  Future<void> _disableScreenshots() async {
    if (!_nativeMethodAvailable) {
      debugPrint('[ScreenshotService] ⚠️ Native method not available, skipping disable');
      return;
    }
    
    try {
      debugPrint('[ScreenshotService] 🔄 Invoking native disableScreenshots method...');
      await platform.invokeMethod('disableScreenshots');
      debugPrint('[ScreenshotService] ✅ Screenshots disabled successfully');
    } on PlatformException catch (e) {
      _lastError = 'Platform exception: ${e.code} - ${e.message}';
      debugPrint('[ScreenshotService] ❌ Platform exception: ${e.code}');
      debugPrint('[ScreenshotService] Message: ${e.message}');
      debugPrint('[ScreenshotService] Details: ${e.details}');
    } catch (e) {
      _lastError = 'Error disabling screenshots: $e';
      debugPrint('[ScreenshotService] ❌ Error disabling screenshots: $e');
      debugPrint('[ScreenshotService] Stack trace: ${StackTrace.current}');
    }
  }

  /// Enable screenshots on the native side
  Future<void> _enableScreenshots() async {
    if (!_nativeMethodAvailable) {
      debugPrint('[ScreenshotService] ⚠️ Native method not available, skipping enable');
      return;
    }
    
    try {
      debugPrint('[ScreenshotService] 🔄 Invoking native enableScreenshots method...');
      await platform.invokeMethod('enableScreenshots');
      debugPrint('[ScreenshotService] ✅ Screenshots enabled successfully');
    } on PlatformException catch (e) {
      _lastError = 'Platform exception: ${e.code} - ${e.message}';
      debugPrint('[ScreenshotService] ❌ Platform exception: ${e.code}');
      debugPrint('[ScreenshotService] Message: ${e.message}');
      debugPrint('[ScreenshotService] Details: ${e.details}');
    } catch (e) {
      _lastError = 'Error enabling screenshots: $e';
      debugPrint('[ScreenshotService] ❌ Error enabling screenshots: $e');
      debugPrint('[ScreenshotService] Stack trace: ${StackTrace.current}');
    }
  }

  /// Get current screenshot status
  bool get screenshotsEnabled => _screenshotsEnabled;

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Get native method availability
  bool get nativeMethodAvailable => _nativeMethodAvailable;

  /// Get last error message
  String? get lastError => _lastError;

  /// Check if screenshots are enabled
  Future<bool> areScreenshotsEnabled() async {
    try {
      debugPrint('[ScreenshotService] 🔍 Checking screenshot status...');
      
      final doc = await _firestore
          .collection('admin_settings')
          .doc('app_settings')
          .get(const GetOptions(source: Source.serverAndCache));
      
      final enabled = doc.data()?['screenshotsEnabled'] ?? true;
      debugPrint('[ScreenshotService] ✅ Status check result: $enabled');
      return enabled;
    } catch (e) {
      _lastError = 'Error checking status: $e';
      debugPrint('[ScreenshotService] ❌ Error checking status: $e');
      debugPrint('[ScreenshotService] Returning cached value: $_screenshotsEnabled');
      return _screenshotsEnabled;
    }
  }

  /// Get debug info
  String getDebugInfo() {
    return '''
[ScreenshotService Debug Info]
- Initialized: $_isInitialized
- Screenshots Enabled: $_screenshotsEnabled
- Native Method Available: $_nativeMethodAvailable
- Last Error: $_lastError
''';
  }
}
