import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/likes/likes_screen.dart';
import '../screens/discovery/swipeable_discovery_screen.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Keep track of the home screen state to control tab switching
  static ValueNotifier<int> selectedTabNotifier = ValueNotifier<int>(0);

  /// Navigate to specific screen based on notification type
  static Future<void> navigateFromNotification(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] as String?;
    final screen = data['screen'] as String?;

    debugPrint('🧭 Navigating from notification - Type: $type, Screen: $screen');

    switch (type) {
      case 'message':
        await _navigateToChat(context, data);
        break;
      case 'match':
        await _navigateToMatches(context);
        break;
      case 'like':
        await _navigateToLikes(context);
        break;
      case 'super_like':
        await _navigateToLikes(context);
        break;
      default:
        // Default to home screen
        await _navigateToHome(context);
        break;
    }
  }

  /// Navigate to chat screen
  static Future<void> _navigateToChat(BuildContext context, Map<String, dynamic> data) async {
    final senderId = data['senderId'] as String?;
    final senderName = data['senderName'] as String?;
    final senderPhoto = data['senderPhoto'] as String?;
    final currentUserId = data['currentUserId'] as String?;

    if (senderId != null && senderName != null && currentUserId != null) {
      // First navigate to home and switch to chat tab
      await _navigateToHomeWithTab(context, 3); // Chat tab index
      
      // Then navigate to specific chat
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUserId: currentUserId,
            otherUserId: senderId,
            otherUserName: senderName,
            otherUserPhoto: senderPhoto,
          ),
        ),
      );
    } else {
      // Just go to chat tab if we don't have specific chat info
      await _navigateToHomeWithTab(context, 3);
    }
  }

  /// Navigate to matches screen
  static Future<void> _navigateToMatches(BuildContext context) async {
    await _navigateToHomeWithTab(context, 2); // Matches tab index
  }

  /// Navigate to likes screen
  static Future<void> _navigateToLikes(BuildContext context) async {
    await _navigateToHomeWithTab(context, 1); // Likes tab index
  }

  /// Navigate to discovery screen
  static Future<void> _navigateToDiscovery(BuildContext context) async {
    await _navigateToHomeWithTab(context, 0); // Discovery tab index
  }

  /// Navigate to home screen
  static Future<void> _navigateToHome(BuildContext context) async {
    await _navigateToHomeWithTab(context, 0);
  }

  /// Navigate to home screen with specific tab
  static Future<void> _navigateToHomeWithTab(BuildContext context, int tabIndex) async {
    // Update the selected tab
    selectedTabNotifier.value = tabIndex;

    // Navigate to home screen if not already there
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != '/home') {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  /// Get current context
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Show snackbar from anywhere in the app
  static void showSnackBar(String message, {bool isError = false}) {
    final context = currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Navigate to specific route
  static Future<void> navigateTo(String routeName, {Object? arguments}) async {
    await navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  /// Replace current route
  static Future<void> navigateAndReplace(String routeName, {Object? arguments}) async {
    await navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate and clear stack
  static Future<void> navigateAndClearStack(String routeName, {Object? arguments}) async {
    await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack() {
    navigatorKey.currentState?.pop();
  }
}
