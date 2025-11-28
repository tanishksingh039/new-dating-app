import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  int _resendTimer = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    debugPrint('[PhoneVerification] 🔄 Loading started - isLoading: $_isLoading');

    try {
      final phoneNumber = '+91${_phoneController.text.trim()}';
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          // LINK phone to existing Google account instead of creating new user
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              await user.linkWithCredential(credential);
              debugPrint('[PhoneVerification] ✅ Phone linked to existing account: ${user.uid}');
            } catch (e) {
              debugPrint('[PhoneVerification] ❌ Error linking phone: $e');
              // If already linked, just continue
            }
          }
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/onboarding/basic-info');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[PhoneVerification] ❌ Verification failed: ${e.message}');
          if (mounted) {
            setState(() => _isLoading = false);
            debugPrint('[PhoneVerification] ✅ Loading stopped - isLoading: $_isLoading');
          }
          _showSnackBar('Verification failed: ${e.message}', Colors.red);
        },
        codeSent: (String verificationId, int? resendToken) async {
          debugPrint('[PhoneVerification] 📨 Code sent callback triggered');
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
          });
          _startResendTimer();
          _showSnackBar('OTP sent successfully!', AppConstants.successColor);
          // Keep loading animation visible until UI transitions to OTP screen
          await Future.delayed(const Duration(milliseconds: 3000));
          if (mounted) {
            setState(() => _isLoading = false);
            debugPrint('[PhoneVerification] ✅ Loading stopped - isLoading: $_isLoading');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showSnackBar('Failed to send OTP. Please try again.', Colors.red);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      _showSnackBar('Please enter a valid 6-digit OTP', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      // LINK phone to existing Google account instead of creating new user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('[PhoneVerification] ═══════════════════════════════════════');
        debugPrint('[PhoneVerification] 📱 Linking phone to existing account...');
        debugPrint('[PhoneVerification] Current User ID: ${user.uid}');
        debugPrint('[PhoneVerification] Email: ${user.email}');
        
        try {
          await user.linkWithCredential(credential);
          debugPrint('[PhoneVerification] ✅ Phone linked successfully!');
          debugPrint('[PhoneVerification] Phone: +91${_phoneController.text.trim()}');
          
          // Update Firestore with phone number
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'phoneNumber': '+91${_phoneController.text.trim()}',
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          debugPrint('[PhoneVerification] ✅ Phone saved to Firestore');
        } catch (linkError) {
          debugPrint('[PhoneVerification] ⚠️ Error linking phone: $linkError');
          // If already linked, just continue
        }
        debugPrint('[PhoneVerification] ═══════════════════════════════════════');
      } else {
        // Fallback: If no user signed in, sign in with phone
        await FirebaseAuth.instance.signInWithCredential(credential);
        debugPrint('[PhoneVerification] ⚠️ No existing user - signed in with phone');
      }
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/basic-info');
      }
    } catch (e) {
      debugPrint('[PhoneVerification] ❌ Error: $e');
      _showSnackBar('Invalid OTP. Please try again.', Colors.red);
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
                          'Verify your number',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _otpSent 
                            ? 'Enter the 6-digit code sent to\n+91 ${_phoneController.text}'
                            : 'We\'ll send you a verification code',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Phone/OTP Input Card
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
                            children: [
                              if (!_otpSent) ...[
                                // Phone Number Input
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '+91',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: 'Enter phone number',
                                          filled: true,
                                          fillColor: AppConstants.backgroundColor,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.all(16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Phone number is required';
                                          }
                                          if (value.trim().length != 10) {
                                            return 'Enter a valid 10-digit phone number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // OTP Input
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '000000',
                                    hintStyle: TextStyle(
                                      color: AppConstants.textLight,
                                      letterSpacing: 8,
                                    ),
                                    filled: true,
                                    fillColor: AppConstants.backgroundColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(20),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Resend OTP
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Didn\'t receive the code? ',
                                      style: TextStyle(
                                        color: AppConstants.textGrey,
                                      ),
                                    ),
                                    if (_resendTimer > 0)
                                      Text(
                                        'Resend in ${_resendTimer}s',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: _sendOTP,
                                        child: const Text(
                                          'Resend',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: 20),
                          // Change Number
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _otpSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: const Text(
                                'Change phone number',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  text: _otpSent ? 'Verify & Continue' : 'Send Code',
                  onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
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
                value: 0.1, // 10% - Step 1 of 10
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '1/10',
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
