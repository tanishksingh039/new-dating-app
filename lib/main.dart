import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens - Auth
import 'screens/auth/wrapper_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';

// Screens - Onboarding
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/photo_upload_screen.dart';
import 'screens/onboarding/interests_screen.dart';
import 'screens/onboarding/bio_screen.dart';
import 'screens/onboarding/preferences_screen.dart';

// Screens - Home & Chat
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';

// Screens - Discovery (Phase 1)
import 'screens/discovery/discovery_screen.dart';
import 'screens/discovery/profile_detail_screen.dart';

// Screens - Matches (Phase 1)
import 'screens/matches/matches_screen.dart';

// Screens - Profile (Phase 1)
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Dating App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro',
      ),
      initialRoute: '/',
      routes: {
        // Auth Routes
        '/': (_) => const WrapperScreen(),
        '/login': (_) => const LoginScreen(),
        '/otp': (_) => const OtpScreen(),
        
        // Onboarding Routes
        '/onboarding': (_) => const OnboardingScreen(),
        '/onboarding/photos': (_) => const PhotoUploadScreen(),
        '/onboarding/interests': (_) => const InterestsScreen(),
        '/onboarding/bio': (_) => const BioScreen(),
        '/onboarding/preferences': (_) => const PreferencesScreen(),
        
        // Main App Routes
        '/home': (_) => const HomeScreen(),
        
        // Phase 1 Routes (Optional - accessed via bottom nav in HomeScreen)
        '/discovery': (_) => const DiscoveryScreen(),
        '/matches': (_) => const MatchesScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle chat screen with arguments
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              currentUserId: args['currentUserId'],
              otherUserId: args['otherUserId'],
              otherUserName: args['otherUserName'],
            ),
          );
        }
        
        // Handle profile detail screen with arguments
        if (settings.name == '/profile-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProfileDetailScreen(
              user: args['user'],
              // Provide simple no-op callbacks here. The screen itself
              // will pop the route after calling these callbacks, so
              // these can be used to record analytics or swipes.
              onLike: () {
                // TODO: hook into Match/Discovery service to record a like
              },
              onPass: () {
                // TODO: record pass if needed
              },
              onSuperLike: () {
                // TODO: record super-like if needed
              },
            ),
          );
        }
        
        return null;
      },
    );
  }
}