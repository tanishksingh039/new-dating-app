# Onboarding Flow Documentation

## Overview
The app uses a smart onboarding detection system that ensures:
- **New users** see the complete onboarding process
- **Existing users** skip onboarding and go directly to the home screen

## Authentication Flow

```
App Launch (SplashScreen)
    ↓
WrapperScreen (checks auth state)
    ↓
    ├─ Not Authenticated → LoginScreen
    │
    └─ Authenticated → Check Onboarding Status
        ↓
        ├─ Onboarding Complete → HomeScreen ✅
        │
        └─ Onboarding Incomplete → WelcomeScreen (start onboarding)
```

## Onboarding Detection Logic

The `WrapperScreen` checks **multiple signals** to determine if onboarding is complete:

### Priority 1: Explicit Completion Flags
- `isOnboardingComplete: true`
- `onboardingCompleted: true`
- `onboardingStep: 'completed'`

### Priority 2: Profile Completion Percentage
- `profileComplete >= 50` (considers user as having substantial profile data)

### Priority 3: Essential Profile Data (Fallback)
For existing users who may not have the completion flags, we check:
- Has `name` (not empty)
- Has `photo` (either in `photos` array or `profilePhoto` field)
- Has `gender` (not empty)
- Has `dateOfBirth` (exists)

**If ANY of these conditions are true, the user is considered to have completed onboarding.**

## Onboarding Completion Points

Users can complete onboarding through two main paths:

### Path 1: Profile Review Screen
Located at: `lib/screens/onboarding/profile_review_screen.dart`

Sets the following fields:
```dart
{
  'onboardingCompleted': true,
  'isOnboardingComplete': true,
  'profileComplete': 100,
  'profileCompletedAt': FieldValue.serverTimestamp(),
  'onboardingStep': 'completed',
}
```

### Path 2: Preferences Screen
Located at: `lib/screens/onboarding/preferences_screen.dart`

Sets the following fields:
```dart
{
  'lookingFor': value,
  'interestedIn': value,
  'ageRangeMin': value,
  'ageRangeMax': value,
  'distance': value,
  'onboardingCompleted': true,
  'isOnboardingComplete': true,
  'onboardingStep': 'completed',
  'profileComplete': 100,
}
```

## Firestore User Document Structure

### Required Fields for Onboarding Detection
```javascript
{
  // Primary completion flags
  "isOnboardingComplete": true,
  "onboardingCompleted": true,
  "onboardingStep": "completed",
  "profileComplete": 100,
  
  // Essential profile data (fallback detection)
  "name": "John Doe",
  "gender": "male",
  "dateOfBirth": Timestamp,
  "photos": ["url1", "url2"],
  // OR
  "profilePhoto": "url",
  
  // Additional profile data
  "interests": ["interest1", "interest2"],
  "lookingFor": "relationship",
  "interestedIn": "female",
  "ageRangeMin": 22,
  "ageRangeMax": 30,
  "distance": 50
}
```

## Debug Logging

The `WrapperScreen` includes comprehensive debug logging to help troubleshoot onboarding detection:

```
═══════════════════════════════════════
[WrapperScreen] 🔍 Checking onboarding status for user: [userId]
  📋 isOnboardingComplete: true
  📋 onboardingCompleted: true
  📋 profileComplete: 100
  📋 onboardingStep: completed
  👤 name: John Doe
  📸 photos: 3 photos
  📸 profilePhoto: true
  ✅ Onboarding flags: true
  ✅ Profile complete %: 100
  ✅ Step complete: true
  ✅ Has essential data: true
  🎯 FINAL DECISION: COMPLETE ✅
═══════════════════════════════════════
[WrapperScreen] ✅ Existing user detected - Navigating to HomeScreen
```

## Testing Scenarios

### Scenario 1: New User
1. User signs up for the first time
2. No user document exists in Firestore
3. `WrapperScreen` detects no document → navigates to `WelcomeScreen`
4. User completes onboarding
5. Completion flags are set in Firestore
6. Next app launch → user goes directly to `HomeScreen`

### Scenario 2: Existing User (with completion flags)
1. User has `isOnboardingComplete: true` in Firestore
2. `WrapperScreen` detects completion flag → navigates to `HomeScreen`
3. Onboarding is skipped

### Scenario 3: Existing User (without completion flags)
1. User has essential profile data (name, photo, gender, DOB)
2. `WrapperScreen` uses fallback detection → navigates to `HomeScreen`
3. Onboarding is skipped

### Scenario 4: Partial Onboarding
1. User starts onboarding but doesn't complete it
2. No completion flags are set
3. `WrapperScreen` detects incomplete onboarding → navigates to `WelcomeScreen`
4. User continues from where they left off

## Troubleshooting

### Issue: Existing user sees onboarding again
**Possible causes:**
1. Completion flags not set in Firestore
2. User document doesn't exist
3. Essential profile data is missing

**Solution:**
1. Check debug logs in console
2. Verify Firestore document has completion flags
3. Manually set `isOnboardingComplete: true` if needed

### Issue: New user skips onboarding
**Possible causes:**
1. User document already exists with completion flags
2. Fallback detection triggered incorrectly

**Solution:**
1. Check debug logs to see which condition triggered
2. Verify user document in Firestore
3. Delete user document to force onboarding

## Key Files

- **Wrapper Screen**: `lib/screens/auth/wrapper_screen.dart`
- **Splash Screen**: `lib/screens/splash/splash_screen.dart`
- **Onboarding Screens**: `lib/screens/onboarding/`
- **Firebase Services**: `lib/firebase_services.dart`
- **Main App**: `lib/main.dart`

## Best Practices

1. **Always set all completion flags** when user completes onboarding
2. **Use consistent field names** across the app
3. **Include fallback detection** for existing users
4. **Add comprehensive logging** for debugging
5. **Test both new and existing user flows** before deployment
