import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks message history for duplicate detection and rate limiting
class MessageTracking {
  final String userId;
  final String conversationId;
  final List<String> recentMessages; // Last 10 messages
  final List<int> messageQualities; // Quality scores
  final int hourlyMessageCount;
  final int hourlyImageCount;
  final DateTime lastMessageTime;
  final DateTime lastImageTime;
  final int dailyConversationCount;

  MessageTracking({
    required this.userId,
    required this.conversationId,
    required this.recentMessages,
    required this.messageQualities,
    required this.hourlyMessageCount,
    required this.hourlyImageCount,
    required this.lastMessageTime,
    required this.lastImageTime,
    required this.dailyConversationCount,
  });

  factory MessageTracking.fromMap(Map<String, dynamic> map) {
    return MessageTracking(
      userId: map['userId'] ?? '',
      conversationId: map['conversationId'] ?? '',
      recentMessages: List<String>.from(map['recentMessages'] ?? []),
      messageQualities: List<int>.from(map['messageQualities'] ?? []),
      hourlyMessageCount: map['hourlyMessageCount'] ?? 0,
      hourlyImageCount: map['hourlyImageCount'] ?? 0,
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastImageTime: (map['lastImageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dailyConversationCount: map['dailyConversationCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'conversationId': conversationId,
      'recentMessages': recentMessages,
      'messageQualities': messageQualities,
      'hourlyMessageCount': hourlyMessageCount,
      'hourlyImageCount': hourlyImageCount,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastImageTime': Timestamp.fromDate(lastImageTime),
      'dailyConversationCount': dailyConversationCount,
    };
  }

  /// Check if user has exceeded hourly message limit
  bool hasExceededMessageLimit() {
    final now = DateTime.now();
    final hoursSinceLastMessage = now.difference(lastMessageTime).inHours;
    
    // Reset counter if more than 1 hour has passed
    if (hoursSinceLastMessage >= 1) {
      return false;
    }
    
    // Max 20 messages per hour per conversation
    return hourlyMessageCount >= 20;
  }

  /// Check if user has exceeded hourly image limit
  bool hasExceededImageLimit() {
    final now = DateTime.now();
    final hoursSinceLastImage = now.difference(lastImageTime).inHours;
    
    // Reset counter if more than 1 hour has passed
    if (hoursSinceLastImage >= 1) {
      return false;
    }
    
    // Max 5 images per hour per conversation
    return hourlyImageCount >= 5;
  }

  /// Check if message is being sent too quickly
  bool isTooQuick() {
    final now = DateTime.now();
    final secondsSinceLastMessage = now.difference(lastMessageTime).inSeconds;
    
    // Min 3 seconds between messages
    return secondsSinceLastMessage < 3;
  }
}

/// Rate limit configuration
class RateLimitConfig {
  static const int maxMessagesPerHour = 20;
  static const int maxImagesPerHour = 5;
  static const int minSecondsBetweenMessages = 3;
  static const int maxConversationsPerDay = 10;
  static const int maxRecentMessagesTracked = 10;
}
