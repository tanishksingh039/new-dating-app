import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Quick script to fix the yougrowth39@gmail.com user's onboarding flags
Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('🔍 Searching for user with email: yougrowth39@gmail.com...');

  // Find user by email (search through all users)
  final usersSnapshot = await firestore.collection('users').get();

  for (var doc in usersSnapshot.docs) {
    final data = doc.data();
    final phoneNumber = data['phoneNumber'] ?? '';
    
    // Check if this might be the user (you can also check by name or other fields)
    print('\n📄 User: ${doc.id}');
    print('   Phone: $phoneNumber');
    print('   Name: ${data['name']}');
    print('   isOnboardingComplete: ${data['isOnboardingComplete']}');
    print('   onboardingCompleted: ${data['onboardingCompleted']}');
    print('   profileComplete: ${data['profileComplete']}');
    
    // If you want to fix this user, uncomment the lines below:
    /*
    if (doc.id == 'YOUR_USER_ID_HERE') {
      print('\n✅ Updating user ${doc.id}...');
      await firestore.collection('users').doc(doc.id).update({
        'isOnboardingComplete': true,
        'onboardingCompleted': true,
        'profileComplete': 100,
      });
      print('✅ User updated successfully!');
    }
    */
  }

  print('\n\n📝 Instructions:');
  print('1. Find your user ID from the list above');
  print('2. Uncomment the update code and replace YOUR_USER_ID_HERE with your actual user ID');
  print('3. Run this script again to update the user');
  print('\nOR use Firebase Console to manually update the user document.');
}
