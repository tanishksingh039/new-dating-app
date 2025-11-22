import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:animate_do/animate_do.dart';
import '../../firebase_services.dart';
import '../../widgets/app_logo.dart';
import '../../constants/app_colors.dart';
import '../../services/location_service.dart';
import '../admin/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocationService _locationService = LocationService();
  bool _isGoogleLoading = false;
  
  // Admin access
  int _logoTapCount = 0;
  DateTime? _lastTapTime;
  final List<String> _adminUserIds = [
    'admin_user',
    'tanishk_admin',
    'shooluv_admin',
    'dev_admin',
  ];

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LoginScreen] $message');
    }
  }

  void _onLogoTap() {
    final now = DateTime.now();
    
    // Reset counter if more than 2 seconds since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _logoTapCount = 0;
    }
    
    _lastTapTime = now;
    _logoTapCount++;
    
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _showAdminAccessDialog();
    }
  }

  void _showAdminAccessDialog() {
    // Navigate directly to admin login screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLoginScreen(),
      ),
    );
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
      await FirebaseServices.updateLastActive(user.uid);
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      _log('Starting Google Sign-In...');

      // Check location before allowing login
      _log('Checking user location...');
      final locationResult = await _locationService.checkLoginLocation();
      
      if (!locationResult.isAllowed) {
        _log('Location check failed: ${locationResult.errorMessage}');
        if (mounted) {
          setState(() => _isGoogleLoading = false);
          _showLocationErrorDialog(
            locationResult.errorMessage ?? 'Location check failed',
            locationResult.distanceInKm,
          );
        }
        return;
      }
      
      _log('Location check passed. Distance: ${locationResult.distanceInKm?.toStringAsFixed(2)} km');

      // Sign out to force account picker
      await _googleSignIn.signOut();
      _log('Signed out from Google to show account picker');
      _log('Starting Google Sign-In flow...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _log('User cancelled Google Sign-In');
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
        return;
      }

      _log('Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      _log('Got Google auth tokens');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _log('Created Firebase credential');

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in to Firebase');
      }

      _log('═══════════════════════════════════════');
      _log('✅ Signed in to Firebase successfully!');
      _log('User ID: ${user.uid}');
      _log('Email: ${user.email}');
      _log('Display Name: ${user.displayName}');
      _log('═══════════════════════════════════════');

      try {
        await FirebaseServices.saveUserData();
        _log('User data saved to Firestore successfully!');
      } catch (firestoreError) {
        _log('Firestore error (non-critical): $firestoreError');
      }

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
        
        await Future.delayed(const Duration(milliseconds: 1200));
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
          _log('Navigated to wrapper');
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
            errorMessage = "Google Sign-In is not enabled.";
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
        }
        
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
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

  void _showLocationErrorDialog(String message, double? distanceInKm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Required',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (distanceInKm != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You must be within 2 km of GHS to access this app.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _locationService.openLocationSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with bounce (tap 5 times for admin access)
                  Bounce(
                    delay: const Duration(milliseconds: 200),
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 1000),
                      child: GestureDetector(
                        onTap: _onLogoTap,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const ClipOval(
                            child: AppLogo(
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Animated title
                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 800),
                    child: ElasticIn(
                      delay: const Duration(milliseconds: 600),
                      child: const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Animated subtitle
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'Find your perfect match',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Animated Google Sign-In button
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    duration: const Duration(milliseconds: 1000),
                    child: SlideInLeft(
                      delay: const Duration(milliseconds: 900),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isGoogleLoading ? null : signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey.shade800,
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: _isGoogleLoading
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
                                      const Text(
                                        "Continue with Google",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Animated terms text
                  FadeIn(
                    delay: const Duration(milliseconds: 1200),
                    duration: const Duration(milliseconds: 800),
                    child: Padding(
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