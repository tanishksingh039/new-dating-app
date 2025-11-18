import 'package:flutter/foundation.dart';

/// Free, client-side message content analyzer
/// No external APIs needed - completely free!
class MessageContentAnalyzer {
  // Spam/gibberish detection patterns
  static final List<RegExp> _gibberishPatterns = [
    RegExp(r'^[a-z]{1,2}$', caseSensitive: false), // Single/double letters
    RegExp(r'(.)\1{4,}'), // Repeated characters (aaaaa, 11111)
    RegExp(r'^[^aeiouAEIOU\s]{5,}$'), // No vowels (consonant spam)
    RegExp(r'^[0-9]+$'), // Only numbers
    RegExp(r'^[!@#%^&*()_+=\[\]{};:,.<>?/\\|`~\-]{3,}$'), // Only symbols
  ];

  // Common spam/test words
  static final Set<String> _spamWords = {
    'test', 'testing', 'asdf', 'qwerty', 'zzz', 'aaa', 'bbb', 'ccc',
    'ddd', 'eee', 'fff', 'ggg', 'hhh', 'iii', 'jjj', 'kkk', 'lll',
    'mmm', 'nnn', 'ooo', 'ppp', 'qqq', 'rrr', 'sss', 'ttt', 'uuu',
    'vvv', 'www', 'xxx', 'yyy', 'zzz', '123', '111', '222', '333',
    '444', '555', '666', '777', '888', '999', '000', 'lol', 'lmao',
  };

  // Meaningful conversation indicators
  static final List<RegExp> _meaningfulPatterns = [
    RegExp(r'\b(how|what|when|where|why|who)\b', caseSensitive: false),
    RegExp(r'\b(like|love|enjoy|prefer|favorite)\b', caseSensitive: false),
    RegExp(r'\b(think|feel|believe|opinion)\b', caseSensitive: false),
    RegExp(r'\b(hello|hi|hey|good morning|good evening)\b', caseSensitive: false),
    RegExp(r'\b(thanks|thank you|appreciate)\b', caseSensitive: false),
    RegExp(r'\b(sorry|apologize|excuse me)\b', caseSensitive: false),
  ];

  // Emoji patterns (indicate engagement)
  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
    unicode: true,
  );

  /// Analyze message quality and return quality score (0-100)
  static MessageQuality analyzeMessage(String message) {
    if (message.trim().isEmpty) {
      return MessageQuality(
        score: 0,
        isGibberish: true,
        isSpam: true,
        isMeaningful: false,
        reason: 'Empty message',
      );
    }

    final trimmed = message.trim();
    final wordCount = trimmed.split(RegExp(r'\s+')).length;
    final charCount = trimmed.length;

    // Check for gibberish patterns
    for (var pattern in _gibberishPatterns) {
      if (pattern.hasMatch(trimmed)) {
        debugPrint('❌ Gibberish detected: $trimmed');
        return MessageQuality(
          score: 0,
          isGibberish: true,
          isSpam: true,
          isMeaningful: false,
          reason: 'Gibberish pattern detected',
        );
      }
    }

    // Check for spam words
    final lowerMessage = trimmed.toLowerCase();
    if (_spamWords.contains(lowerMessage)) {
      debugPrint('❌ Spam word detected: $trimmed');
      return MessageQuality(
        score: 0,
        isGibberish: true,
        isSpam: true,
        isMeaningful: false,
        reason: 'Spam word detected',
      );
    }

    // Too short (less than 2 characters)
    if (charCount < 2) {
      return MessageQuality(
        score: 10,
        isGibberish: false,
        isSpam: false,
        isMeaningful: false,
        reason: 'Too short',
      );
    }

    // Calculate base score
    int score = 50; // Start at 50

    // Length bonus (up to 20 points)
    if (charCount >= 10) score += 10;
    if (charCount >= 30) score += 10;

    // Word count bonus (up to 15 points)
    if (wordCount >= 3) score += 5;
    if (wordCount >= 5) score += 5;
    if (wordCount >= 8) score += 5;

    // Meaningful pattern bonus (up to 15 points)
    int meaningfulMatches = 0;
    for (var pattern in _meaningfulPatterns) {
      if (pattern.hasMatch(lowerMessage)) {
        meaningfulMatches++;
      }
    }
    score += meaningfulMatches * 5;
    if (score > 100) score = 100;

    // Emoji bonus (shows engagement)
    if (_emojiPattern.hasMatch(trimmed)) {
      score = (score * 1.1).toInt(); // 10% bonus
      if (score > 100) score = 100;
    }

    // Determine if meaningful
    final isMeaningful = score >= 60 || meaningfulMatches > 0;

    debugPrint('✅ Message quality: $score - "${trimmed.substring(0, trimmed.length > 20 ? 20 : trimmed.length)}..."');

    return MessageQuality(
      score: score,
      isGibberish: false,
      isSpam: false,
      isMeaningful: isMeaningful,
      reason: 'Quality score: $score',
    );
  }

  /// Check if message is a duplicate or near-duplicate
  static bool isDuplicate(String message, List<String> recentMessages) {
    final trimmed = message.trim().toLowerCase();
    
    for (var recent in recentMessages) {
      final recentTrimmed = recent.trim().toLowerCase();
      
      // Exact match
      if (trimmed == recentTrimmed) {
        debugPrint('❌ Duplicate message detected');
        return true;
      }
      
      // Very similar (80% match)
      if (_isSimilar(trimmed, recentTrimmed)) {
        debugPrint('❌ Similar message detected');
        return true;
      }
    }
    
    return false;
  }

  /// Simple similarity check (free alternative to Levenshtein)
  static bool _isSimilar(String s1, String s2) {
    if (s1.length < 5 || s2.length < 5) return false;
    
    // Check if 80% of characters match
    int matches = 0;
    final minLength = s1.length < s2.length ? s1.length : s2.length;
    
    for (int i = 0; i < minLength; i++) {
      if (s1[i] == s2[i]) matches++;
    }
    
    return (matches / minLength) > 0.8;
  }

  /// Analyze conversation quality between two users
  static ConversationQuality analyzeConversation({
    required int messageCount,
    required int replyCount,
    required int imageCount,
    required Duration conversationDuration,
    required List<int> messageQualities,
  }) {
    if (messageCount == 0) {
      return ConversationQuality(
        score: 0,
        isGenuine: false,
        engagementLevel: 'none',
        reason: 'No messages',
      );
    }

    // Calculate average message quality
    final avgQuality = messageQualities.isEmpty
        ? 0
        : messageQualities.reduce((a, b) => a + b) / messageQualities.length;

    // Check for rapid-fire spam (too many messages too quickly)
    final messagesPerMinute = messageCount / (conversationDuration.inSeconds / 60);
    if (messagesPerMinute > 10) {
      debugPrint('❌ Rapid-fire spam detected: $messagesPerMinute msg/min');
      return ConversationQuality(
        score: 0,
        isGenuine: false,
        engagementLevel: 'spam',
        reason: 'Too rapid messaging detected',
      );
    }

    // Calculate base score
    int score = 50;

    // Message quality bonus (up to 30 points)
    score += (avgQuality * 0.3).toInt();

    // Reply ratio bonus (up to 20 points)
    final replyRatio = messageCount > 0 ? replyCount / messageCount : 0;
    score += (replyRatio * 20).toInt();

    // Duration bonus (longer conversations = more genuine)
    if (conversationDuration.inMinutes >= 5) score += 10;
    if (conversationDuration.inMinutes >= 15) score += 10;

    // Image sharing bonus (shows engagement)
    if (imageCount > 0) score += 10;

    if (score > 100) score = 100;

    // Determine engagement level
    String engagementLevel;
    if (score >= 80) {
      engagementLevel = 'high';
    } else if (score >= 60) {
      engagementLevel = 'medium';
    } else if (score >= 40) {
      engagementLevel = 'low';
    } else {
      engagementLevel = 'minimal';
    }

    debugPrint('📊 Conversation quality: $score ($engagementLevel)');

    return ConversationQuality(
      score: score,
      isGenuine: score >= 50,
      engagementLevel: engagementLevel,
      reason: 'Conversation score: $score',
    );
  }

  /// Calculate points multiplier based on message quality
  static double getPointsMultiplier(int qualityScore) {
    if (qualityScore >= 80) return 1.5; // 50% bonus for high quality
    if (qualityScore >= 60) return 1.0; // Normal points
    if (qualityScore >= 40) return 0.5; // Half points for low quality
    return 0.0; // No points for very low quality
  }
}

/// Message quality result
class MessageQuality {
  final int score; // 0-100
  final bool isGibberish;
  final bool isSpam;
  final bool isMeaningful;
  final String reason;

  MessageQuality({
    required this.score,
    required this.isGibberish,
    required this.isSpam,
    required this.isMeaningful,
    required this.reason,
  });

  @override
  String toString() {
    return 'MessageQuality(score: $score, meaningful: $isMeaningful, reason: $reason)';
  }
}

/// Conversation quality result
class ConversationQuality {
  final int score; // 0-100
  final bool isGenuine;
  final String engagementLevel; // 'high', 'medium', 'low', 'minimal', 'spam'
  final String reason;

  ConversationQuality({
    required this.score,
    required this.isGenuine,
    required this.engagementLevel,
    required this.reason,
  });

  @override
  String toString() {
    return 'ConversationQuality(score: $score, genuine: $isGenuine, level: $engagementLevel)';
  }
}
