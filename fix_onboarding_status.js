// Firebase Admin SDK Script to Check and Fix Onboarding Status
// Run this with: node fix_onboarding_status.js

const admin = require('firebase-admin');

// Initialize Firebase Admin
// You need to download your serviceAccountKey.json from Firebase Console
// Go to: Project Settings > Service Accounts > Generate New Private Key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// The user ID you want to check/fix
const USER_ID = 'S6Bh0LbnLLPL60f1VkBcf8N1Wfm2';

async function checkAndFixUser() {
  try {
    console.log('═══════════════════════════════════════');
    console.log('🔍 CHECKING USER DOCUMENT');
    console.log('═══════════════════════════════════════');
    console.log(`User ID: ${USER_ID}`);
    console.log('');

    // Get the user document
    const userDoc = await db.collection('users').doc(USER_ID).get();

    if (!userDoc.exists) {
      console.log('❌ ERROR: User document does not exist!');
      console.log('═══════════════════════════════════════');
      return;
    }

    const userData = userDoc.data();
    console.log('📋 CURRENT DOCUMENT DATA:');
    console.log('───────────────────────────────────────');
    console.log(`Email: ${userData.email || 'N/A'}`);
    console.log(`Phone: ${userData.phoneNumber || 'N/A'}`);
    console.log(`Name: ${userData.name || 'N/A'}`);
    console.log(`Gender: ${userData.gender || 'N/A'}`);
    console.log(`Date of Birth: ${userData.dateOfBirth || 'N/A'}`);
    console.log(`Photos: ${userData.photos ? userData.photos.length : 0} photos`);
    console.log(`Interests: ${userData.interests ? userData.interests.length : 0} interests`);
    console.log(`Bio: ${userData.bio || 'N/A'}`);
    console.log('');
    console.log('🎯 ONBOARDING STATUS:');
    console.log('───────────────────────────────────────');
    console.log(`isOnboardingComplete: ${userData.isOnboardingComplete}`);
    console.log(`onboardingCompleted: ${userData.onboardingCompleted}`);
    console.log(`onboardingStep: ${userData.onboardingStep || 'N/A'}`);
    console.log(`profileComplete: ${userData.profileComplete || 0}%`);
    console.log('');

    // Check if onboarding should be marked as complete
    const hasName = userData.name && userData.name.length > 0;
    const hasGender = userData.gender && userData.gender.length > 0;
    const hasDOB = userData.dateOfBirth != null;
    const hasPhotos = userData.photos && userData.photos.length > 0;
    const hasInterests = userData.interests && userData.interests.length > 0;

    console.log('✅ PROFILE COMPLETENESS CHECK:');
    console.log('───────────────────────────────────────');
    console.log(`Has Name: ${hasName ? '✅' : '❌'}`);
    console.log(`Has Gender: ${hasGender ? '✅' : '❌'}`);
    console.log(`Has Date of Birth: ${hasDOB ? '✅' : '❌'}`);
    console.log(`Has Photos: ${hasPhotos ? '✅' : '❌'}`);
    console.log(`Has Interests: ${hasInterests ? '✅' : '❌'}`);
    console.log('');

    // Determine if profile is actually complete
    const isProfileComplete = hasName && hasGender && hasDOB && hasPhotos;
    
    if (isProfileComplete) {
      console.log('🎉 Profile appears COMPLETE!');
      
      // Check if flags are set correctly
      if (userData.isOnboardingComplete !== true || 
          userData.onboardingCompleted !== true || 
          userData.onboardingStep !== 'completed' ||
          userData.profileComplete !== 100) {
        
        console.log('');
        console.log('⚠️  ISSUE FOUND: Onboarding flags are NOT set correctly!');
        console.log('');
        console.log('🔧 FIXING NOW...');
        
        // Update the document with correct flags
        await db.collection('users').doc(USER_ID).update({
          isOnboardingComplete: true,
          onboardingCompleted: true,
          onboardingStep: 'completed',
          profileComplete: 100,
          profileCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastActive: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log('✅ FIXED! Onboarding status updated successfully!');
        console.log('');
        console.log('📋 UPDATED VALUES:');
        console.log('───────────────────────────────────────');
        console.log('isOnboardingComplete: true');
        console.log('onboardingCompleted: true');
        console.log('onboardingStep: completed');
        console.log('profileComplete: 100%');
        console.log('profileCompletedAt: [current timestamp]');
        console.log('');
        console.log('🎯 ACTION: Restart your app and login again!');
      } else {
        console.log('✅ Onboarding flags are already set correctly!');
        console.log('');
        console.log('🤔 If you\'re still seeing onboarding screen:');
        console.log('   1. Make sure you\'re logging in with the SAME account');
        console.log('   2. Check the User ID in console logs matches this one');
        console.log('   3. Clear app data and try again');
      }
    } else {
      console.log('❌ Profile is INCOMPLETE!');
      console.log('');
      console.log('Missing required fields:');
      if (!hasName) console.log('  - Name');
      if (!hasGender) console.log('  - Gender');
      if (!hasDOB) console.log('  - Date of Birth');
      if (!hasPhotos) console.log('  - Photos (at least 1)');
      console.log('');
      console.log('⚠️  User needs to complete these fields first!');
    }

    console.log('═══════════════════════════════════════');

  } catch (error) {
    console.error('❌ ERROR:', error);
    console.log('═══════════════════════════════════════');
  }

  process.exit(0);
}

// Run the check
checkAndFixUser();
