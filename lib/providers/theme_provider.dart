import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  ThemeProvider() {
    debugPrint('ThemeProvider: Initializing...');
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoading => _isLoading;

  Future<void> _loadThemeMode() async {
    debugPrint('ThemeProvider: Loading theme mode...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      debugPrint('ThemeProvider: Saved theme from preferences: $savedTheme');
      
      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.light,
        );
        debugPrint('ThemeProvider: Set theme mode to: $_themeMode');
      } else {
        debugPrint('ThemeProvider: No saved theme, using default light mode');
      }
    } catch (e) {
      debugPrint('ThemeProvider: Error loading theme: $e');
    } finally {
      _isLoading = false;
      debugPrint('ThemeProvider: Finished loading, notifying listeners');
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    debugPrint('ThemeProvider: Setting theme mode to: $mode');
    _themeMode = mode;
    notifyListeners();
    debugPrint('ThemeProvider: Notified listeners of theme change');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
      debugPrint('ThemeProvider: Successfully saved theme to preferences');
    } catch (e) {
      debugPrint('ThemeProvider: Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    debugPrint('ThemeProvider: Toggling theme from $_themeMode');
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    debugPrint('ThemeProvider: New theme mode will be: $newMode');
    await setThemeMode(newMode);
  }
}
