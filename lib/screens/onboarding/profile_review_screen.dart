import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';

class ProfileReviewScreen extends StatefulWidget {
  const ProfileReviewScreen({super.key});

  @override
  State<ProfileReviewScreen> createState() => _ProfileReviewScreenState();
}

class _ProfileReviewScreenState extends State<ProfileReviewScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ProfileReviewScreen] $message');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data();
          });
        }
      }
    } catch (e) {
      _log('Error loading user data: $e');
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Mark onboarding as complete
      await FirebaseServices.saveOnboardingStep(
        userId: user.uid,
        stepData: {
          'onboardingCompleted': true,
          'isOnboardingComplete': true,
          'profileComplete': 100,
          'profileCompletedAt': FieldValue.serverTimestamp(),
          'onboardingStep': 'completed',
        },
      );

      _log('Onboarding completed successfully!');

      if (mounted) {
        // Show success message
        _showSnackBar('Welcome to shooLuv! 🎉', AppConstants.successColor);
        
        await Future.delayed(const Duration(milliseconds: 2000));
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      }
    } catch (e) {
      _log('Error completing onboarding: $e');
      if (mounted) {
        _showSnackBar('Failed to complete setup. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editSection(String section) {
    // Navigate back to specific onboarding section for editing
    switch (section) {
      case 'basic':
        Navigator.pushNamed(context, '/onboarding/basic-info');
        break;
      case 'detailed':
        Navigator.pushNamed(context, '/onboarding/detailed-profile');
        break;
      case 'prompts':
        Navigator.pushNamed(context, '/onboarding/prompts');
        break;
      case 'photos':
        Navigator.pushNamed(context, '/onboarding/photos');
        break;
      case 'interests':
        Navigator.pushNamed(context, '/onboarding/interests');
        break;
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
                        'Review your profile',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make sure everything looks perfect before we launch your profile',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      if (_userData != null) ...[
                        // Profile Preview Card
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
                              // Basic Info Section
                              _buildReviewSection(
                                title: 'Basic Information',
                                icon: Icons.person,
                                onEdit: () => _editSection('basic'),
                                children: [
                                  _buildInfoRow('Name', _userData!['name'] ?? 'Not set'),
                                  _buildInfoRow('Age', '${_userData!['age'] ?? 'Not set'}'),
                                  _buildInfoRow('Gender', AppConstants.getGenderLabel(_userData!['gender'] ?? '')),
                                ],
                              ),

                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),

                              // Photos Section
                              _buildReviewSection(
                                title: 'Photos',
                                icon: Icons.photo_library,
                                onEdit: () => _editSection('photos'),
                                children: [
                                  _buildPhotosPreview(),
                                ],
                              ),

                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),

                              // Prompts Section
                              if (_userData!['prompts'] != null) ...[
                                _buildReviewSection(
                                  title: 'Prompts',
                                  icon: Icons.chat_bubble_outline,
                                  onEdit: () => _editSection('prompts'),
                                  children: [
                                    _buildPromptsPreview(),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 24),
                              ],

                              // Interests Section
                              if (_userData!['interests'] != null) ...[
                                _buildReviewSection(
                                  title: 'Interests',
                                  icon: Icons.favorite,
                                  onEdit: () => _editSection('interests'),
                                  children: [
                                    _buildInterestsPreview(),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Completion Status
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.successColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppConstants.successColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your profile is complete and ready to go!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.successColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Loading state
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Complete Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  text: 'Launch My Profile 🚀',
                  onPressed: _isLoading ? null : _completeOnboarding,
                  isLoading: _isLoading,
                  backgroundColor: Colors.white,
                  textColor: AppColors.primary,
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
                value: 0.9, // 90% - Step 9 of 10
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '9/10',
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

  Widget _buildReviewSection({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onEdit,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosPreview() {
    final photos = _userData!['photos'] as List<dynamic>?;
    if (photos == null || photos.isEmpty) {
      return const Text('No photos added');
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(photos[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromptsPreview() {
    final prompts = _userData!['prompts'] as List<dynamic>?;
    if (prompts == null || prompts.isEmpty) {
      return const Text('No prompts added');
    }

    return Column(
      children: prompts.take(2).map<Widget>((prompt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prompt['prompt'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prompt['answer'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestsPreview() {
    final interests = _userData!['interests'] as List<dynamic>?;
    if (interests == null || interests.isEmpty) {
      return const Text('No interests added');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.take(6).map<Widget>((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${AppConstants.getInterestIcon(interest)} $interest',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
