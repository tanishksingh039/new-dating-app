import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/icebreaker_service.dart';
import '../models/icebreaker_model.dart';

/// Simplified icebreaker widget - shows questions only, sends directly to chat
class IcebreakerSelectionWidget extends StatefulWidget {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final Function(String question) onQuestionSelected;

  const IcebreakerSelectionWidget({
    Key? key,
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.onQuestionSelected,
  }) : super(key: key);

  @override
  State<IcebreakerSelectionWidget> createState() =>
      _IcebreakerSelectionWidgetState();
}

class _IcebreakerSelectionWidgetState
    extends State<IcebreakerSelectionWidget> {
  final IcebreakerService _icebreakerService = IcebreakerService();
  
  IcebreakerPrompt? _currentPrompt;
  bool _isLoading = true;
  List<String> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }
  
  Future<void> _loadUserInterests() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        final interests = userData?['interests'] as List<dynamic>?;
        setState(() {
          _userInterests = interests?.cast<String>() ?? [];
        });
        debugPrint('[IcebreakerWidget] Loaded ${_userInterests.length} user interests');
      }
    } catch (e) {
      debugPrint('[IcebreakerWidget] Error loading user interests: $e');
    }
    
    _loadRandomPrompt();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRandomPrompt() async {
    setState(() => _isLoading = true);
    
    final prompt = await _icebreakerService.getRandomPrompt(
      matchId: widget.matchId,
      userInterests: _userInterests.isNotEmpty ? _userInterests : null,
    );
    
    setState(() {
      _currentPrompt = prompt;
      _isLoading = false;
    });
  }

  void _sendQuestion() {
    if (_currentPrompt == null) return;
    
    // Record usage
    _icebreakerService.recordUsage(
      matchId: widget.matchId,
      promptId: _currentPrompt!.id,
      question: _currentPrompt!.question,
      senderId: widget.currentUserId,
    );
    
    // Send question directly to chat
    widget.onQuestionSelected(_currentPrompt!.question);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.pink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start with a Fun Question',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Break the ice with ${widget.otherUserName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.pink),
                onPressed: _isLoading ? null : _loadRandomPrompt,
                tooltip: 'Get another question',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Question Card
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            )
          else if (_currentPrompt != null)
            _buildQuestionCard()
          else
            _buildNoPromptsMessage(),

          const SizedBox(height: 16),

          // Action Buttons
          if (_currentPrompt != null && !_isLoading)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _sendQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Send Question',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.pink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category badge
          if (_currentPrompt!.relatedInterest != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPrompt!.relatedInterest} 💕',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Question - centered and prominent
          Text(
            _currentPrompt!.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Hint text
          Text(
            'This question will be sent to ${widget.otherUserName}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildNoPromptsMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No icebreaker questions available',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
