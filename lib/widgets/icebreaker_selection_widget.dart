import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/icebreaker_model.dart';
import '../services/icebreaker_service.dart';

/// Widget for selecting and answering icebreaker prompts
class IcebreakerSelectionWidget extends StatefulWidget {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final Function(String question, String? answer) onAnswerSubmitted;

  const IcebreakerSelectionWidget({
    Key? key,
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.onAnswerSubmitted,
  }) : super(key: key);

  @override
  State<IcebreakerSelectionWidget> createState() =>
      _IcebreakerSelectionWidgetState();
}

class _IcebreakerSelectionWidgetState
    extends State<IcebreakerSelectionWidget> {
  final IcebreakerService _icebreakerService = IcebreakerService();
  final TextEditingController _customAnswerController = TextEditingController();
  
  IcebreakerPrompt? _currentPrompt;
  bool _isLoading = true;
  bool _showCustomAnswer = false;
  String? _selectedQuickReply;
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
    _customAnswerController.dispose();
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

  Future<void> _submitAnswer() async {
    if (_currentPrompt == null) return;

    String? answer;
    if (_showCustomAnswer) {
      answer = _customAnswerController.text.trim();
      if (answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your answer'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      answer = _selectedQuickReply;
      if (answer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an answer'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Record usage
    await _icebreakerService.recordUsage(
      matchId: widget.matchId,
      promptId: _currentPrompt!.id,
      question: _currentPrompt!.question,
      selectedReply: _showCustomAnswer ? null : answer,
      customReply: _showCustomAnswer ? answer : null,
      senderId: widget.currentUserId,
    );

    // Call callback with question and answer
    widget.onAnswerSubmitted(_currentPrompt!.question, answer);
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
                    onPressed: _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Send Answer',
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
    final hasQuickReplies = _currentPrompt!.quickReplies?.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${IcebreakerCategory.getEmoji(_currentPrompt!.category)} ${IcebreakerCategory.getDisplayName(_currentPrompt!.category)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.pink,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Question
          Text(
            _currentPrompt!.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Quick replies or custom answer
          if (hasQuickReplies && !_showCustomAnswer)
            _buildQuickReplies()
          else
            _buildCustomAnswerField(),

          // Toggle custom answer
          if (hasQuickReplies)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showCustomAnswer = !_showCustomAnswer;
                  _selectedQuickReply = null;
                  _customAnswerController.clear();
                });
              },
              icon: Icon(
                _showCustomAnswer ? Icons.list : Icons.edit,
                size: 16,
                color: Colors.pink,
              ),
              label: Text(
                _showCustomAnswer ? 'Choose from options' : 'Write custom answer',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.pink,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _currentPrompt!.quickReplies!.map((reply) {
        final isSelected = _selectedQuickReply == reply;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedQuickReply = reply;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.pink : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.pink : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Text(
              reply,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomAnswerField() {
    return TextField(
      controller: _customAnswerController,
      maxLines: 3,
      maxLength: 200,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.pink, width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
      style: const TextStyle(fontSize: 14),
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
