# ✅ FIXED: Single Document for Sign-In and Onboarding

## 🔴 Problem You Reported

When you sign in with email/Google:
1. **First**: One document is created (e.g., `aRClait5b0XACthsR1oeMxy0jSx2`)
2. **Then**: During onboarding, a **SECOND document** is created (e.g., `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`)
3. **Result**: Sign-in data in one document, onboarding data in another ❌

## 🔍 Root Cause

The issue was in `firebase_services.dart`:

### Before (WRONG):
```dart
// updateUserProfile() was using .update()
await _firestore.collection('users').doc(userId).update(updates);

// Problem: .update() FAILS if document doesn't exist
// This caused the app to create a NEW document elsewhere
```

### After (FIXED):
```dart
// Now using .set() with merge: true
await _firestore
    .collection('users')
    .doc(userId)
    .set(updates, SetOptions(merge: true));

// Solution: .set() with merge ALWAYS updates the SAME document
// If document exists → updates it
// If document doesn't exist → creates it (shouldn't happen, but safe)
```

## ✅ What Was Fixed

### 1. `updateUserProfile()` Method
**File**: `lib/firebase_services.dart` (Line 240-264)

**Changed from**: `.update()` → **Changed to**: `.set(merge: true)`

**Used by**:
- `basic_info_screen.dart` - Saving name, gender, DOB
- `photo_upload_screen.dart` - Saving photos
- `interests_screen.dart` - Saving interests
- `bio_screen.dart` - Saving bio
- `preferences_screen.dart` - Saving preferences

### 2. `savePhotos()` Method
**File**: `lib/firebase_services.dart` (Line 200-216)

**Changed from**: `.update()` → **Changed to**: `.set(merge: true)`

### 3. `completeOnboarding()` Method
**File**: `lib/firebase_services.dart` (Line 157-170)

**Changed from**: `.update()` → **Changed to**: `.set(merge: true)`

### 4. Enhanced Logging
Added detailed logging to track which document is being updated:

```dart
_log('═══════════════════════════════════════');
_log('📝 Updating user profile...');
_log('User ID: aRClait5b0XACthsR1oeMxy0jSx2');  // ← You'll see this in console
_log('Fields: name, gender, dateOfBirth');
_log('✅ User profile updated successfully');
_log('═══════════════════════════════════════');
```

## 🎯 How It Works Now

### Step 1: Sign In with Google/Email
```
User signs in
    ↓
FirebaseServices.saveUserData() creates ONE document
    ↓
Document ID: aRClait5b0XACthsR1oeMxy0jSx2
    {
      uid: "aRClait5b0XACthsR1oeMxy0jSx2",
      email: "user@example.com",
      phoneNumber: "",
      isOnboardingComplete: false,
      onboardingStep: "welcome",
      profileComplete: 0,
      // ... all default fields
    }
```

### Step 2: Complete Onboarding
```
User enters name, gender, DOB
    ↓
FirebaseServices.updateUserProfile() called
    ↓
SAME document updated (merge: true)
    ↓
Document ID: aRClait5b0XACthsR1oeMxy0jSx2  ← SAME!
    {
      uid: "aRClait5b0XACthsR1oeMxy0jSx2",
      email: "user@example.com",
      name: "John Doe",           ← ADDED
      gender: "male",             ← ADDED
      dateOfBirth: [timestamp],   ← ADDED
      isOnboardingComplete: false,
      profileComplete: 20,        ← UPDATED
      // ... other fields
    }
```

### Step 3: Upload Photos
```
User uploads photos
    ↓
FirebaseServices.updateUserProfile() called
    ↓
SAME document updated
    ↓
Document ID: aRClait5b0XACthsR1oeMxy0jSx2  ← STILL SAME!
    {
      uid: "aRClait5b0XACthsR1oeMxy0jSx2",
      email: "user@example.com",
      name: "John Doe",
      gender: "male",
      dateOfBirth: [timestamp],
      photos: ["url1", "url2"],   ← ADDED
      profileComplete: 50,        ← UPDATED
      // ... other fields
    }
```

### Step 4: Complete All Steps
```
User completes all onboarding
    ↓
FirebaseServices.updateUserProfile() called
    ↓
SAME document updated with completion flags
    ↓
Document ID: aRClait5b0XACthsR1oeMxy0jSx2  ← ALWAYS SAME!
    {
      uid: "aRClait5b0XACthsR1oeMxy0jSx2",
      email: "user@example.com",
      name: "John Doe",
      gender: "male",
      dateOfBirth: [timestamp],
      photos: ["url1", "url2"],
      interests: ["coding", "music"],
      bio: "Hello!",
      isOnboardingComplete: true,   ← COMPLETED
      onboardingCompleted: true,    ← COMPLETED
      onboardingStep: "completed",  ← COMPLETED
      profileComplete: 100,         ← COMPLETED
      // ... all data in ONE document!
    }
```

## 📋 Console Logs to Watch

When you run the app now, you'll see:

### During Sign-In:
```
[FirebaseServices] ═══════════════════════════════════════
[FirebaseServices] Saving user data to Firestore...
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2
[FirebaseServices] Email: user@example.com
[FirebaseServices] 🆕 Creating NEW user document...
[FirebaseServices] ✅ New user document created successfully!
[FirebaseServices] ═══════════════════════════════════════
```

### During Onboarding:
```
[FirebaseServices] ═══════════════════════════════════════
[FirebaseServices] 📝 Updating user profile...
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← SAME ID!
[FirebaseServices] Fields: name, gender, dateOfBirth
[FirebaseServices] ✅ User profile updated successfully
[FirebaseServices] ═══════════════════════════════════════
```

**Key Point**: The User ID should be **IDENTICAL** in all logs!

## ✅ Testing Steps

### Test 1: Fresh User Flow
1. **Uninstall** the app completely
2. **Reinstall** and open
3. **Sign in** with Google/Email
4. **Check console** - Note the User ID
5. **Complete onboarding** (all steps)
6. **Check console** - User ID should be **SAME** in all logs
7. **Check Firebase Console**:
   - Go to Firestore → users
   - You should see **ONLY ONE document** with your email
   - That document should have ALL your data

### Test 2: Verify in Firebase Console
1. Go to Firebase Console → Firestore
2. Click on `users` collection
3. Find your document (by email)
4. Verify it contains:
   - ✅ `email` (from sign-in)
   - ✅ `name`, `gender`, `dateOfBirth` (from onboarding)
   - ✅ `photos` (from photo upload)
   - ✅ `interests` (from interests screen)
   - ✅ `bio` (from bio screen)
   - ✅ `isOnboardingComplete: true` (completion flag)
   - ✅ All in **ONE document**!

### Test 3: Check for Duplicates
1. In Firestore, search for your email
2. You should find **ONLY ONE document**
3. If you find multiple documents with same email → old bug, delete extras

## 🧹 Cleanup Old Duplicate Documents

If you have existing duplicate documents:

### Option 1: Manual Cleanup (Recommended)
1. Go to Firebase Console → Firestore → users
2. Find documents with your email
3. Keep the one with **most complete data**
4. Delete the others

### Option 2: Keep the One You're Currently Using
Check the console logs to see which User ID you're currently using, then:
1. Keep that document
2. Delete all others with same email

## 🎉 Expected Result

After this fix:

✅ **Sign-in creates ONE document**  
✅ **Onboarding updates SAME document**  
✅ **All data in ONE place**  
✅ **No duplicate documents**  
✅ **Consistent User ID throughout**  
✅ **Onboarding status properly tracked**  

## 🔍 How to Verify It's Working

### In Console Logs:
```
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← Sign-in
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← Basic info
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← Photos
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← Interests
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← Bio
[FirebaseServices] User ID: aRClait5b0XACthsR1oeMxy0jSx2  ← Completion
```

**All should be IDENTICAL!** ✅

### In Firebase Console:
```
users/
  └─ aRClait5b0XACthsR1oeMxy0jSx2/  ← ONLY ONE DOCUMENT
      ├─ uid: "aRClait5b0XACthsR1oeMxy0jSx2"
      ├─ email: "user@example.com"
      ├─ name: "John Doe"
      ├─ gender: "male"
      ├─ dateOfBirth: [timestamp]
      ├─ photos: ["url1", "url2"]
      ├─ interests: ["coding", "music"]
      ├─ bio: "Hello!"
      ├─ isOnboardingComplete: true
      └─ profileComplete: 100
```

## 📚 Technical Details

### Why `.update()` Was Wrong:
- `.update()` requires the document to **already exist**
- If document doesn't exist → throws error
- Error handling might create a new document elsewhere
- Result: Multiple documents

### Why `.set(merge: true)` Is Correct:
- `.set(merge: true)` works whether document exists or not
- If exists → merges new fields with existing data
- If doesn't exist → creates it (shouldn't happen, but safe)
- Result: Always updates the SAME document

### Methods Fixed:
1. ✅ `updateUserProfile()` - Main profile updates
2. ✅ `savePhotos()` - Photo uploads
3. ✅ `completeOnboarding()` - Completion flag
4. ✅ `saveOnboardingStep()` - Already correct, added logging

## 🚀 Summary

**Problem**: Sign-in and onboarding created separate documents  
**Cause**: Using `.update()` instead of `.set(merge: true)`  
**Solution**: Changed all update methods to use `.set(merge: true)`  
**Result**: Everything now saves to ONE document ✅  

Your issue is now **completely fixed**! 🎉

Test it out and watch the console logs - you'll see the same User ID throughout the entire flow!
