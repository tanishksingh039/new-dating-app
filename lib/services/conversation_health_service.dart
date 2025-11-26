import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation_health_score_model.dart';

/// Service to calculate and manage Conversation Health Scores (CHS)
class ConversationHealthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ConversationHealthService] $message');
    }
  }

  /// Calculate Conversation Health Score for a specific conversation
  Future<ConversationHealthScoreModel> calculateCHS(
    String userId,
    String otherUserId,
    String conversationId,
  ) async {
    try {
      _log('🔍 Calculating CHS for conversation: $conversationId');

      // Get all messages in the conversation
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(100) // Last 100 messages
          .get();

      if (messagesSnapshot.docs.isEmpty) {
        _log('⚠️ No messages found in conversation');
        return ConversationHealthScoreModel(
          conversationId: conversationId,
          userId: userId,
          otherUserId: otherUserId,
          replySpeedScore: 0,
          messageLengthScore: 0,
          engagementScore: 0,
          consistencyScore: 0,
          lastUpdated: DateTime.now(),
        );
      }

      // Calculate component scores
      final replySpeedScore = _calculateReplySpeedScore(messagesSnapshot.docs, userId);
      final messageLengthScore = _calculateMessageLengthScore(messagesSnapshot.docs, userId);
      final engagementScore = _calculateEngagementScore(messagesSnapshot.docs, userId);
      final consistencyScore = await _calculateConsistencyScore(userId, otherUserId);

      _log('📊 CHS Components:');
      _log('  Reply Speed: $replySpeedScore/10');
      _log('  Message Length: $messageLengthScore/5');
      _log('  Engagement: $engagementScore/3');
      _log('  Consistency: $consistencyScore/5');

      final chs = ConversationHealthScoreModel(
        conversationId: conversationId,
        userId: userId,
        otherUserId: otherUserId,
        replySpeedScore: replySpeedScore,
        messageLengthScore: messageLengthScore,
        engagementScore: engagementScore,
        consistencyScore: consistencyScore,
        lastUpdated: DateTime.now(),
      );

      _log('✅ CHS Calculated: ${chs.totalCHS} (${chs.healthStatus}) | Bonus: +${chs.bonusPoints} pts');

      // Save CHS to Firestore
      await _saveCHS(chs);

      return chs;
    } catch (e) {
      _log('❌ Error calculating CHS: $e');
      rethrow;
    }
  }

  /// Calculate Reply Speed Score (0-10)
  /// Reply < 30 min = 10 points
  int _calculateReplySpeedScore(List<QueryDocumentSnapshot> messages, String userId) {
    if (messages.length < 2) return 0;

    int totalReplyTime = 0;
    int replyCount = 0;

    for (int i = 0; i < messages.length - 1; i++) {
      final currentMsg = messages[i];
      final nextMsg = messages[i + 1];

      final currentSenderId = currentMsg['senderId'];
      final nextSenderId = nextMsg['senderId'];

      // Check if this is a reply (different sender)
      if (currentSenderId != nextSenderId && nextSenderId == userId) {
        final currentTime = (currentMsg['timestamp'] as Timestamp?)?.toDate();
        final nextTime = (nextMsg['timestamp'] as Timestamp?)?.toDate();

        if (currentTime != null && nextTime != null) {
          final replyTime = currentTime.difference(nextTime).inMinutes.abs();
          totalReplyTime += replyTime;
          replyCount++;
        }
      }
    }

    if (replyCount == 0) return 0;

    final avgReplyTime = totalReplyTime ~/ replyCount;
    if (avgReplyTime < 30) return 10;
    if (avgReplyTime < 60) return 8;
    if (avgReplyTime < 120) return 5;
    return 2;
  }

  /// Calculate Message Length Score (0-5)
  /// Average message length > 6 words = 5 points
  int _calculateMessageLengthScore(List<QueryDocumentSnapshot> messages, String userId) {
    final userMessages = messages
        .where((msg) => msg['senderId'] == userId && msg['text'] != null)
        .toList();

    if (userMessages.isEmpty) return 0;

    int totalWords = 0;
    for (final msg in userMessages) {
      final text = msg['text'] as String? ?? '';
      final wordCount = text.split(RegExp(r'\s+')).length;
      totalWords += wordCount;
    }

    final avgLength = totalWords ~/ userMessages.length;
    if (avgLength > 6) return 5;
    if (avgLength > 4) return 3;
    if (avgLength > 2) return 1;
    return 0;
  }

  /// Calculate Engagement Score (0-3)
  /// Emojis or voice notes = 3 points
  int _calculateEngagementScore(List<QueryDocumentSnapshot> messages, String userId) {
    final userMessages = messages.where((msg) => msg['senderId'] == userId).toList();

    if (userMessages.isEmpty) return 0;

    int engagementCount = 0;

    for (final msg in userMessages) {
      final text = msg['text'] as String? ?? '';
      final hasEmoji = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(text);
      final hasVoiceNote = msg['audioUrl'] != null;

      if (hasEmoji || hasVoiceNote) {
        engagementCount++;
      }
    }

    // If 30%+ of messages have emojis/voice notes = 3 points
    final engagementPercentage = (engagementCount / userMessages.length) * 100;
    if (engagementPercentage >= 30) return 3;
    if (engagementPercentage >= 15) return 2;
    if (engagementPercentage >= 5) return 1;
    return 0;
  }

  /// Calculate Consistency Score (0-5)
  /// Daily 1+ message = 5 points
  Future<int> _calculateConsistencyScore(String userId, String otherUserId) async {
    try {
      final chatId = _getChatId(userId, otherUserId);
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      if (messagesSnapshot.docs.isEmpty) return 0;

      // Count unique days with messages
      final daysWithMessages = <String>{};
      for (final msg in messagesSnapshot.docs) {
        final timestamp = (msg['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          daysWithMessages.add(dateKey);
        }
      }

      // Score based on days with messages in last 7 days
      final daysCount = daysWithMessages.length;
      if (daysCount >= 6) return 5; // 6-7 days
      if (daysCount >= 4) return 4; // 4-5 days
      if (daysCount >= 2) return 3; // 2-3 days
      if (daysCount >= 1) return 1; // 1 day
      return 0;
    } catch (e) {
      _log('⚠️ Error calculating consistency: $e');
      return 0;
    }
  }

  /// Save CHS to Firestore
  Future<void> _saveCHS(ConversationHealthScoreModel chs) async {
    try {
      await _firestore
          .collection('conversation_health_scores')
          .doc('${chs.userId}_${chs.conversationId}')
          .set(chs.toMap());

      _log('💾 CHS saved to Firestore');
    } catch (e) {
      _log('❌ Error saving CHS: $e');
    }
  }

  /// Get CHS for a conversation
  Future<ConversationHealthScoreModel?> getCHS(
    String userId,
    String conversationId,
  ) async {
    try {
      final doc = await _firestore
          .collection('conversation_health_scores')
          .doc('${userId}_$conversationId')
          .get();

      if (doc.exists) {
        return ConversationHealthScoreModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _log('❌ Error getting CHS: $e');
      return null;
    }
  }

  /// Get all CHS for a user
  Future<List<ConversationHealthScoreModel>> getAllCHSForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('conversation_health_scores')
          .where('userId', isEqualTo: userId)
          .orderBy('totalCHS', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConversationHealthScoreModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _log('❌ Error getting user CHS: $e');
      return [];
    }
  }

  /// Get hot conversations (CHS > 15)
  Future<List<ConversationHealthScoreModel>> getHotConversations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('conversation_health_scores')
          .where('userId', isEqualTo: userId)
          .where('totalCHS', isGreaterThan: 15)
          .orderBy('totalCHS', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConversationHealthScoreModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _log('❌ Error getting hot conversations: $e');
      return [];
    }
  }

  /// Helper to get chat ID
  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 ? '${userId1}_$userId2' : '${userId2}_$userId1';
  }
}
