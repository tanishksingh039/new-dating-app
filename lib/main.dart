import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/screenshot_service.dart';
import 'services/screenshot_protection_service.dart';
import 'services/presence_service.dart';
import 'services/icebreaker_service.dart';
import 'constants/app_colors.dart';
import 'providers/appearance_provider.dart';
import 'providers/theme_provider.dart';
import 'services/navigation_service.dart';

// Screens - Splash
import 'screens/splash/splash_screen.dart';

// Screens - Auth
import 'screens/auth/wrapper_screen.dart';
import 'screens/auth/login_screen.dart';

// Screens - Onboarding
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/phone_verification_screen.dart';
import 'screens/onboarding/terms_and_conditions_screen.dart';
import 'screens/onboarding/basic_info_screen.dart';
import 'screens/onboarding/detailed_profile_screen.dart';
import 'screens/onboarding/prompts_screen.dart';
import 'screens/onboarding/photo_upload_screen.dart';
import 'screens/onboarding/interests_screen.dart';
import 'screens/onboarding/bio_screen.dart';
import 'screens/onboarding/location_permission_screen.dart';
import 'screens/onboarding/notification_permission_screen.dart';
import 'screens/onboarding/profile_review_screen.dart';
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

// Screens - Verification
import 'screens/verification/liveness_verification_screen.dart';

// Models
import 'models/user_model.dart';

// Monitoring
import 'utils/firestore_monitor.dart';

// Providers
import 'providers/premium_provider.dart';

// Admin Action Enforcement
import 'widgets/admin_action_checker.dart';
import 'screens/banned_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Catch errors outside Flutter framework
  runZonedGuarded(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase Crashlytics
    try {
      // Enable Crashlytics collection (in both debug and release modes)
      // In debug mode, you can test crashes; in release mode, they'll be reported
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      // Set up Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        // Send to Crashlytics
        FirebaseCrashlytics.instance.recordFlutterError(details);
        
        // Log the error
        debugPrint('═══════════════════════════════════════');
        debugPrint('🚨 CAUGHT ERROR: ${details.exception}');
        debugPrint('📍 Location: ${details.context}');
        debugPrint('📚 Stack trace: ${details.stack}');
        debugPrint('═══════════════════════════════════════');
        
        // Show error in debug mode but don't crash
        if (kDebugMode) {
          FlutterError.presentError(details);
        }
      };
      
      debugPrint('✅ Firebase Crashlytics initialized');
    } catch (e) {
      debugPrint('⚠️ Firebase Crashlytics init failed: $e');
    }
    
    // Replace error widget with friendly message instead of red screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please restart the app',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${details.exception}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    };
    
    // Initialize Firebase Analytics
    try {
      await FirebaseAnalytics.instance.logAppOpen();
      debugPrint('✅ Firebase Analytics initialized');
    } catch (e) {
      debugPrint('⚠️ Firebase Analytics init failed: $e');
    }
    
    // Initialize icebreaker prompts (runs once)
    try {
      final icebreakerService = IcebreakerService();
      await icebreakerService.initializeDefaultPrompts();
      debugPrint('✅ Icebreaker prompts initialized');
    } catch (e) {
      debugPrint('⚠️ Icebreaker init: $e');
    }
    
    // Start Firestore monitoring (debug mode only)
    if (kDebugMode) {
      try {
        FirestoreMonitor.startMonitoring();
        debugPrint('🔍 Firestore monitoring enabled');
      } catch (e) {
        debugPrint('⚠️ Firestore monitoring failed: $e');
      }
    }
    
    // Initialize notification service
    try {
      await NotificationService().initialize();
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('⚠️ Notification service init failed: $e');
    }
    
    // Initialize screenshot service
    try {
      await ScreenshotService().initialize();
      debugPrint('✅ Screenshot service initialized');
    } catch (e) {
      debugPrint('⚠️ Screenshot service init failed: $e');
    }
    
    // Initialize screenshot protection service with real-time admin control
    try {
      // This will start listening to admin settings immediately
      final screenshotProtection = ScreenshotProtectionService();
      debugPrint('✅ Screenshot protection service initialized with real-time sync');
    } catch (e) {
      debugPrint('⚠️ Screenshot protection service init failed: $e');
    }
    
    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🚨 UNCAUGHT ERROR: $error');
    debugPrint('📚 Stack trace: $stackTrace');
    debugPrint('═══════════════════════════════════════');
    
    // Send uncaught errors to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Uncaught error in runZonedGuarded',
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppearanceProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
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
      onGenerateRoute: (settings) {
        // Define all routes here to ensure provider context is available
        switch (settings.name) {
          // Splash Route
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          
          // Home Route with Admin Action Enforcement
          case '/home-protected':
            return MaterialPageRoute(
              builder: (_) => AdminActionChecker(
                child: const HomeScreen(),
              ),
            );
          
          // Auth Routes
          case '/wrapper':
            return MaterialPageRoute(builder: (_) => const WrapperScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          
          // Onboarding Routes - New Enhanced Flow
          case '/onboarding/welcome':
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          case '/onboarding/phone':
            return MaterialPageRoute(builder: (_) => const PhoneVerificationScreen());
          case '/onboarding/terms':
            return MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen());
          case '/onboarding/basic-info':
            return MaterialPageRoute(builder: (_) => const BasicInfoScreen());
          case '/onboarding/detailed-profile':
            return MaterialPageRoute(builder: (_) => const DetailedProfileScreen());
          case '/onboarding/prompts':
            return MaterialPageRoute(builder: (_) => const PromptsScreen());
          case '/onboarding/photos':
            return MaterialPageRoute(builder: (_) => const PhotoUploadScreen());
          case '/onboarding/interests':
            return MaterialPageRoute(builder: (_) => const InterestsScreen());
          case '/onboarding/bio':
            return MaterialPageRoute(builder: (_) => const BioScreen());
          case '/onboarding/location':
            return MaterialPageRoute(builder: (_) => const LocationPermissionScreen());
          case '/onboarding/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationPermissionScreen());
          case '/onboarding/profile-review':
            return MaterialPageRoute(builder: (_) => const ProfileReviewScreen());
          case '/onboarding/preferences':
            return MaterialPageRoute(builder: (_) => const PreferencesScreen());
          
          // Legacy Onboarding Route (redirect to new flow)
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          
          // Main App Routes
          case '/home':
            return MaterialPageRoute(
              builder: (_) => AdminActionChecker(
                child: const HomeScreen(),
              ),
            );
          
          // Phase 1 Routes (Optional - accessed via bottom nav)
          case '/discovery':
            return MaterialPageRoute(builder: (_) => const DiscoveryScreen());
          case '/matches':
            return MaterialPageRoute(builder: (_) => const MatchesScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          
          // Phase 2 Routes - Settings
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/settings/account':
            return MaterialPageRoute(builder: (_) => const AccountSettingsScreen());
          case '/settings/privacy':
            return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
          case '/settings/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());
          
          // Verification Routes
          case '/settings/verification':
            return MaterialPageRoute(builder: (_) => const LivenessVerificationScreen());
          
          // Admin Action Enforcement Routes
          case '/banned':
            final banStatus = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => BannedScreen(banStatus: banStatus));
          
          // Handle chat screen with arguments
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                currentUserId: currentUserId,
                otherUserId: args['receiverId'] ?? args['otherUserId'],
                otherUserName: args['receiverName'] ?? args['otherUserName'],
              ),
            );
          
          // Handle profile detail screen with arguments
          case '/profile-detail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ProfileDetailScreen(
                user: args['user'],
                onLike: args['onLike'] ?? () {},
                onPass: args['onPass'] ?? () {},
                onSuperLike: args['onSuperLike'] ?? () {},
              ),
            );
          
          // Handle edit profile screen with arguments
          case '/edit-profile':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                user: args['user'] as UserModel,
              ),
            );
          
          default:
            return null;
        }
      },
      ),
    );
  }
}