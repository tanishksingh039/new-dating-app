import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';

class DetailedProfileScreen extends StatefulWidget {
  const DetailedProfileScreen({super.key});

  @override
  State<DetailedProfileScreen> createState() => _DetailedProfileScreenState();
}

class _DetailedProfileScreenState extends State<DetailedProfileScreen> {
  final _jobController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();
  
  String? _selectedEducation;
  int _selectedHeight = 170; // Default height in cm
  String? _selectedDrinking;
  String? _selectedSmoking;
  String? _selectedWorkout;
  bool _isLoading = false;

  // Options
  final List<String> _drinkingOptions = [
    'Never',
    'Socially',
    'Regularly',
    'Prefer not to say'
  ];

  final List<String> _smokingOptions = [
    'Never',
    'Socially',
    'Regularly',
    'Prefer not to say'
  ];

  final List<String> _workoutOptions = [
    'Never',
    'Sometimes',
    'Often',
    'Every day'
  ];

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[DetailedProfileScreen] $message');
    }
  }

  @override
  void dispose() {
    _jobController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  String _formatHeight(int heightCm) {
    final feet = (heightCm / 30.48).floor();
    final inches = ((heightCm / 2.54) % 12).round();
    return '$heightCm cm (${feet}\'${inches}\")';
  }

  Future<void> _continue() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Save detailed profile data
      await FirebaseServices.saveOnboardingStep(
        userId: user.uid,
        stepData: {
          'jobTitle': _jobController.text.trim(),
          'company': _companyController.text.trim(),
          'school': _schoolController.text.trim(),
          'education': _selectedEducation,
          'height': _selectedHeight,
          'drinking': _selectedDrinking,
          'smoking': _selectedSmoking,
          'workout': _selectedWorkout,
          'profileComplete': 30, // 30% complete
          'onboardingStep': 'detailed_profile_completed',
        },
      );

      _log('Detailed profile saved successfully');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/prompts');
      }
    } catch (e) {
      _log('Error saving detailed profile: $e');
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
                        'More about you',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help others get to know you better',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form Card
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
                            // Work Section
                            _buildSectionTitle('💼', 'Work'),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _jobController,
                              label: 'Job Title',
                              hint: 'e.g., Software Engineer',
                              optional: true,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _companyController,
                              label: 'Company',
                              hint: 'e.g., Google',
                              optional: true,
                            ),
                            const SizedBox(height: 32),

                            // Education Section
                            _buildSectionTitle('🎓', 'Education'),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _schoolController,
                              label: 'School/University',
                              hint: 'e.g., Harvard University',
                              optional: true,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDropdown(
                              label: 'Education Level',
                              value: _selectedEducation,
                              items: AppConstants.educationOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedEducation = value;
                                });
                              },
                              optional: true,
                            ),
                            const SizedBox(height: 32),

                            // Physical Section
                            _buildSectionTitle('📏', 'Physical'),
                            const SizedBox(height: 16),
                            
                            // Height Slider
                            const Text(
                              'Height',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatHeight(_selectedHeight),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Slider(
                              value: _selectedHeight.toDouble(),
                              min: 140,
                              max: 220,
                              divisions: 80,
                              activeColor: AppColors.primary,
                              inactiveColor: AppConstants.backgroundColor,
                              onChanged: (double value) {
                                setState(() {
                                  _selectedHeight = value.round();
                                });
                              },
                            ),
                            const SizedBox(height: 32),

                            // Lifestyle Section
                            _buildSectionTitle('🌟', 'Lifestyle'),
                            const SizedBox(height: 16),
                            
                            _buildDropdown(
                              label: 'Drinking',
                              value: _selectedDrinking,
                              items: _drinkingOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedDrinking = value;
                                });
                              },
                              optional: true,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDropdown(
                              label: 'Smoking',
                              value: _selectedSmoking,
                              items: _smokingOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSmoking = value;
                                });
                              },
                              optional: true,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDropdown(
                              label: 'Workout',
                              value: _selectedWorkout,
                              items: _workoutOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedWorkout = value;
                                });
                              },
                              optional: true,
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
                value: 0.3, // 30% - Step 3 of 10
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '3/10',
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

  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppConstants.headingSmall,
            ),
            if (optional) ...[
              const SizedBox(width: 8),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textGrey,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
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
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppConstants.headingSmall,
            ),
            if (optional) ...[
              const SizedBox(width: 8),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textGrey,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: TextStyle(color: AppConstants.textGrey),
              ),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
