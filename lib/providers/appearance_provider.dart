import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode_enabled';
  bool _isDarkModeEnabled = false;
  bool _isLoading = true;

  AppearanceProvider() {
    debugPrint('AppearanceProvider: Initializing...');
    _loadDarkModePreference();
  }

  bool get isDarkModeEnabled => _isDarkModeEnabled;
  bool get isLoading => _isLoading;

  // Get background color based on dark mode setting
  Color get backgroundColor => _isDarkModeEnabled ? const Color(0xFF121212) : Colors.white;
  Color get cardBackgroundColor => _isDarkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white;
  Color get surfaceColor => _isDarkModeEnabled ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA);
  Color get textColor => _isDarkModeEnabled ? Colors.white : Colors.black;
  Color get secondaryTextColor => _isDarkModeEnabled ? Colors.white70 : Colors.grey[600]!;

  Future<void> _loadDarkModePreference() async {
    debugPrint('AppearanceProvider: Loading dark mode preference...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDarkMode = prefs.getBool(_darkModeKey);
      debugPrint('AppearanceProvider: Saved dark mode from preferences: $savedDarkMode');
      
      if (savedDarkMode != null) {
        _isDarkModeEnabled = savedDarkMode;
        debugPrint('AppearanceProvider: Set dark mode to: $_isDarkModeEnabled');
      } else {
        debugPrint('AppearanceProvider: No saved preference, using default light mode');
      }
    } catch (e) {
      debugPrint('AppearanceProvider: Error loading dark mode preference: $e');
    } finally {
      _isLoading = false;
      debugPrint('AppearanceProvider: Finished loading, notifying listeners');
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode() async {
    debugPrint('AppearanceProvider: Toggling dark mode from $_isDarkModeEnabled');
    _isDarkModeEnabled = !_isDarkModeEnabled;
    debugPrint('AppearanceProvider: New dark mode state: $_isDarkModeEnabled');
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkModeEnabled);
      debugPrint('AppearanceProvider: Successfully saved dark mode preference');
    } catch (e) {
      debugPrint('AppearanceProvider: Error saving dark mode preference: $e');
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    debugPrint('AppearanceProvider: Setting dark mode to: $enabled');
    _isDarkModeEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, enabled);
      debugPrint('AppearanceProvider: Successfully saved dark mode preference');
    } catch (e) {
      debugPrint('AppearanceProvider: Error saving dark mode preference: $e');
    }
  }
}
