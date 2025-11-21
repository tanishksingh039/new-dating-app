import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String? _lookingFor;
  String? _interestedIn;
  RangeValues _ageRange = const RangeValues(22, 30);
  double _distance = 50;
  bool _isLoading = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PreferencesScreen] $message');
    }
  }

  Future<void> _completeOnboarding() async {
    if (_lookingFor == null) {
      _showSnackBar('Please select what you\'re looking for', Colors.orange);
      return;
    }

    if (_interestedIn == null) {
      _showSnackBar('Please select who you\'re interested in', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Save preferences and mark onboarding as complete
      await FirebaseServices.updateUserProfile(user.uid, {
        'lookingFor': _lookingFor,
        'interestedIn': _interestedIn,
        'ageRangeMin': _ageRange.start.round(),
        'ageRangeMax': _ageRange.end.round(),
        'distance': _distance.round(),
        'onboardingCompleted': true,
        'isOnboardingComplete': true,
        'onboardingStep': 'completed',
        'profileComplete': 100,
      });

      _log('Preferences saved and onboarding completed!');

      if (mounted) {
        // Show success and navigate to home
        _showSnackBar('Profile completed! 🎉', AppConstants.successColor);
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
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
                        'Your preferences',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us find your perfect match',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Preferences Card
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
                            // Looking For
                            const Text(
                              'I\'m looking for',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: 16),
                            ...AppConstants.lookingForOptions
                                .map((option) => _buildLookingForCard(
                                      option['value'],
                                      option['label'],
                                      option['icon'],
                                      option['description'],
                                    ))
                                .toList(),

                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 32),

                            // Interested In
                            const Text(
                              'Show me',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInterestedInCard('male', 'Men', '👨'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInterestedInCard('female', 'Women', '👩'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 32),

                            // Age Range
                            const Text(
                              'Age range',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            RangeSlider(
                              values: _ageRange,
                              min: 18,
                              max: 80,
                              divisions: 62,
                              activeColor: AppColors.primary,
                              inactiveColor: AppConstants.backgroundColor,
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _ageRange = values;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

                            // Distance
                            const Text(
                              'Maximum distance',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_distance.round()} km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Slider(
                              value: _distance,
                              min: 1,
                              max: 100,
                              divisions: 99,
                              activeColor: AppColors.primary,
                              inactiveColor: AppConstants.backgroundColor,
                              onChanged: (double value) {
                                setState(() {
                                  _distance = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Complete Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  text: 'Complete Profile 🎉',
                  onPressed: _isLoading ? null : _completeOnboarding,
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
                value: 1.0, // 100% - Step 5 of 5
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '5/5',
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

  Widget _buildLookingForCard(
    String value,
    String label,
    String icon,
    String description,
  ) {
    final isSelected = _lookingFor == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _lookingFor = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestedInCard(String value, String label, String icon) {
    final isSelected = _interestedIn == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _interestedIn = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : AppConstants.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

