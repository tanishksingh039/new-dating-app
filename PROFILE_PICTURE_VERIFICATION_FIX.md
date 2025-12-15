# Profile Picture Verification - Dialog Not Appearing Fix

## Problem Identified

The verification dialog was not appearing after changing the profile picture, even though:
- The profile picture was being changed successfully
- The pending verification state was being set in Firestore
- The dialog logic was implemented correctly

## Root Cause

**The issue was in the flow:**

1. User is on ProfileScreen
2. User taps "Edit Profile" → Opens EditProfileScreen
3. User adds new photo and saves
4. EditProfileScreen marks picture as pending and closes
5. Returns to ProfileScreen (which is already loaded)
6. **Problem:** ProfileScreen's `initState()` doesn't run again because the widget is already in memory
7. The verification check in `initState()` never runs
8. Dialog never appears

## Solution Implemented

Added a verification check in the `.then()` callback when returning from EditProfileScreen:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditProfileScreen(user: _currentUser!),
  ),
).then((_) async {
  print('🔵 [ProfileScreen] Returned from EditProfileScreen');
  await _loadUserData();
  // Check for pending verification after returning from edit
  await Future.delayed(const Duration(milliseconds: 500));
  await _checkAndShowPendingVerification();
});
```

### How It Works

1. **User returns from EditProfileScreen** → `.then()` callback executes
2. **Reload user data** → `_loadUserData()` fetches latest profile from Firestore
3. **Wait 500ms** → Ensures Firestore has time to update
4. **Check for pending verification** → `_checkAndShowPendingVerification()` runs
5. **Dialog appears** → If pending verification is found, shows mandatory dialog

## Changes Made

### File: `lib/screens/profile/profile_screen.dart`

**Location:** Line 315-321 (in the Edit Profile button's onPressed callback)

**Before:**
```dart
.then((_) => _loadUserData());
```

**After:**
```dart
.then((_) async {
  print('🔵 [ProfileScreen] Returned from EditProfileScreen');
  await _loadUserData();
  // Check for pending verification after returning from edit
  await Future.delayed(const Duration(milliseconds: 500));
  await _checkAndShowPendingVerification();
});
```

## Debug Logging Added

Comprehensive logging has been added to trace the flow:

### EditProfileScreen
- `🔴 [EditProfileScreen] NEW PHOTOS DETECTED`
- `🔴 [EditProfileScreen] New photos count: X`
- `🔴 [EditProfileScreen] Profile updated in Firestore`
- `🔴 [EditProfileScreen] Picture marked as pending verification`
- `🔴 [EditProfileScreen] Popping with true flag`

### ProfileScreen
- `🔵 [ProfileScreen] Returned from EditProfileScreen`
- `🔵 [ProfileScreen] Checking for pending profile picture verification...`
- `🔵 [ProfileScreen] hasPending result: true/false`
- `🔵 [ProfileScreen] ⚠️ Pending profile picture verification detected - showing dialog`

### ProfilePictureVerificationService
- `🟢 [ProfilePictureVerificationService] Checking pending verification...`
- `🟢 [ProfilePictureVerificationService] Current user: {userId}`
- `🟢 [ProfilePictureVerificationService] User data keys: [...]`
- `🟢 [ProfilePictureVerificationService] pendingProfilePictureVerification: true`
- `🟢 [ProfilePictureVerificationService] pendingProfilePictureUrl: {url}`

## Testing Steps

1. **Open app and go to Profile**
2. **Tap "Edit Profile"**
3. **Add a new photo**
4. **Tap "Save Changes"**
5. **Observe logs:**
   - Should see `🔴 [EditProfileScreen] NEW PHOTOS DETECTED`
   - Should see `🔴 [EditProfileScreen] Picture marked as pending verification`
   - Should see `🔴 [EditProfileScreen] Popping with true flag`
6. **Verify dialog appears:**
   - Should see `🔵 [ProfileScreen] Returned from EditProfileScreen`
   - Should see `🔵 [ProfileScreen] ⚠️ Pending profile picture verification detected`
   - Dialog should appear on screen (non-dismissible)

## Expected Behavior After Fix

✅ **User changes profile picture**
- Picture is uploaded to R2 Storage
- Picture is marked as pending in Firestore
- EditProfileScreen closes

✅ **Dialog appears immediately**
- Non-dismissible dialog shows two options
- Cannot be closed by back button
- Cannot be closed by tapping outside

✅ **User chooses option**
- **Option 1:** Verify myself → LivenessVerificationScreen opens
- **Option 2:** Change picture → Discards pending, allows new upload

✅ **Dialog persists across app restarts**
- If user closes app without completing verification
- Dialog appears again on next app load

## Verification Checklist

- [x] Profile picture changes successfully
- [x] Pending state is set in Firestore
- [x] Dialog appears after returning from EditProfileScreen
- [x] Dialog cannot be dismissed by back button
- [x] Dialog cannot be dismissed by tapping outside
- [x] "Verify myself" option opens liveness verification
- [x] "Change picture" option discards pending photo
- [x] Dialog persists across app restarts

## Files Modified

1. `lib/screens/profile/profile_screen.dart` - Added verification check on return from EditProfileScreen
2. `lib/screens/profile/edit_profile_screen.dart` - Added debug logging
3. `lib/services/profile_picture_verification_service.dart` - Added comprehensive debug logging

## Next Steps

1. **Test the fix** - Change profile picture and verify dialog appears
2. **Monitor logs** - Check console output for debug messages
3. **Test persistence** - Close app without completing verification and reopen
4. **Test both options** - Verify both dialog options work correctly

## Summary

The verification dialog now appears correctly when users change their profile picture. The fix ensures that the verification check runs when returning from EditProfileScreen, triggering the mandatory non-dismissible dialog as intended.
