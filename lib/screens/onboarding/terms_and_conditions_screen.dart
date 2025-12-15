import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../utils/constants.dart';
import '../../firebase_services.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _agreeToTerms = false;
  bool _isLoading = false;

  void _log(String message) {
    debugPrint('[TermsAndConditions] $message');
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

  Future<void> _acceptTerms() async {
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions to continue', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');

      _log('═══════════════════════════════════════');
      _log('📋 Saving Terms & Conditions acceptance...');
      _log('User ID: ${user.uid}');

      // Save terms acceptance to Firestore
      await FirebaseServices.saveOnboardingStep(
        userId: user.uid,
        stepData: {
          'agreedToTerms': true,
          'termsAcceptedAt': DateTime.now(),
          'onboardingStep': 'terms_accepted',
        },
      );

      _log('✅ Terms & Conditions accepted successfully');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/basic-info');
      }
    } catch (e) {
      _log('Error accepting terms: $e');
      if (mounted) {
        _showSnackBar('Failed to save. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to CampusBound',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please review and accept our terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Terms & Conditions Content
                  _buildSection(
                    'Terms of Service',
                    '''
CampusBound is a dating and social networking platform designed for college students. By using our app, you agree to comply with these terms and conditions.

• You must be at least 18 years old to use this service
• You are responsible for maintaining the confidentiality of your account
• You agree not to use the service for any illegal or harmful purposes
• You will not harass, abuse, or harm other users
• You will not share explicit or inappropriate content
• You agree to provide accurate and truthful information
• CampusBound reserves the right to suspend or terminate accounts that violate these terms
• You understand that your data will be stored and processed according to our privacy policy
                    ''',
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Community Guidelines',
                    '''
To maintain a safe and respectful community, please follow these guidelines:

✓ Be Respectful: Treat all users with respect and dignity
✓ No Harassment: Do not engage in bullying, harassment, or discrimination
✓ No Explicit Content: Do not share nude, sexual, or explicit images
✓ No Spam: Do not spam other users with unwanted messages
✓ Authentic Profile: Use real photos and accurate information
✓ No Scams: Do not attempt to scam or defraud other users
✓ Report Issues: Report any inappropriate behavior to our support team
✓ Respect Privacy: Do not share other users' personal information

Violations of these guidelines may result in account suspension or permanent ban.
                    ''',
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Privacy Policy',
                    '''
Your privacy is important to us. Here's how we handle your data:

Data Collection:
• We collect profile information (name, age, photos, interests)
• We collect location data to show nearby matches
• We collect usage data to improve our service
• We collect device information for security purposes

Data Usage:
• Your data is used to provide personalized matches
• We use analytics to improve user experience
• We never sell your data to third parties
• Your data is encrypted and stored securely

Data Protection:
• We use industry-standard encryption for all data
• Your password is never stored in plain text
• You can delete your account and data anytime
• We comply with GDPR and other privacy regulations

Third-Party Services:
• We use Firebase for authentication and storage
• We use analytics services to track app performance
• Third-party services have their own privacy policies

Contact Us:
• For privacy concerns, contact us at privacy@campusbound.com
                    ''',
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Safety & Security',
                    '''
We are committed to keeping our community safe:

• Verify your identity through phone verification
• Report suspicious accounts or behavior
• Use strong passwords and enable two-factor authentication
• Never share personal financial information
• Be cautious of users asking for money
• Block users who make you uncomfortable
• Our team reviews reported content and takes action

If you encounter any safety issues, please contact us immediately.
                    ''',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Agreement Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    setState(() => _agreeToTerms = !_agreeToTerms);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _agreeToTerms
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _agreeToTerms
                            ? AppColors.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _agreeToTerms
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _agreeToTerms
                                  ? AppColors.primary
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _agreeToTerms
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'I agree to the Terms & Conditions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Including Community Guidelines and Privacy Policy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _acceptTerms,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agreeToTerms
                          ? AppColors.primary
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'I Agree & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Decline option
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            content.trim(),
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
