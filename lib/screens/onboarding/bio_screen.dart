import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';

class BioScreen extends StatefulWidget {
  const BioScreen({super.key});

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen> {
  final _bioController = TextEditingController();
  bool _isLoading = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[BioScreen] $message');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final bio = _bioController.text.trim();

    // Bio is optional, but if provided, validate it
    if (bio.isNotEmpty) {
      final validation = AppConstants.validateBio(bio);
      if (validation != null) {
        _showSnackBar(validation, Colors.orange);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');

      await FirebaseServices.updateUserProfile(user.uid, {
        'bio': bio.isEmpty ? '' : bio,
        'profileComplete': 80, // 80% complete
      });

      _log('Bio saved successfully');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/preferences');
      }
    } catch (e) {
      _log('Error saving bio: $e');
      if (mounted) {
        _showSnackBar('Failed to save. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/onboarding/preferences');
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
          gradient: AppConstants.primaryGradient,
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
                        'About you',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tell others about yourself',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Bio Input Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                            const Text(
                              'Write something about yourself',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _bioController,
                              maxLines: 8,
                              maxLength: AppConstants.maxBioLength,
                              decoration: InputDecoration(
                                hintText:
                                    'I love traveling, coffee, and meeting new people...',
                                filled: true,
                                fillColor: AppConstants.backgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                counterText: '',
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Character Count
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _bioController.text.length >= AppConstants.minBioLength
                                      ? 'Great! ✨'
                                      : 'Min ${AppConstants.minBioLength} characters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _bioController.text.length >= AppConstants.minBioLength
                                        ? AppConstants.successColor
                                        : AppConstants.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_bioController.text.length}/${AppConstants.maxBioLength}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppConstants.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pro Tips:',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTip('• Share your hobbies and passions'),
                            _buildTip('• Mention what you\'re looking for'),
                            _buildTip('• Be authentic and positive'),
                            _buildTip('• Add a fun fact about yourself'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Continue',
                      onPressed: _isLoading ? null : _continue,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Skip for now',
                      onPressed: _isLoading ? null : _skip,
                      isOutlined: true,
                      backgroundColor: Colors.white,
                      textColor: Colors.white,
                    ),
                  ],
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
                value: 0.8, // 80% - Step 4 of 5
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '4/5',
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

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 12,
        ),
      ),
    );
  }
}