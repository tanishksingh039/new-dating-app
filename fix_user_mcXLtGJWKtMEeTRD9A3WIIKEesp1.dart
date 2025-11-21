import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Fix script for user mcXLtGJWKtMEeTRD9A3WIIKEesp1 (yougrowth39@gmail.com)
/// This will mark their onboarding as complete
Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final userId = 'mcXLtGJWKtMEeTRD9A3WIIKEesp1';

  print('🔍 Fetching user data for: $userId');

  // Get current user data
  final doc = await firestore.collection('users').doc(userId).get();
  
  if (!doc.exists) {
    print('❌ User document does not exist!');
    return;
  }

  final data = doc.data()!;
  print('\n📄 Current user data:');
  print('   - isOnboardingComplete: ${data['isOnboardingComplete']}');
  print('   - onboardingCompleted: ${data['onboardingCompleted']}');
  print('   - profileComplete: ${data['profileComplete']}');
  print('   - name: ${data['name']}');
  print('   - photos: ${data['photos']}');

  print('\n✅ Updating user to mark onboarding as complete...');
  
  await firestore.collection('users').doc(userId).update({
    'isOnboardingComplete': true,
    'onboardingCompleted': true,
    'profileComplete': 100,
    'profileCompletedAt': FieldValue.serverTimestamp(),
  });

  print('✅ User updated successfully!');
  print('\n📝 New values set:');
  print('   - isOnboardingComplete: true');
  print('   - onboardingCompleted: true');
  print('   - profileComplete: 100');
  print('   - profileCompletedAt: <current timestamp>');
  
  print('\n🎉 Done! Now restart your app and login again.');
}
