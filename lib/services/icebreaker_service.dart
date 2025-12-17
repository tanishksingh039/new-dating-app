import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/icebreaker_model.dart';
import '../data/interest_based_icebreakers.dart';

/// Service for managing icebreaker prompts and questions
class IcebreakerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get a random icebreaker prompt for a match based on user interests
  /// Prioritizes prompts matching user's interests
  /// Excludes prompts already used in this match
  Future<IcebreakerPrompt?> getRandomPrompt({
    String? category,
    required String matchId,
    List<String>? userInterests,
  }) async {
    try {
      // Get all active prompts
      Query query = _firestore
          .collection('icebreaker_prompts')
          .where('isActive', isEqualTo: true);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      final snapshot = await query.get();
      
      // If user has interests, try to find matching prompts first
      if (userInterests != null && userInterests.isNotEmpty) {
        final interestBasedPrompts = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final relatedInterest = data['relatedInterest'] as String?;
          return relatedInterest != null && userInterests.contains(relatedInterest);
        }).toList();
        
        if (interestBasedPrompts.isNotEmpty) {
          debugPrint('[IcebreakerService] Found ${interestBasedPrompts.length} interest-based prompts');
          // Get prompts already used in this match
          final usedPrompts = await _getUsedPromptIds(matchId);
          
          // Filter out used prompts
          final availableInterestPrompts = interestBasedPrompts
              .where((doc) => !usedPrompts.contains(doc.id))
              .toList();
          
          if (availableInterestPrompts.isNotEmpty) {
            final randomDoc = availableInterestPrompts[Random().nextInt(availableInterestPrompts.length)];
            return IcebreakerPrompt.fromFirestore(randomDoc);
          }
        }
      }
      
      if (snapshot.docs.isEmpty) {
        debugPrint('[IcebreakerService] No prompts found');
        return null;
      }
      
      // Get prompts already used in this match
      final usedPrompts = await _getUsedPromptIds(matchId);
      
      // Filter out used prompts
      final availablePrompts = snapshot.docs
          .where((doc) => !usedPrompts.contains(doc.id))
          .toList();
      
      if (availablePrompts.isEmpty) {
        debugPrint('[IcebreakerService] All prompts used, resetting...');
        // If all prompts used, pick from all prompts
        final allPrompts = snapshot.docs;
        final randomDoc = allPrompts[Random().nextInt(allPrompts.length)];
        return IcebreakerPrompt.fromFirestore(randomDoc);
      }
      
      // Sort by priority (higher priority = more likely to be shown)
      availablePrompts.sort((a, b) {
        final aPriority = (a.data() as Map<String, dynamic>)['priority'] ?? 1;
        final bPriority = (b.data() as Map<String, dynamic>)['priority'] ?? 1;
        return bPriority.compareTo(aPriority);
      });
      
      // Use weighted random selection based on priority
      final randomPrompt = _weightedRandomSelection(availablePrompts);
      return IcebreakerPrompt.fromFirestore(randomPrompt);
    } catch (e) {
      debugPrint('[IcebreakerService] Error getting random prompt: $e');
      return null;
    }
  }
  
  /// Get prompts by category
  Future<List<IcebreakerPrompt>> getPromptsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('icebreaker_prompts')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => IcebreakerPrompt.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[IcebreakerService] Error getting prompts by category: $e');
      return [];
    }
  }
  
  /// Get all active categories with at least one prompt
  Future<List<String>> getActiveCategories() async {
    try {
      final snapshot = await _firestore
          .collection('icebreaker_prompts')
          .where('isActive', isEqualTo: true)
          .get();
      
      final categories = snapshot.docs
          .map((doc) => (doc.data())['category'] as String?)
          .where((category) => category != null)
          .toSet()
          .toList();
      
      return categories.cast<String>();
    } catch (e) {
      debugPrint('[IcebreakerService] Error getting active categories: $e');
      return [];
    }
  }
  
  /// Record icebreaker usage
  Future<void> recordUsage({
    required String matchId,
    required String promptId,
    required String question,
    required String senderId,
  }) async {
    try {
      final usage = IcebreakerUsage(
        matchId: matchId,
        promptId: promptId,
        question: question,
        senderId: senderId,
        usedAt: DateTime.now(),
      );
      
      await _firestore
          .collection('icebreaker_usage')
          .add(usage.toFirestore());
      
      debugPrint('[IcebreakerService] ✅ Icebreaker usage recorded');
    } catch (e) {
      debugPrint('[IcebreakerService] ❌ Error recording usage: $e');
    }
  }
  
  /// Get prompt IDs already used in a match
  Future<Set<String>> _getUsedPromptIds(String matchId) async {
    try {
      final snapshot = await _firestore
          .collection('icebreaker_usage')
          .where('matchId', isEqualTo: matchId)
          .get();
      
      return snapshot.docs
          .map((doc) => (doc.data())['promptId'] as String?)
          .where((id) => id != null)
          .toSet()
          .cast<String>();
    } catch (e) {
      debugPrint('[IcebreakerService] Error getting used prompts: $e');
      return {};
    }
  }
  
  /// Weighted random selection based on priority
  DocumentSnapshot _weightedRandomSelection(List<QueryDocumentSnapshot> prompts) {
    if (prompts.length == 1) return prompts[0];
    
    // Calculate total weight
    int totalWeight = 0;
    for (var prompt in prompts) {
      final priority = ((prompt.data() as Map<String, dynamic>)['priority'] ?? 1) as int;
      totalWeight += priority;
    }
    
    // Random selection based on weight
    int randomValue = Random().nextInt(totalWeight);
    int currentWeight = 0;
    
    for (var prompt in prompts) {
      final priority = ((prompt.data() as Map<String, dynamic>)['priority'] ?? 1) as int;
      currentWeight += priority;
      if (randomValue < currentWeight) {
        return prompt;
      }
    }
    
    return prompts.last; // Fallback
  }
  
  /// Get icebreaker statistics for analytics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final promptsSnapshot = await _firestore
          .collection('icebreaker_prompts')
          .where('isActive', isEqualTo: true)
          .get();
      
      final usageSnapshot = await _firestore
          .collection('icebreaker_usage')
          .get();
      
      // Calculate usage per prompt
      Map<String, int> usagePerPrompt = {};
      for (var doc in usageSnapshot.docs) {
        final promptId = (doc.data())['promptId'] as String?;
        if (promptId != null) {
          usagePerPrompt[promptId] = (usagePerPrompt[promptId] ?? 0) + 1;
        }
      }
      
      return {
        'totalPrompts': promptsSnapshot.docs.length,
        'totalUsage': usageSnapshot.docs.length,
        'usagePerPrompt': usagePerPrompt,
        'averageUsagePerPrompt': usageSnapshot.docs.length / 
            (promptsSnapshot.docs.length > 0 ? promptsSnapshot.docs.length : 1),
      };
    } catch (e) {
      debugPrint('[IcebreakerService] Error getting statistics: $e');
      return {};
    }
  }
  
  /// Initialize default icebreaker prompts (call once during setup)
  Future<void> initializeDefaultPrompts() async {
    try {
      // Check if prompts already exist
      final existing = await _firestore
          .collection('icebreaker_prompts')
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        debugPrint('[IcebreakerService] Prompts already initialized');
        return;
      }
      
      debugPrint('[IcebreakerService] Initializing default prompts...');
      
      final defaultPrompts = _getDefaultPrompts();
      final batch = _firestore.batch();
      
      for (var prompt in defaultPrompts) {
        final docRef = _firestore.collection('icebreaker_prompts').doc();
        batch.set(docRef, prompt.toFirestore());
      }
      
      await batch.commit();
      debugPrint('[IcebreakerService] ✅ ${defaultPrompts.length} default prompts initialized');
    } catch (e) {
      debugPrint('[IcebreakerService] ❌ Error initializing prompts: $e');
    }
  }
  
  /// Get default icebreaker prompts
  List<IcebreakerPrompt> _getDefaultPrompts() {
    final now = DateTime.now();
    final prompts = <IcebreakerPrompt>[];
    
    // Add interest-based prompts (100+ questions)
    prompts.addAll(InterestBasedIcebreakers.getAllInterestBasedPrompts());
    
    // Add general prompts
    prompts.addAll([
      // This or That (Quick & Easy)
      IcebreakerPrompt(
        id: 'tot_1',
        question: 'Coffee date ☕ or movie night 🎬?',
        category: IcebreakerCategory.thisOrThat,
        quickReplies: ['Coffee date ☕', 'Movie night 🎬', 'Both sound great!'],
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'tot_2',
        question: 'Beach vacation 🏖️ or mountain trip 🏔️?',
        category: IcebreakerCategory.thisOrThat,
        quickReplies: ['Beach vacation 🏖️', 'Mountain trip 🏔️', 'I love both!'],
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'tot_3',
        question: 'Early bird 🌅 or night owl 🌙?',
        category: IcebreakerCategory.thisOrThat,
        quickReplies: ['Early bird 🌅', 'Night owl 🌙', 'Depends on the day'],
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'tot_4',
        question: 'Texting 📱 or calling 📞?',
        category: IcebreakerCategory.thisOrThat,
        quickReplies: ['Texting 📱', 'Calling 📞', 'Video calls 📹'],
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'tot_5',
        question: 'Netflix binge 📺 or reading a book 📚?',
        category: IcebreakerCategory.thisOrThat,
        quickReplies: ['Netflix binge 📺', 'Reading a book 📚', 'Both!'],
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Fun & Light
      IcebreakerPrompt(
        id: 'fun_1',
        question: 'What\'s your comfort food at 2 AM? 🍕',
        category: IcebreakerCategory.funAndLight,
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'fun_2',
        question: 'What\'s your go-to karaoke song? 🎤',
        category: IcebreakerCategory.funAndLight,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'fun_3',
        question: 'If you could have any superpower, what would it be? 🦸',
        category: IcebreakerCategory.funAndLight,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'fun_4',
        question: 'What\'s the most spontaneous thing you\'ve ever done? ✨',
        category: IcebreakerCategory.funAndLight,
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'fun_5',
        question: 'What\'s your favorite way to spend a lazy Sunday? 😌',
        category: IcebreakerCategory.funAndLight,
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Preferences
      IcebreakerPrompt(
        id: 'pref_1',
        question: 'What\'s your ideal weekend? 🌟',
        category: IcebreakerCategory.preferences,
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'pref_2',
        question: 'What\'s one thing you can talk about for hours? 💬',
        category: IcebreakerCategory.preferences,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'pref_3',
        question: 'What\'s your favorite type of music? 🎵',
        category: IcebreakerCategory.preferences,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'pref_4',
        question: 'What\'s your dream travel destination? ✈️',
        category: IcebreakerCategory.preferences,
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'pref_5',
        question: 'What\'s your favorite way to unwind after a long day? 🧘',
        category: IcebreakerCategory.preferences,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Hypotheticals
      IcebreakerPrompt(
        id: 'hypo_1',
        question: 'If you could live in any era, which would you choose? ⏰',
        category: IcebreakerCategory.hypotheticals,
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'hypo_2',
        question: 'If you won the lottery tomorrow, what\'s the first thing you\'d do? 💰',
        category: IcebreakerCategory.hypotheticals,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'hypo_3',
        question: 'If you could have dinner with anyone (dead or alive), who would it be? 🍽️',
        category: IcebreakerCategory.hypotheticals,
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'hypo_4',
        question: 'If you could master any skill instantly, what would it be? 🎯',
        category: IcebreakerCategory.hypotheticals,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Flirty but Safe
      IcebreakerPrompt(
        id: 'flirt_1',
        question: 'What\'s your idea of a perfect first date? 💕',
        category: IcebreakerCategory.flirtyButSafe,
        priority: 5,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'flirt_2',
        question: 'What\'s something that always makes you smile? 😊',
        category: IcebreakerCategory.flirtyButSafe,
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'flirt_3',
        question: 'What\'s your love language? 💖',
        category: IcebreakerCategory.flirtyButSafe,
        quickReplies: ['Words of affirmation', 'Quality time', 'Physical touch', 'Acts of service', 'Gifts'],
        priority: 4,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'flirt_4',
        question: 'What\'s the most romantic thing someone has done for you? 🌹',
        category: IcebreakerCategory.flirtyButSafe,
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Deeper Questions
      IcebreakerPrompt(
        id: 'deep_1',
        question: 'What\'s something you\'re really passionate about? 🔥',
        category: IcebreakerCategory.deeperQuestions,
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'deep_2',
        question: 'What\'s a goal you\'re currently working towards? 🎯',
        category: IcebreakerCategory.deeperQuestions,
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'deep_3',
        question: 'What\'s the best advice you\'ve ever received? 💡',
        category: IcebreakerCategory.deeperQuestions,
        priority: 2,
        createdAt: now,
        updatedAt: now,
      ),
      IcebreakerPrompt(
        id: 'deep_4',
        question: 'What\'s something you\'ve always wanted to learn? 📖',
        category: IcebreakerCategory.deeperQuestions,
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    
    return prompts;
  }
}
