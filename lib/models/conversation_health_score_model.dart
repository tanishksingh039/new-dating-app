import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation Health Score (CHS) Model
/// Scores each conversation based on engagement metrics
class ConversationHealthScoreModel {
  final String conversationId;
  final String userId;
  final String otherUserId;
  
  // Component scores
  final int replySpeedScore; // 0-10 points (reply < 30 min = 10)
  final int messageLengthScore; // 0-5 points (avg > 6 words = 5)
  final int engagementScore; // 0-3 points (emojis/voice notes = 3)
  final int consistencyScore; // 0-5 points (daily 1+ message = 5)
  
  // Calculated scores
  final int totalCHS;
  final String healthStatus; // 'Hot 🔥' (>15), 'Warm 🌡️' (8-15), 'Cold ❄️' (<8)
  final int bonusPoints; // Points awarded based on CHS
  
  final DateTime lastUpdated;

  ConversationHealthScoreModel({
    required this.conversationId,
    required this.userId,
    required this.otherUserId,
    required this.replySpeedScore,
    required this.messageLengthScore,
    required this.engagementScore,
    required this.consistencyScore,
    required this.lastUpdated,
  })  : totalCHS = replySpeedScore + messageLengthScore + engagementScore + consistencyScore,
        healthStatus = _calculateHealthStatus(
          replySpeedScore + messageLengthScore + engagementScore + consistencyScore,
        ),
        bonusPoints = _calculateBonusPoints(
          replySpeedScore + messageLengthScore + engagementScore + consistencyScore,
        );

  /// Calculate health status based on total CHS
  static String _calculateHealthStatus(int score) {
    if (score > 15) return 'Hot 🔥';
    if (score >= 8) return 'Warm 🌡️';
    return 'Cold ❄️';
  }

  /// Calculate bonus points based on CHS
  static int _calculateBonusPoints(int score) {
    if (score > 15) return 25; // Hot conversation bonus
    if (score >= 8) return 15; // Warm conversation bonus
    return 5; // Cold conversation bonus
  }

  factory ConversationHealthScoreModel.fromMap(Map<String, dynamic> map) {
    return ConversationHealthScoreModel(
      conversationId: map['conversationId'] ?? '',
      userId: map['userId'] ?? '',
      otherUserId: map['otherUserId'] ?? '',
      replySpeedScore: map['replySpeedScore'] ?? 0,
      messageLengthScore: map['messageLengthScore'] ?? 0,
      engagementScore: map['engagementScore'] ?? 0,
      consistencyScore: map['consistencyScore'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'otherUserId': otherUserId,
      'replySpeedScore': replySpeedScore,
      'messageLengthScore': messageLengthScore,
      'engagementScore': engagementScore,
      'consistencyScore': consistencyScore,
      'totalCHS': totalCHS,
      'healthStatus': healthStatus,
      'bonusPoints': bonusPoints,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  @override
  String toString() {
    return 'CHS: $totalCHS ($healthStatus) | Speed: $replySpeedScore, Length: $messageLengthScore, Engagement: $engagementScore, Consistency: $consistencyScore | Bonus: +$bonusPoints pts';
  }
}
