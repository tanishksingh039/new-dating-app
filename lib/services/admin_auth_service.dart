import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Admin Authentication Service
/// Manages authentication for 4 unique admin accounts with session control
class AdminAuthService {
  static const String _sessionKey = 'admin_session';
  static const String _sessionTimeKey = 'admin_session_time';
  static const Duration _sessionTimeout = Duration(hours: 8);

  // Hardcoded admin credentials (plain text for development - should be encrypted in production)
  static final Map<String, String> _adminCredentials = {
    'admin_master': 'admin123',
    'admin_analytics': 'analytics123',
    'admin_support': 'support123',
    'admin_finance': 'finance123',
  };

  static final Map<String, String> _adminRoles = {
    'admin_master': 'Master Admin',
    'admin_analytics': 'Analytics Admin',
    'admin_support': 'Support Admin',
    'admin_finance': 'Finance Admin',
  };

  /// Hash password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Authenticate admin with username and password
  static Future<AdminSession?> authenticate(String username, String password) async {
    try {
      if (kDebugMode) {
        print('[AdminAuth] Attempting authentication for: $username');
      }

      // Check if credentials match
      if (kDebugMode) {
        print('[AdminAuth] Username: $username');
        print('[AdminAuth] Password entered: $password');
        print('[AdminAuth] Expected password: ${_adminCredentials[username]}');
        print('[AdminAuth] Available usernames: ${_adminCredentials.keys.toList()}');
      }
      
      if (_adminCredentials[username] != password) {
        if (kDebugMode) {
          print('[AdminAuth] Invalid credentials for: $username');
        }
        return null;
      }

      // Check if another session is active for this admin
      final prefs = await SharedPreferences.getInstance();
      final existingSession = prefs.getString('${_sessionKey}_$username');
      final existingTime = prefs.getInt('${_sessionTimeKey}_$username');
      
      if (existingSession != null && existingTime != null) {
        final sessionTime = DateTime.fromMillisecondsSinceEpoch(existingTime);
        if (DateTime.now().difference(sessionTime) < _sessionTimeout) {
          if (kDebugMode) {
            print('[AdminAuth] Active session exists for: $username');
          }
          // Return existing session
          return AdminSession(
            username: username,
            role: _adminRoles[username]!,
            loginTime: sessionTime,
            sessionToken: existingSession,
          );
        }
      }

      // Create new session
      final sessionToken = _generateSessionToken(username);
      final loginTime = DateTime.now();

      // Store session
      await prefs.setString('${_sessionKey}_$username', sessionToken);
      await prefs.setInt('${_sessionTimeKey}_$username', loginTime.millisecondsSinceEpoch);

      if (kDebugMode) {
        print('[AdminAuth] New session created for: $username');
      }

      return AdminSession(
        username: username,
        role: _adminRoles[username]!,
        loginTime: loginTime,
        sessionToken: sessionToken,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AdminAuth] Authentication error: $e');
      }
      return null;
    }
  }

  /// Generate unique session token
  static String _generateSessionToken(String username) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$username:$timestamp:${DateTime.now().microsecond}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if current session is valid
  static Future<AdminSession?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check all admin sessions
      for (final username in _adminCredentials.keys) {
        final sessionToken = prefs.getString('${_sessionKey}_$username');
        final sessionTime = prefs.getInt('${_sessionTimeKey}_$username');
        
        if (sessionToken != null && sessionTime != null) {
          final loginTime = DateTime.fromMillisecondsSinceEpoch(sessionTime);
          
          // Check if session is still valid
          if (DateTime.now().difference(loginTime) < _sessionTimeout) {
            return AdminSession(
              username: username,
              role: _adminRoles[username]!,
              loginTime: loginTime,
              sessionToken: sessionToken,
            );
          } else {
            // Session expired, clean up
            await _clearSession(username);
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[AdminAuth] Error checking session: $e');
      }
      return null;
    }
  }

  /// Logout admin and clear session
  static Future<void> logout(String username) async {
    try {
      await _clearSession(username);
      if (kDebugMode) {
        print('[AdminAuth] Logged out: $username');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AdminAuth] Logout error: $e');
      }
    }
  }

  /// Clear session data for specific admin
  static Future<void> _clearSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_sessionKey}_$username');
    await prefs.remove('${_sessionTimeKey}_$username');
  }

  /// Clear all admin sessions (for security)
  static Future<void> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final username in _adminCredentials.keys) {
        await _clearSession(username);
      }
      
      if (kDebugMode) {
        print('[AdminAuth] All sessions cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AdminAuth] Error clearing sessions: $e');
      }
    }
  }

  /// Get all admin usernames (for UI purposes)
  static List<String> getAdminUsernames() {
    return _adminCredentials.keys.toList();
  }

  /// Check if username exists
  static bool isValidUsername(String username) {
    return _adminCredentials.containsKey(username);
  }

  /// Get admin role by username
  static String? getAdminRole(String username) {
    return _adminRoles[username];
  }

}

/// Admin Session Model
class AdminSession {
  final String username;
  final String role;
  final DateTime loginTime;
  final String sessionToken;

  AdminSession({
    required this.username,
    required this.role,
    required this.loginTime,
    required this.sessionToken,
  });

  /// Check if session is still valid
  bool get isValid {
    return DateTime.now().difference(loginTime) < AdminAuthService._sessionTimeout;
  }

  /// Get remaining session time
  Duration get remainingTime {
    final elapsed = DateTime.now().difference(loginTime);
    final remaining = AdminAuthService._sessionTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'role': role,
      'loginTime': loginTime.millisecondsSinceEpoch,
      'sessionToken': sessionToken,
    };
  }

  /// Create from map
  factory AdminSession.fromMap(Map<String, dynamic> map) {
    return AdminSession(
      username: map['username'],
      role: map['role'],
      loginTime: DateTime.fromMillisecondsSinceEpoch(map['loginTime']),
      sessionToken: map['sessionToken'],
    );
  }
}
