import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for icebreaker prompts/questions
class IcebreakerPrompt {
  final String id;
  final String question;
  final String category;
  final List<String>? quickReplies; // Optional quick reply options
  final bool isActive;
  final int priority; // Higher priority = shown more often
  final String? relatedInterest; // Interest this question is related to (e.g., 'Travel', 'Music')
  final DateTime createdAt;
  final DateTime updatedAt;

  IcebreakerPrompt({
    required this.id,
    required this.question,
    required this.category,
    this.quickReplies,
    this.isActive = true,
    this.priority = 1,
    this.relatedInterest,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory IcebreakerPrompt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IcebreakerPrompt(
      id: doc.id,
      question: data['question'] ?? '',
      category: data['category'] ?? 'general',
      quickReplies: data['quickReplies'] != null
          ? List<String>.from(data['quickReplies'])
          : null,
      isActive: data['isActive'] ?? true,
      priority: data['priority'] ?? 1,
      relatedInterest: data['relatedInterest'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'category': category,
      'quickReplies': quickReplies,
      'isActive': isActive,
      'priority': priority,
      'relatedInterest': relatedInterest,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with method
  IcebreakerPrompt copyWith({
    String? id,
    String? question,
    String? category,
    List<String>? quickReplies,
    bool? isActive,
    int? priority,
    String? relatedInterest,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IcebreakerPrompt(
      id: id ?? this.id,
      question: question ?? this.question,
      category: category ?? this.category,
      quickReplies: quickReplies ?? this.quickReplies,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      relatedInterest: relatedInterest ?? this.relatedInterest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Categories for icebreaker prompts
class IcebreakerCategory {
  static const String funAndLight = 'fun_and_light';
  static const String preferences = 'preferences';
  static const String hypotheticals = 'hypotheticals';
  static const String flirtyButSafe = 'flirty_but_safe';
  static const String deeperQuestions = 'deeper_questions';
  static const String thisOrThat = 'this_or_that';

  static List<String> get all => [
        funAndLight,
        preferences,
        hypotheticals,
        flirtyButSafe,
        deeperQuestions,
        thisOrThat,
      ];

  static String getDisplayName(String category) {
    switch (category) {
      case funAndLight:
        return 'Fun & Light';
      case preferences:
        return 'Preferences';
      case hypotheticals:
        return 'Hypotheticals';
      case flirtyButSafe:
        return 'Flirty but Safe';
      case deeperQuestions:
        return 'Deeper Questions';
      case thisOrThat:
        return 'This or That';
      default:
        return 'General';
    }
  }

  static String getEmoji(String category) {
    switch (category) {
      case funAndLight:
        return '😄';
      case preferences:
        return '⭐';
      case hypotheticals:
        return '🤔';
      case flirtyButSafe:
        return '😊';
      case deeperQuestions:
        return '💭';
      case thisOrThat:
        return '🎯';
      default:
        return '💬';
    }
  }
}

/// Model for tracking icebreaker usage per match
class IcebreakerUsage {
  final String matchId;
  final String promptId;
  final String question;
  final String senderId;
  final DateTime usedAt;

  IcebreakerUsage({
    required this.matchId,
    required this.promptId,
    required this.question,
    required this.senderId,
    required this.usedAt,
  });

  /// Create from Firestore document
  factory IcebreakerUsage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IcebreakerUsage(
      matchId: data['matchId'] ?? '',
      promptId: data['promptId'] ?? '',
      question: data['question'] ?? '',
      senderId: data['senderId'] ?? '',
      usedAt: (data['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'promptId': promptId,
      'question': question,
      'senderId': senderId,
      'usedAt': Timestamp.fromDate(usedAt),
    };
  }
}
