import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// One-time script to fix existing users who completed onboarding
/// but are missing the isOnboardingComplete flag
Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('🔍 Searching for users with incomplete onboarding flags...');

  // Find all users who have onboardingCompleted but not isOnboardingComplete
  final usersSnapshot = await firestore.collection('users').get();

  int fixedCount = 0;
  int alreadyCorrectCount = 0;

  for (var doc in usersSnapshot.docs) {
    final data = doc.data();
    final onboardingCompleted = data['onboardingCompleted'] ?? false;
    final isOnboardingComplete = data['isOnboardingComplete'] ?? false;
    final profileComplete = data['profileComplete'] ?? 0;

    // If user has onboardingCompleted or profileComplete >= 80 but missing isOnboardingComplete
    if ((onboardingCompleted || profileComplete >= 80) && !isOnboardingComplete) {
      print('📝 Fixing user: ${doc.id} (${data['name'] ?? 'Unknown'})');
      
      await firestore.collection('users').doc(doc.id).update({
        'isOnboardingComplete': true,
        'onboardingCompleted': true,
        'profileComplete': 100,
      });
      
      fixedCount++;
    } else if (isOnboardingComplete) {
      alreadyCorrectCount++;
    }
  }

  print('\n✅ Migration complete!');
  print('   - Fixed: $fixedCount users');
  print('   - Already correct: $alreadyCorrectCount users');
  print('   - Total checked: ${usersSnapshot.docs.length} users');
}
