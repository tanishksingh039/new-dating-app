import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../../utils/account_diagnostics.dart';
import '../../utils/firestore_monitor.dart';

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
          
          // Run diagnostics to check for issues (only in debug mode)
          AccountDiagnostics.runFullDiagnostics();
          
          // Also check for duplicate documents
          FirestoreMonitor.checkForDuplicates();
          
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

              // Handle errors
              if (userSnapshot.hasError) {
                debugPrint('[WrapperScreen] Error fetching user data: ${userSnapshot.error}');
                return const WelcomeScreen();
              }

              // Check if user document exists and has onboarding data
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                // Safely get user data - handle null case
                Map<String, dynamic>? userData;
                try {
                  final data = userSnapshot.data!.data();
                  if (data == null) {
                    debugPrint('[WrapperScreen] ⚠️ Document data is null for user ${user.uid}');
                    userData = null;
                  } else if (data is Map<String, dynamic>) {
                    userData = data;
                  } else {
                    debugPrint('[WrapperScreen] ⚠️ Document data is not a Map: ${data.runtimeType}');
                    userData = null;
                  }
                } catch (e, stackTrace) {
                  debugPrint('[WrapperScreen] ❌ Error casting user data: $e');
                  debugPrint('[WrapperScreen] Stack trace: $stackTrace');
                  // If cast fails, treat as incomplete onboarding
                  return const WelcomeScreen();
                }
                
                if (userData != null && userData.isNotEmpty) {
                  // Debug: Print user data to see what flags are set
                  debugPrint('═══════════════════════════════════════');
                  debugPrint('[WrapperScreen] 🔍 Checking onboarding status for user: ${user.uid}');
                  debugPrint('  📋 isOnboardingComplete: ${userData['isOnboardingComplete']}');
                  debugPrint('  📋 onboardingCompleted: ${userData['onboardingCompleted']}');
                  debugPrint('  📋 profileComplete: ${userData['profileComplete']}');
                  debugPrint('  📋 onboardingStep: ${userData['onboardingStep']}');
                  debugPrint('  👤 name: ${userData['name']}');
                  debugPrint('  📸 photos: ${userData['photos'] is List ? (userData['photos'] as List).length : 0} photos');
                  debugPrint('  📸 profilePhoto: ${userData['profilePhoto']?.toString().isNotEmpty ?? false}');
                  
                  // Check multiple signals to decide if onboarding is complete
                  // Priority 1: Explicit onboarding completion flags
                  final isOnboardingFlag = (userData['isOnboardingComplete'] == true) || 
                                          (userData['onboardingCompleted'] == true);

                  // Priority 2: Profile completion percentage (>= 50 means substantial progress)
                  int profileComplete = 0;
                  try {
                    final pc = userData['profileComplete'];
                    if (pc is int) {
                      profileComplete = pc;
                    } else if (pc is String) {
                      profileComplete = int.tryParse(pc) ?? 0;
                    } else if (pc is double) {
                      profileComplete = pc.round();
                    }
                  } catch (_) {
                    profileComplete = 0;
                  }

                  // Priority 3: Onboarding step is marked as 'completed'
                  final onboardingStepComplete = userData['onboardingStep'] == 'completed';

                  // Priority 4: Fallback heuristics - has essential profile data
                  final hasName = (userData['name'] as String?)?.isNotEmpty ?? false;
                  bool hasPhoto = false;
                  final photosField = userData['photos'];
                  if (photosField is List && photosField.isNotEmpty) {
                    hasPhoto = true;
                  } else if ((userData['profilePhoto'] as String?)?.isNotEmpty ?? false) {
                    hasPhoto = true;
                  }
                  
                  // Additional checks for existing users
                  final hasGender = userData['gender'] != null && (userData['gender'] as String?)?.isNotEmpty == true;
                  final hasDateOfBirth = userData['dateOfBirth'] != null;
                  final hasInterests = userData['interests'] is List && (userData['interests'] as List).isNotEmpty;
                  
                  // Consider user as having completed onboarding if ANY of these are true:
                  // 1. Explicit completion flags are set
                  // 2. Profile completion >= 50%
                  // 3. Onboarding step is 'completed'
                  // 4. Has essential profile data (name + photo + gender + DOB)
                  final onboardingComplete = isOnboardingFlag || 
                                            profileComplete >= 50 || 
                                            onboardingStepComplete ||
                                            (hasName && hasPhoto && hasGender && hasDateOfBirth);

                  debugPrint('  ✅ Onboarding flags: $isOnboardingFlag');
                  debugPrint('  ✅ Profile complete %: $profileComplete');
                  debugPrint('  ✅ Step complete: $onboardingStepComplete');
                  debugPrint('  ✅ Has essential data: ${hasName && hasPhoto && hasGender && hasDateOfBirth}');
                  debugPrint('  🎯 FINAL DECISION: ${onboardingComplete ? "COMPLETE ✅" : "INCOMPLETE ❌"}');
                  debugPrint('═══════════════════════════════════════');

                  if (onboardingComplete) {
                    debugPrint('[WrapperScreen] ✅ Existing user detected - Navigating to HomeScreen');
                    // Onboarding done, go to home
                    return const HomeScreen();
                  } else {
                    debugPrint('[WrapperScreen] ❌ New user or incomplete onboarding - Navigating to WelcomeScreen');
                  }
                } else {
                  debugPrint('[WrapperScreen] ⚠️ User data is null or empty - New user, navigating to WelcomeScreen');
                }
              } else {
                debugPrint('[WrapperScreen] ⚠️ User document does not exist - New user, navigating to WelcomeScreen');
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