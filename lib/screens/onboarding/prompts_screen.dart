import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';

class PromptsScreen extends StatefulWidget {
  const PromptsScreen({super.key});

  @override
  State<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends State<PromptsScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  
  final List<String> _selectedPrompts = ['', '', ''];
  bool _isLoading = false;

  // Dating app prompts similar to Bumble/Hinge
  final List<String> _availablePrompts = [
    'My ideal first date would be...',
    'I\'m looking for someone who...',
    'My biggest turn-on is...',
    'I\'m weirdly attracted to...',
    'The way to my heart is...',
    'I\'m overly competitive about...',
    'My most irrational fear is...',
    'I\'m secretly really good at...',
    'My simple pleasures include...',
    'I want someone who...',
    'My love language is...',
    'I\'m the type of person who...',
    'My perfect Sunday involves...',
    'I\'m currently obsessed with...',
    'My greatest strength is...',
    'I\'m looking for...',
    'My friends would describe me as...',
    'I\'m passionate about...',
    'My guilty pleasure is...',
    'I can\'t live without...',
    'My dream vacation is...',
    'I\'m most proud of...',
    'My favorite way to relax is...',
    'I\'m attracted to people who...',
    'My biggest pet peeve is...',
  ];

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PromptsScreen] $message');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showPromptSelector(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Choose a prompt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 20),
            
            // Prompts List
            Expanded(
              child: ListView.builder(
                itemCount: _availablePrompts.length,
                itemBuilder: (context, promptIndex) {
                  final prompt = _availablePrompts[promptIndex];
                  final isSelected = _selectedPrompts.contains(prompt);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        prompt,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected 
                            ? AppConstants.textLight 
                            : AppConstants.textDark,
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(Icons.check, color: AppConstants.textLight)
                        : null,
                      onTap: isSelected ? null : () {
                        setState(() {
                          _selectedPrompts[index] = prompt;
                        });
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSelected 
                        ? AppConstants.backgroundColor
                        : Colors.transparent,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    // Check if at least 2 prompts are filled
    int filledPrompts = 0;
    for (int i = 0; i < 3; i++) {
      if (_selectedPrompts[i].isNotEmpty && _controllers[i].text.trim().isNotEmpty) {
        filledPrompts++;
      }
    }

    if (filledPrompts < 2) {
      _showSnackBar('Please complete at least 2 prompts', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Prepare prompts data
      List<Map<String, String>> promptsData = [];
      for (int i = 0; i < 3; i++) {
        if (_selectedPrompts[i].isNotEmpty && _controllers[i].text.trim().isNotEmpty) {
          promptsData.add({
            'prompt': _selectedPrompts[i],
            'answer': _controllers[i].text.trim(),
          });
        }
      }

      // Save prompts data
      await FirebaseServices.saveOnboardingStep(
        userId: user.uid,
        stepData: {
          'prompts': promptsData,
          'profileComplete': 45, // 45% complete
          'onboardingStep': 'prompts_completed',
        },
      );

      _log('Prompts saved successfully');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/photos');
      }
    } catch (e) {
      _log('Error saving prompts: $e');
      if (mounted) {
        _showSnackBar('Failed to save. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Show your personality',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Answer prompts to help others get to know you',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Prompts
                      ...List.generate(3, (index) => _buildPromptCard(index)),
                      
                      const SizedBox(height: 20),
                      
                      // Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Complete at least 2 prompts to continue. You can always add more later.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  text: 'Continue',
                  onPressed: _isLoading ? null : _continue,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.4, // 40% - Step 4 of 10
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '4/10',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(int index) {
    final hasPrompt = _selectedPrompts[index].isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt selector
          GestureDetector(
            onTap: () => _showPromptSelector(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasPrompt 
                  ? AppColors.primary.withOpacity(0.1)
                  : AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasPrompt 
                    ? AppColors.primary
                    : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasPrompt 
                        ? _selectedPrompts[index]
                        : 'Choose a prompt...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: hasPrompt ? FontWeight.w600 : FontWeight.normal,
                        color: hasPrompt 
                          ? AppColors.primary
                          : AppConstants.textGrey,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: hasPrompt 
                      ? AppColors.primary
                      : AppConstants.textGrey,
                  ),
                ],
              ),
            ),
          ),
          
          if (hasPrompt) ...[
            const SizedBox(height: 16),
            // Answer field
            TextFormField(
              controller: _controllers[index],
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Your answer...',
                filled: true,
                fillColor: AppConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
