import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Import the firebase services
import '../../firebase_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String _countryCode = "+91";

  /// Helper method for logging (only in debug mode)
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LoginScreen] $message');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      _log('User already signed in: ${user.email}');
      // Update last login
      await FirebaseServices.updateLastLogin(user.uid);
    }
  }

  /// ✅ Google Sign-In with Firestore Integration
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      _log('Starting Google Sign-In...');

      // Sign out from any previous Google account
      await _googleSignIn.signOut();
      _log('Signed out from previous Google session');

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _log('User cancelled Google Sign-In');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      _log('Google user selected: ${googleUser.email}');

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      _log('Got Google auth tokens');

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _log('Created Firebase credential');

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in to Firebase');
      }

      _log('Signed in to Firebase: ${user.email}');

      // ✅ Save user data to Firestore using FirebaseServices
      try {
        await FirebaseServices.saveUserData();
        _log('User data saved to Firestore successfully!');
      } catch (firestoreError) {
        _log('Firestore error (non-critical): $firestoreError');
        // Don't fail the login if Firestore fails
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Welcome ${user.displayName ?? 'back'}!"),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        _log('Google Sign-In completed successfully');
        
        // Wait for snackbar to show, then navigate
        await Future.delayed(const Duration(milliseconds: 1200));
        
        if (mounted) {
          // Navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
          _log('Navigated to home screen');
        }
      }

    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthException: ${e.code} - ${e.message}');
      
      if (mounted) {
        String errorMessage = "Authentication failed. Please try again.";
        
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage = "An account already exists with this email.";
            break;
          case 'invalid-credential':
            errorMessage = "Invalid credentials. Please try again.";
            break;
          case 'operation-not-allowed':
            errorMessage = "Google Sign-In is not enabled. Please contact support.";
            break;
          case 'user-disabled':
            errorMessage = "This account has been disabled.";
            break;
          case 'user-not-found':
            errorMessage = "No account found. Please sign up.";
            break;
          case 'wrong-password':
            errorMessage = "Incorrect password.";
            break;
          case 'network-request-failed':
            errorMessage = "Network error. Check your connection.";
            break;
        }
        
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      _log('General error: $e');
      
      if (mounted) {
        String errorMessage = "Something went wrong. Please try again.";
        
        if (e.toString().contains('network')) {
          errorMessage = "Network error. Check your internet connection.";
        } else if (e.toString().contains('PlatformException')) {
          errorMessage = "Google Sign-In error. Please try again.";
        }
        
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// ✅ Phone Sign-In with Firestore Integration
  Future<void> signInWithPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar("Enter a valid phone number");
      return;
    }

    setState(() => _isLoading = true);
    final phone = '$_countryCode${_phoneController.text.trim()}';

    _log('Starting phone verification for: $phone');

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        _log('Phone verification completed automatically');
        try {
          await _auth.signInWithCredential(credential);
          _log('Signed in with phone');
          
          // ✅ Save user data to Firestore
          try {
            await FirebaseServices.saveUserData(phoneNumber: phone);
            _log('User data saved to Firestore with phone number');
          } catch (e) {
            _log('Firestore error (non-critical): $e');
          }
          
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (e) {
          _log('Auto sign-in error: $e');
          if (mounted) {
            setState(() => _isLoading = false);
            _showErrorSnackBar("Auto-verification failed: $e");
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _log('Phone verification failed: ${e.code} - ${e.message}');
        if (mounted) {
          String errorMessage = e.message ?? "Phone verification failed";
          
          if (e.code == 'invalid-phone-number') {
            errorMessage = "Invalid phone number format";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many attempts. Please try again later.";
          }
          
          _showErrorSnackBar(errorMessage);
          setState(() => _isLoading = false);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _log('OTP sent to $phone');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text("OTP sent to $phone"),
                ],
              ),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          setState(() => _isLoading = false);
          Navigator.pushNamed(context, '/otp', arguments: {
            'verificationId': verificationId,
            'phone': phone,
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _log('Code auto-retrieval timeout');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Welcome Text
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find your perfect match',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // Card Container
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 📞 Phone Input
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_isLoading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            prefixText: "$_countryCode ",
                            prefixStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667eea),
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667eea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.phone_android_rounded,
                                color: Color(0xFF667eea),
                                size: 20,
                              ),
                            ),
                            labelText: "Phone Number",
                            labelStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF667eea),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 📲 Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : signInWithPhone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              disabledBackgroundColor:
                                  const Color(0xFF667eea).withOpacity(0.6),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Continue with Phone",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // 🟢 Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                        height: 24,
                                        width: 24,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.g_mobiledata,
                                          size: 28,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Continue with Google",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Terms & Privacy
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}