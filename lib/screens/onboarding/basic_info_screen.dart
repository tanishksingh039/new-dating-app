import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[BasicInfoScreen] $message');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 100, 1, 1);
    final DateTime lastDate = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppConstants.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  int _calculateAge() {
    if (_selectedDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select your date of birth', Colors.orange);
      return;
    }

    if (_selectedGender == null) {
      _showSnackBar('Please select your gender', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      _log('═══════════════════════════════════════');
      _log('📝 Saving basic info...');
      _log('Current User ID: ${user.uid}');
      _log('Email: ${user.email ?? "N/A"}');
      _log('Name: ${_nameController.text.trim()}');
      _log('Gender: $_selectedGender');
      _log('═══════════════════════════════════════');

      final age = _calculateAge();

      // Save basic details to Firestore
      await FirebaseServices.saveOnboardingStep(
        userId: user.uid,
        stepData: {
          'name': _nameController.text.trim(),
          'dateOfBirth': _selectedDate,
          'age': age,
          'gender': _selectedGender,
          'profileComplete': 15, // 15% complete
          'onboardingStep': 'basic_info_completed',
        },
      );

      _log('✅ Basic details saved successfully');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/detailed-profile');
      }
    } catch (e) {
      _log('Error saving basic details: $e');
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Tell us about yourself',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Let\'s start with the basics',
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
                              // Name Field
                              const Text(
                                'First Name',
                                style: AppConstants.headingSmall,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your first name',
                                  filled: true,
                                  fillColor: AppConstants.backgroundColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                validator: AppConstants.validateName,
                              ),
                              const SizedBox(height: 24),

                              // Date of Birth
                              const Text(
                                'Date of Birth',
                                style: AppConstants.headingSmall,
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppConstants.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: AppConstants.textGrey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedDate == null
                                            ? 'Select your date of birth'
                                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedDate == null
                                              ? AppConstants.textGrey
                                              : AppConstants.textDark,
                                        ),
                                      ),
                                      if (_selectedDate != null) ...[
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${_calculateAge()} years',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Gender Selection
                              const Text(
                                'Gender',
                                style: AppConstants.headingSmall,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: AppConstants.genderOptions
                                    .map((option) => Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedGender = option['value'];
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              decoration: BoxDecoration(
                                                color: _selectedGender == option['value']
                                                    ? AppColors.primary.withOpacity(0.1)
                                                    : AppConstants.backgroundColor,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _selectedGender == option['value']
                                                      ? AppColors.primary
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    option['icon'],
                                                    style: const TextStyle(fontSize: 24),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    option['label'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: _selectedGender == option['value']
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color: _selectedGender == option['value']
                                                          ? AppColors.primary
                                                          : AppConstants.textGrey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                value: 0.2, // 20% - Step 2 of 10
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '2/10',
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
}
