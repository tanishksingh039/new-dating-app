import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserRewardsStats {
  final String userId;
  final int totalScore;
  final int weeklyScore;
  final int monthlyScore;
  final int messagesSent;
  final int repliesGiven;
  final int imagesSent;
  final double positiveFeedbackRatio;
  final int currentStreak;
  final int longestStreak;
  final int weeklyRank;
  final int monthlyRank;
  final DateTime lastUpdated;

  UserRewardsStats({
    required this.userId,
    required this.totalScore,
    required this.weeklyScore,
    required this.monthlyScore,
    required this.messagesSent,
    required this.repliesGiven,
    required this.imagesSent,
    required this.positiveFeedbackRatio,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyRank,
    required this.monthlyRank,
    required this.lastUpdated,
  });

  factory UserRewardsStats.fromMap(Map<String, dynamic> map) {
    return UserRewardsStats(
      userId: map['userId'] ?? '',
      totalScore: map['totalScore'] ?? 0,
      weeklyScore: map['weeklyScore'] ?? 0,
      monthlyScore: map['monthlyScore'] ?? 0,
      messagesSent: map['messagesSent'] ?? 0,
      repliesGiven: map['repliesGiven'] ?? 0,
      imagesSent: map['imagesSent'] ?? 0,
      positiveFeedbackRatio: (map['positiveFeedbackRatio'] ?? 0.0).toDouble(),
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      weeklyRank: map['weeklyRank'] ?? 0,
      monthlyRank: map['monthlyRank'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalScore': totalScore,
      'weeklyScore': weeklyScore,
      'monthlyScore': monthlyScore,
      'messagesSent': messagesSent,
      'repliesGiven': repliesGiven,
      'imagesSent': imagesSent,
      'positiveFeedbackRatio': positiveFeedbackRatio,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'weeklyRank': weeklyRank,
      'monthlyRank': monthlyRank,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // For JSON encoding (used in SharedPreferences cache)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalScore': totalScore,
      'weeklyScore': weeklyScore,
      'monthlyScore': monthlyScore,
      'messagesSent': messagesSent,
      'repliesGiven': repliesGiven,
      'imagesSent': imagesSent,
      'positiveFeedbackRatio': positiveFeedbackRatio,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'weeklyRank': weeklyRank,
      'monthlyRank': monthlyRank,
      'lastUpdated': lastUpdated.toIso8601String(), // Convert to string for JSON
    };
  }

  // From JSON (used when loading from SharedPreferences cache)
  factory UserRewardsStats.fromJson(Map<String, dynamic> json) {
    return UserRewardsStats(
      userId: json['userId'] ?? '',
      totalScore: json['totalScore'] ?? 0,
      weeklyScore: json['weeklyScore'] ?? 0,
      monthlyScore: json['monthlyScore'] ?? 0,
      messagesSent: json['messagesSent'] ?? 0,
      repliesGiven: json['repliesGiven'] ?? 0,
      imagesSent: json['imagesSent'] ?? 0,
      positiveFeedbackRatio: (json['positiveFeedbackRatio'] ?? 0.0).toDouble(),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      weeklyRank: json['weeklyRank'] ?? 0,
      monthlyRank: json['monthlyRank'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? photoUrl;
  final int score;
  final int rank;
  final bool isVerified;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.score,
    required this.rank,
    this.isVerified = false,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      photoUrl: map['photoUrl'],
      score: map['score'] ?? 0,
      rank: map['rank'] ?? 0,
      isVerified: map['isVerified'] ?? false,
    );
  }
}

class RewardIncentive {
  final String id;
  final String title;
  final String description;
  final String type; // 'netflix', 'spotify', 'amazon', etc.
  final int requiredScore;
  final int requiredRank;
  final String imageUrl;
  final DateTime validUntil;
  final bool isActive;

  RewardIncentive({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.requiredScore,
    required this.requiredRank,
    required this.imageUrl,
    required this.validUntil,
    this.isActive = true,
  });

  factory RewardIncentive.fromMap(Map<String, dynamic> map) {
    return RewardIncentive(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      requiredScore: map['requiredScore'] ?? 0,
      requiredRank: map['requiredRank'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      validUntil: (map['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'requiredScore': requiredScore,
      'requiredRank': requiredRank,
      'imageUrl': imageUrl,
      'validUntil': Timestamp.fromDate(validUntil),
      'isActive': isActive,
    };
  }
}

class RewardHistory {
  final String id;
  final String userId;
  final String rewardTitle;
  final String rewardType;
  final DateTime wonDate;
  final bool claimed;
  final DateTime? claimedDate;
  final String? claimCode;

  RewardHistory({
    required this.id,
    required this.userId,
    required this.rewardTitle,
    required this.rewardType,
    required this.wonDate,
    this.claimed = false,
    this.claimedDate,
    this.claimCode,
  });

  factory RewardHistory.fromMap(Map<String, dynamic> map) {
    return RewardHistory(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      rewardTitle: map['rewardTitle'] ?? '',
      rewardType: map['rewardType'] ?? '',
      wonDate: (map['wonDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      claimed: map['claimed'] ?? false,
      claimedDate: (map['claimedDate'] as Timestamp?)?.toDate(),
      claimCode: map['claimCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'rewardTitle': rewardTitle,
      'rewardType': rewardType,
      'wonDate': Timestamp.fromDate(wonDate),
      'claimed': claimed,
      'claimedDate': claimedDate != null ? Timestamp.fromDate(claimedDate!) : null,
      'claimCode': claimCode,
    };
  }
}

class ScoringRules {
  static const int messageSentPoints = 5;
  static const int replyGivenPoints = 10;
  static const int imageSentPoints = 30; // Updated: 30 points for sending image
  static const int positiveFeedbackPoints = 20;
  static const int dailyStreakBonus = 25; // Bonus for chatting daily with multiple people
  static const int weeklyStreakBonus = 100;
  
  // Streak bonus multipliers based on number of unique conversations per day
  static const int streakBonusPerConversation = 5; // 5 points per unique person chatted with
  static const int maxDailyConversationBonus = 50; // Max 50 points from conversations (10 people)
  
  static const int top1Reward = 1000;
  static const int top3Reward = 500;
  static const int top10Reward = 250;
}
