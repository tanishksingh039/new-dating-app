import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'navigation_service.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notification permissions granted');
      } else {
        debugPrint('⚠️ Notification permissions denied');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // Save token to Firestore
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        _fcmToken = newToken;
        _saveFCMToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _initialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message received: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'New notification',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'campusbound_channel',
      'CampusBound Notifications',
      channelDescription: 'Notifications for matches, likes, and messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle message tap (when user taps notification)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    
    // Navigate to appropriate screen based on message data
    if (message.data.isNotEmpty) {
      NavigationService.navigateFromNotification(message.data);
    }
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.payload}');
    
    // Parse payload and navigate
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Parse JSON payload
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        NavigationService.navigateFromNotification(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
        // Fallback to simple string parsing if JSON fails
        final data = <String, dynamic>{};
        if (response.payload!.contains('like')) {
          data['type'] = 'like';
          data['screen'] = 'likes';
        } else if (response.payload!.contains('match')) {
          data['type'] = 'match';
          data['screen'] = 'matches';
        } else if (response.payload!.contains('message')) {
          data['type'] = 'message';
          data['screen'] = 'chat';
        }
        
        if (data.isNotEmpty) {
          NavigationService.navigateFromNotification(data);
        }
      }
    }
  }

  /// Send notification for new like
  Future<void> sendLikeNotification({
    required String targetUserId,
    required String likerName,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: targetUserId,
        title: '💕 New Like!',
        body: '$likerName liked you!',
        data: {
          'type': 'like',
          'screen': 'likes',
        },
      );
    } catch (e) {
      debugPrint('Error sending like notification: $e');
    }
  }

  /// Send notification for new match
  Future<void> sendMatchNotification({
    required String targetUserId,
    required String matchedUserName,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: targetUserId,
        title: '🎉 It\'s a Match!',
        body: 'You and $matchedUserName liked each other!',
        data: {
          'type': 'match',
          'screen': 'matches',
        },
      );
    } catch (e) {
      debugPrint('Error sending match notification: $e');
    }
  }

  /// Send notification for super like
  Future<void> sendSuperLikeNotification({
    required String targetUserId,
    required String likerName,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: targetUserId,
        title: '⭐ Super Like!',
        body: '$likerName super liked you!',
        data: {
          'type': 'super_like',
          'screen': 'likes',
        },
      );
    } catch (e) {
      debugPrint('Error sending super like notification: $e');
    }
  }

  /// Send notification for new message
  Future<void> sendMessageNotification({
    required String targetUserId,
    required String senderId,
    required String senderName,
    required String messagePreview,
    String? senderPhoto,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: targetUserId,
        title: '💬 $senderName',
        body: messagePreview,
        data: {
          'type': 'message',
          'screen': 'chat',
          'senderId': senderId,
          'senderName': senderName,
          'senderPhoto': senderPhoto ?? '',
          'currentUserId': targetUserId,
        },
      );
    } catch (e) {
      debugPrint('Error sending message notification: $e');
    }
  }

  /// Send notification to specific user
  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        debugPrint('⚠️ No FCM token found for user: $userId');
        return;
      }

      // Check notification settings
      final notifSettings = userDoc.data()?['notificationSettings'] as Map<String, dynamic>?;
      if (notifSettings != null) {
        final pushEnabled = notifSettings['pushEnabled'] ?? true;
        if (!pushEnabled) {
          debugPrint('⚠️ Push notifications disabled for user: $userId');
          return;
        }

        // Check specific notification type
        if (data != null && data['type'] != null) {
          final type = data['type'];
          if (type == 'like' && !(notifSettings['likeNotif'] ?? true)) return;
          if (type == 'match' && !(notifSettings['newMatchNotif'] ?? true)) return;
          if (type == 'message' && !(notifSettings['messageNotif'] ?? true)) return;
        }
      }

      // Create notification document in Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'fcmToken': fcmToken,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('✅ Notification queued for user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Test notification navigation (for development/testing)
  static void testNotificationNavigation(String type) {
    final data = <String, dynamic>{};
    
    switch (type) {
      case 'message':
        data.addAll({
          'type': 'message',
          'screen': 'chat',
          'senderId': 'test_sender',
          'senderName': 'Test User',
          'senderPhoto': '',
          'currentUserId': FirebaseAuth.instance.currentUser?.uid ?? '',
        });
        break;
      case 'like':
        data.addAll({
          'type': 'like',
          'screen': 'likes',
        });
        break;
      case 'match':
        data.addAll({
          'type': 'match',
          'screen': 'matches',
        });
        break;
      case 'super_like':
        data.addAll({
          'type': 'super_like',
          'screen': 'likes',
        });
        break;
    }
    
    if (data.isNotEmpty) {
      NavigationService.navigateFromNotification(data);
    }
  }

  /// Dispose
  void dispose() {
    // Clean up if needed
  }
}
