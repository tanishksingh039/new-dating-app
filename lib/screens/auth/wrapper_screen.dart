import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import '../onboarding/welcome_screen.dart';

class WrapperScreen extends StatefulWidget {
  const WrapperScreen({super.key});

  @override
  State<WrapperScreen> createState() => _WrapperScreenState();
}

class _WrapperScreenState extends State<WrapperScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF667eea),
              ),
            ),
          );
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // Check if onboarding is completed
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              // Show loading while fetching user data
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF667eea),
                    ),
                  ),
                );
              }

              // Check if user document exists and has onboarding data
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                
                if (userData != null) {
                  // Check a few signals to decide if onboarding is complete.
                  // Different parts of the app historically used different
                  // fields; be permissive so existing users are detected.
                  final isOnboardingFlag = (userData['isOnboardingComplete'] ?? userData['onboardingCompleted']) == true;

                  // Some onboarding flows write a numeric profile completion
                  // percentage (e.g. 40, 100). Treat >= 80 as complete.
                  int profileComplete = 0;
                  try {
                    final pc = userData['profileComplete'];
                    if (pc is int) profileComplete = pc;
                    if (pc is String) profileComplete = int.tryParse(pc) ?? 0;
                  } catch (_) {
                    profileComplete = 0;
                  }

                  // Fallback heuristics: require basic profile fields (name + photo)
                  final hasName = (userData['name'] as String?)?.isNotEmpty ?? false;
                  bool hasPhoto = false;
                  final photosField = userData['photos'];
                  if (photosField is List && photosField.isNotEmpty) {
                    hasPhoto = true;
                  } else if ((userData['profilePhoto'] as String?)?.isNotEmpty ?? false) {
                    hasPhoto = true;
                  }

                  final onboardingComplete = isOnboardingFlag || profileComplete >= 80 || (hasName && hasPhoto);

                  if (onboardingComplete) {
                    // Onboarding done, go to home
                    return const HomeScreen();
                  }
                }
              }
              
              // No user data or onboarding not completed
              return const WelcomeScreen();
            },
          );
        }

        // User is not signed in
        return const LoginScreen();
      },
    );
  }
}