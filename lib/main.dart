import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'constants/app_colors.dart';

// Screens - Splash
import 'screens/splash/splash_screen.dart';

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

// Screens - Profile (Phase 2)
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';

// Screens - Settings (Phase 2)
import 'screens/settings/settings_screen.dart';
import 'screens/settings/account_settings_screen.dart';
import 'screens/settings/privacy_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';

// Models
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShooLuv',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'SF Pro',
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.softWarmPink,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        // Splash Route
        '/': (_) => const SplashScreen(),
        
        // Auth Routes
        '/wrapper': (_) => const WrapperScreen(),
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
        
        // Phase 1 Routes (Optional - accessed via bottom nav)
        '/discovery': (_) => const DiscoveryScreen(),
        '/matches': (_) => const MatchesScreen(),
        '/profile': (_) => const ProfileScreen(),
        
        // Phase 2 Routes - Settings
        '/settings': (_) => const SettingsScreen(),
        '/settings/account': (_) => const AccountSettingsScreen(),
        '/settings/privacy': (_) => const PrivacySettingsScreen(),
        '/settings/notifications': (_) => const NotificationSettingsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle chat screen with arguments
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) {
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          }
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              currentUserId: currentUserId,
              otherUserId: args['receiverId'] ?? args['otherUserId'],
              otherUserName: args['receiverName'] ?? args['otherUserName'],
            ),
          );
        }
        
        // Handle profile detail screen with arguments
        if (settings.name == '/profile-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProfileDetailScreen(
              user: args['user'],
              onLike: args['onLike'] ?? () {},
              onPass: args['onPass'] ?? () {},
              onSuperLike: args['onSuperLike'] ?? () {},
            ),
          );
        }
        
        // Handle edit profile screen with arguments
        if (settings.name == '/edit-profile') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EditProfileScreen(
              user: args['user'] as UserModel,
            ),
          );
        }
        
        return null;
      },
    );
  }
}