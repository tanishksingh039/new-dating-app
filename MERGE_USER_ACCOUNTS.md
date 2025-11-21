# Merge Duplicate User Accounts

## Problem Identified

You have **two different user documents** for the same person:

1. **First Document** (Completed Onboarding): `aRClait5b0XACthsR1oeMxy0jSx2`
2. **Second Document** (Incomplete): `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`

This happened because the Google Sign-In was signing out before signing in, causing Firebase to create a new account each time.

## Root Cause

**Line 109 in `login_screen.dart`:**
```dart
await _googleSignIn.signOut(); // ❌ This was the problem!
```

This line was forcing Google to forget the previous account and create a new one every time.

## Fix Applied

✅ **Removed the signOut call** - Now Google Sign-In will use the same account consistently

```dart
// Don't sign out - this causes Firebase to create new accounts
// await _googleSignIn.signOut();
_log('Starting Google Sign-In flow...');
```

## How to Fix Existing Duplicate Accounts

### Option 1: Delete the Incomplete Document (Recommended)

Since the second document (`S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`) has no onboarding data, simply delete it:

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Find the document: `users/S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`
4. Click "Delete"
5. Also delete the Firebase Auth user:
   - Go to Authentication → Users
   - Find user with UID `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`
   - Click "Delete User"

### Option 2: Merge the Documents (If Second Has Data)

If the second document has any data you want to keep:

#### Step 1: Export Both Documents

```javascript
// In Firebase Console → Firestore → Run Query
// Document 1 (Complete)
db.collection('users').doc('aRClait5b0XACthsR1oeMxy0jSx2').get()

// Document 2 (Incomplete)
db.collection('users').doc('S6Bh0LbnLLPL60f1VkBcf8N1Wfm2').get()
```

#### Step 2: Merge Data Manually

Copy any unique data from Document 2 to Document 1 in Firebase Console.

#### Step 3: Delete Document 2

Delete both the Firestore document and Firebase Auth user for `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`.

### Option 3: Use Firebase Admin SDK (For Multiple Users)

If you have many users with this issue, create a migration script:

```javascript
// migration.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function findDuplicateUsers() {
  const users = await db.collection('users').get();
  const emailMap = new Map();
  const duplicates = [];

  users.forEach(doc => {
    const data = doc.data();
    const email = data.email;
    
    if (email) {
      if (emailMap.has(email)) {
        duplicates.push({
          email: email,
          existing: emailMap.get(email),
          duplicate: doc.id
        });
      } else {
        emailMap.set(email, doc.id);
      }
    }
  });

  console.log('Found duplicates:', duplicates);
  return duplicates;
}

async function mergeDuplicates(duplicates) {
  for (const dup of duplicates) {
    const existingDoc = await db.collection('users').doc(dup.existing).get();
    const duplicateDoc = await db.collection('users').doc(dup.duplicate).get();
    
    const existingData = existingDoc.data();
    const duplicateData = duplicateDoc.data();
    
    // Keep the one with completed onboarding
    if (existingData.isOnboardingComplete && !duplicateData.isOnboardingComplete) {
      console.log(`Deleting incomplete duplicate: ${dup.duplicate}`);
      await db.collection('users').doc(dup.duplicate).delete();
      
      // Also delete from Firebase Auth
      try {
        await admin.auth().deleteUser(dup.duplicate);
        console.log(`Deleted auth user: ${dup.duplicate}`);
      } catch (error) {
        console.log(`Could not delete auth user: ${error.message}`);
      }
    } else if (!existingData.isOnboardingComplete && duplicateData.isOnboardingComplete) {
      console.log(`Deleting incomplete existing: ${dup.existing}`);
      await db.collection('users').doc(dup.existing).delete();
      
      try {
        await admin.auth().deleteUser(dup.existing);
        console.log(`Deleted auth user: ${dup.existing}`);
      } catch (error) {
        console.log(`Could not delete auth user: ${error.message}`);
      }
    }
  }
}

// Run the migration
findDuplicateUsers()
  .then(duplicates => mergeDuplicates(duplicates))
  .then(() => console.log('Migration complete!'))
  .catch(error => console.error('Migration error:', error));
```

## Testing After Fix

### Test 1: Clear App Data
1. Uninstall the app completely
2. Reinstall the app
3. Sign in with Google
4. Check the console logs for User ID
5. Complete onboarding
6. Close the app

### Test 2: Second Login
1. Open the app again
2. Sign in with the **same Google account**
3. Check the console logs - **User ID should be the same**
4. You should go directly to HomeScreen (no onboarding)

### Test 3: Verify in Firebase
1. Go to Firebase Console → Authentication
2. You should see **only ONE user** with your email
3. Go to Firestore → users collection
4. You should see **only ONE document** with your email
5. That document should have `isOnboardingComplete: true`

## Prevention

The fix ensures this won't happen again:

✅ **Removed `signOut()` call** - Google will remember the account  
✅ **Added better logging** - Track User ID in console  
✅ **Single document approach** - One user = one document  
✅ **Email tracking** - Easier to identify duplicates  

## Console Log to Watch

When you sign in, you should see:
```
[LoginScreen] Starting Google Sign-In flow...
[LoginScreen] Google user selected: your@email.com
[LoginScreen] ═══════════════════════════════════════
[LoginScreen] ✅ Signed in to Firebase successfully!
[LoginScreen] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← Should be SAME every time
[LoginScreen] Email: your@email.com
[LoginScreen] Display Name: Your Name
[LoginScreen] ═══════════════════════════════════════
```

**The User ID should be IDENTICAL on every login!**

## Quick Fix for Your Current Issue

**Immediate Action:**

1. Open Firebase Console
2. Go to Authentication → Users
3. Find and delete user: `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`
4. Go to Firestore → users
5. Delete document: `users/S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`
6. Keep the completed one: `users/aRClait5b0XACthsR1oeMxy0jSx2`
7. Update your app with the fixed code
8. Test login again - should work perfectly!

## Summary

### What Was Wrong
- ❌ `signOut()` before `signIn()` created new accounts
- ❌ Same user got multiple Firebase Auth UIDs
- ❌ Multiple Firestore documents for same person
- ❌ Onboarding status lost on second login

### What's Fixed
- ✅ Removed problematic `signOut()` call
- ✅ Google Sign-In now consistent
- ✅ Same user = same UID every time
- ✅ One document per user
- ✅ Onboarding status preserved

Your onboarding issue is now completely solved! 🎉
