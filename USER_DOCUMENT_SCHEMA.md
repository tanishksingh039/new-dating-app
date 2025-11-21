# User Document Schema - Single Document Approach

## Overview

CampusBound uses a **single user document** approach where all user data is stored in one Firestore document. This document is created once during signup and progressively updated during onboarding and app usage.

## Key Benefits

✅ **Single Source of Truth** - All user data in one place  
✅ **Efficient Queries** - No need to join multiple collections  
✅ **Atomic Updates** - All changes happen in one transaction  
✅ **Easy Onboarding Detection** - Check one document for completion status  
✅ **Better Performance** - Fewer Firestore reads/writes  

## Document Structure

### Firestore Path
```
users/{userId}
```

### Complete Schema

```javascript
{
  // ============================================
  // CORE IDENTITY FIELDS (Set at signup)
  // ============================================
  "uid": "string",                    // Firebase Auth UID (unique identifier)
  "email": "string",                  // User email (from Google Sign-In)
  "phoneNumber": "string",            // User phone (from Phone Auth)
  "createdAt": Timestamp,             // Account creation timestamp
  "lastActive": Timestamp,            // Last login/activity timestamp
  
  // ============================================
  // ONBOARDING STATUS (Critical for routing)
  // ============================================
  "isOnboardingComplete": false,      // Primary completion flag
  "onboardingCompleted": false,       // Secondary completion flag
  "onboardingStep": "welcome",        // Current step: "welcome", "basic-info", "photos", "completed"
  "profileComplete": 0,               // Percentage: 0-100
  
  // ============================================
  // PROFILE FIELDS (Filled during onboarding)
  // ============================================
  "name": "",                         // Full name
  "dateOfBirth": null,                // Timestamp or ISO string
  "gender": "",                       // "male", "female", "other"
  "photos": [],                       // Array of photo URLs
  "interests": [],                    // Array of interest strings
  "bio": "",                          // User bio/description
  
  // ============================================
  // PREFERENCES (Set in preferences screen)
  // ============================================
  "preferences": {},                  // General preferences object
  "lookingFor": "",                   // "relationship", "friendship", "casual"
  "interestedIn": "",                 // "male", "female", "everyone"
  "ageRangeMin": 22,                  // Minimum age preference
  "ageRangeMax": 30,                  // Maximum age preference
  "distance": 50,                     // Maximum distance in km
  
  // ============================================
  // VERIFICATION & PREMIUM
  // ============================================
  "isVerified": false,                // Profile verification status
  "isPremium": false,                 // Premium subscription status
  
  // ============================================
  // MATCHING & DISCOVERY
  // ============================================
  "matches": [],                      // Array of matched user IDs
  "matchCount": 0,                    // Total number of matches
  "dailySwipes": {},                  // Daily swipe tracking
  
  // ============================================
  // PRIVACY SETTINGS (Phase 2)
  // ============================================
  "privacySettings": {
    "showOnlineStatus": true,
    "showDistance": true,
    "showAge": true,
    "showLastActive": false,
    "allowMessagesFromMatches": true,
    "incognitoMode": false
  },
  
  // ============================================
  // NOTIFICATION SETTINGS (Phase 2)
  // ============================================
  "notificationSettings": {
    "pushEnabled": true,
    "newMatchNotif": true,
    "messageNotif": true,
    "likeNotif": true,
    "superLikeNotif": true,
    "emailEnabled": false,
    "emailMatches": false,
    "emailMessages": false,
    "emailPromotions": false
  },
  
  // ============================================
  // SAFETY FEATURES (Phase 3)
  // ============================================
  "blockedUsers": [],                 // Array of blocked user IDs
  "blockedBy": []                     // Array of users who blocked this user
}
```

## Document Lifecycle

### 1. **Initial Creation (Signup)**

When a user signs up (via Phone or Google), the system creates a complete document with all default fields:

```dart
// Called from: login_screen.dart, otp_screen.dart
await FirebaseServices.saveUserData(phoneNumber: phoneNumber);
```

**Fields Set:**
- `uid`, `email`, `phoneNumber`
- `createdAt`, `lastActive`
- All onboarding flags set to `false`/`0`
- Empty profile fields
- Default privacy/notification settings
- Empty arrays for matches, interests, etc.

### 2. **Progressive Updates (Onboarding)**

As the user completes onboarding steps, fields are updated using merge:

```dart
// Called from: basic_info_screen.dart, photo_upload_screen.dart, etc.
await FirebaseServices.saveOnboardingStep(
  userId: userId,
  stepData: {
    'name': 'John Doe',
    'gender': 'male',
    'dateOfBirth': timestamp,
    'onboardingStep': 'basic-info',
    'profileComplete': 20,
  },
);
```

**Fields Updated:**
- Profile fields: `name`, `gender`, `dateOfBirth`, `photos`, `interests`, `bio`
- Progress tracking: `onboardingStep`, `profileComplete`

### 3. **Completion (Final Step)**

When onboarding is complete, completion flags are set:

```dart
// Called from: preferences_screen.dart, profile_review_screen.dart
await FirebaseServices.updateUserProfile(userId, {
  'onboardingCompleted': true,
  'isOnboardingComplete': true,
  'onboardingStep': 'completed',
  'profileComplete': 100,
});
```

**Fields Set:**
- `isOnboardingComplete: true`
- `onboardingCompleted: true`
- `onboardingStep: 'completed'`
- `profileComplete: 100`

### 4. **Ongoing Updates (App Usage)**

During normal app usage, the document is updated for:

```dart
// Update last active
await FirebaseServices.updateLastActive(userId);

// Update profile
await FirebaseServices.updateUserProfile(userId, {
  'bio': 'New bio',
  'interests': ['reading', 'hiking'],
});

// Update settings
await FirebaseServices.updatePrivacySettings(userId, settings);
```

## Onboarding Detection Logic

The `WrapperScreen` checks the single document to determine routing:

```dart
// Priority 1: Explicit flags
final isComplete = userData['isOnboardingComplete'] == true || 
                   userData['onboardingCompleted'] == true;

// Priority 2: Profile completion
final profileComplete = userData['profileComplete'] >= 50;

// Priority 3: Step marker
final stepComplete = userData['onboardingStep'] == 'completed';

// Priority 4: Essential data (fallback for existing users)
final hasEssentials = hasName && hasPhoto && hasGender && hasDOB;

// Final decision
if (isComplete || profileComplete || stepComplete || hasEssentials) {
  return HomeScreen(); // Existing user
} else {
  return WelcomeScreen(); // New user
}
```

## Best Practices

### ✅ DO

1. **Always use merge: true** when updating the document
   ```dart
   await docRef.set(data, SetOptions(merge: true));
   ```

2. **Set all completion flags** when onboarding is done
   ```dart
   {
     'isOnboardingComplete': true,
     'onboardingCompleted': true,
     'onboardingStep': 'completed',
     'profileComplete': 100,
   }
   ```

3. **Include email AND phone** for better user identification
   ```dart
   {
     'email': user.email ?? '',
     'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
   }
   ```

4. **Update lastActive** on every login
   ```dart
   'lastActive': FieldValue.serverTimestamp()
   ```

### ❌ DON'T

1. **Don't create multiple documents** for the same user
2. **Don't overwrite the entire document** - always use merge
3. **Don't skip default fields** during initial creation
4. **Don't forget to set completion flags** at the end of onboarding

## Migration Strategy (For Existing Users)

If you have existing users without the new fields, run a migration:

```dart
Future<void> migrateUserDocuments() async {
  final users = await FirebaseFirestore.instance.collection('users').get();
  
  for (var doc in users.docs) {
    final data = doc.data();
    
    // Add missing fields
    final updates = <String, dynamic>{};
    
    if (!data.containsKey('email')) {
      updates['email'] = '';
    }
    
    if (!data.containsKey('onboardingStep')) {
      updates['onboardingStep'] = data['isOnboardingComplete'] == true 
        ? 'completed' 
        : 'welcome';
    }
    
    if (!data.containsKey('profileComplete')) {
      updates['profileComplete'] = data['isOnboardingComplete'] == true ? 100 : 0;
    }
    
    if (updates.isNotEmpty) {
      await doc.reference.set(updates, SetOptions(merge: true));
    }
  }
}
```

## Firestore Security Rules

Ensure proper security rules for the users collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can read their own document
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Users can write their own document
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Allow reading other users' public profile data (for discovery)
      allow read: if request.auth != null && 
                     resource.data.isOnboardingComplete == true;
    }
  }
}
```

## Key Files

- **User Model**: `lib/models/user_model.dart`
- **Firebase Services**: `lib/firebase_services.dart`
- **Wrapper Screen**: `lib/screens/auth/wrapper_screen.dart`
- **Login Screen**: `lib/screens/auth/login_screen.dart`
- **OTP Screen**: `lib/screens/auth/otp_screen.dart`
- **Onboarding Screens**: `lib/screens/onboarding/`

## Summary

The single document approach ensures:
- ✅ One document per user (identified by `uid`)
- ✅ Email and phone number stored for identification
- ✅ All onboarding data saved progressively
- ✅ Multiple completion flags for robust detection
- ✅ Existing users automatically detected and routed to home
- ✅ New users go through complete onboarding flow

This architecture prevents onboarding issues and provides a clean, maintainable user data structure.
