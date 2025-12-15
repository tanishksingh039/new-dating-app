# Profile Picture Verification - Implementation Guide

## Overview

This guide explains the mandatory live verification system for profile picture changes in CampusBound. When users attempt to change their profile picture, they must complete live face detection verification to ensure identity authenticity and prevent misuse/impersonation.

## Architecture

### Core Components

1. **ProfilePictureVerificationService** (`lib/services/profile_picture_verification_service.dart`)
   - Manages pending verification state in Firestore
   - Tracks profile picture changes
   - Handles verification completion and picture discard logic

2. **ProfilePictureVerificationDialog** (`lib/widgets/profile_picture_verification_dialog.dart`)
   - Mandatory dialog with two options (non-dismissible)
   - Cannot be closed by back button or tapping outside
   - Persists across app restarts

3. **LivenessVerificationScreen** (`lib/screens/verification/liveness_verification_screen.dart`)
   - Supports profile picture verification context
   - Completes verification when `isProfilePictureVerification = true`
   - Integrates with ProfilePictureVerificationService

4. **EditProfileScreen** (`lib/screens/profile/edit_profile_screen.dart`)
   - Triggers verification when new photos are uploaded
   - Marks pictures as pending verification
   - Returns with success flag to indicate verification needed

5. **ProfileScreen** (`lib/screens/profile/profile_screen.dart`)
   - Checks for pending verifications on app load
   - Shows mandatory dialog if verification is pending
   - Persists across app restarts and reboots

## Data Flow

### When User Changes Profile Picture

```
EditProfileScreen
    ↓
User selects new photo from gallery
    ↓
Photo uploaded to R2 Storage
    ↓
markProfilePictureAsPending(photoUrl)
    ↓
Firestore updated:
  - pendingProfilePictureVerification: true
  - pendingProfilePictureUrl: photoUrl
  - pendingProfilePictureUploadedAt: timestamp
    ↓
Navigator.pop(context, true)
    ↓
ProfileScreen detects pending verification
    ↓
Shows ProfilePictureVerificationDialog
```

### When User Completes Verification

```
ProfilePictureVerificationDialog
    ↓
User taps "I want to verify myself once again"
    ↓
Navigate to LivenessVerificationScreen
    ↓
User completes liveness challenges
    ↓
_submitVerification() called
    ↓
completeProfilePictureVerification()
    ↓
Firestore updated:
  - Add pending photo to photos array
  - pendingProfilePictureVerification: false
  - lastProfilePictureVerifiedAt: timestamp
    ↓
Return true to dialog
    ↓
ProfileScreen reloads user data
```

### When User Discards Picture

```
ProfilePictureVerificationDialog
    ↓
User taps "I want to change my profile picture"
    ↓
discardPendingProfilePicture()
    ↓
Firestore updated:
  - pendingProfilePictureVerification: false
  - pendingProfilePictureUrl: deleted
    ↓
Close dialog
    ↓
User can upload new picture
```

## Firestore Schema

### Users Collection Fields

```dart
{
  // ... existing fields ...
  
  // Profile Picture Verification Fields
  "pendingProfilePictureVerification": bool,      // true if pending
  "pendingProfilePictureUrl": String,             // URL of pending picture
  "pendingProfilePictureUploadedAt": Timestamp,   // When uploaded
  "lastProfilePictureVerifiedAt": Timestamp,      // Last verification time
}
```

## Key Features

### 1. Mandatory Enforcement
- Dialog cannot be dismissed by back button
- Dialog cannot be dismissed by tapping outside
- Dialog persists across app restarts
- Dialog persists even after phone reboot

### 2. Two Options Only
- **Option 1:** "I want to verify myself once again"
  - Opens LivenessVerificationScreen
  - User completes live face detection
  - Photo is added to profile after verification
  
- **Option 2:** "I want to change my profile picture"
  - Discards the pending picture
  - User can upload a different picture
  - No verification required for discard

### 3. State Persistence
- Pending verification state stored in Firestore
- Checked on every app load
- Survives app restart and phone reboot
- Verified by checking `pendingProfilePictureVerification` flag

### 4. Integration with Existing Verification
- Uses same LivenessVerificationScreen as Premium verification
- Reuses face detection and liveness logic
- Maintains consistent verification standards

## Implementation Details

### ProfilePictureVerificationService Methods

```dart
// Check if user has pending verification
static Future<bool> hasPendingProfilePictureVerification()

// Get pending picture URL
static Future<String?> getPendingProfilePictureUrl()

// Mark picture as pending (called when user uploads)
static Future<void> markProfilePictureAsPending(String newPictureUrl)

// Complete verification (called after liveness verification)
static Future<void> completeProfilePictureVerification()

// Discard pending picture (called when user chooses to change)
static Future<void> discardPendingProfilePicture()

// Get verification status for UI
static Future<ProfilePictureVerificationStatus> getVerificationStatus()
```

### EditProfileScreen Changes

When new photos are added:
1. Upload photos to R2 Storage
2. If new photos exist, mark first one as pending
3. Return with `true` flag to indicate verification needed
4. Show snackbar: "Profile updated! Verification required for new photo."

### ProfileScreen Changes

On app load:
1. Call `_checkAndShowPendingVerification()`
2. Check `hasPendingProfilePictureVerification()`
3. If pending, show `ProfilePictureVerificationDialog`
4. Dialog is non-dismissible (barrierDismissible: false)

### LivenessVerificationScreen Changes

Added parameter:
```dart
final bool isProfilePictureVerification;
```

When `isProfilePictureVerification = true`:
- After successful verification, call `completeProfilePictureVerification()`
- This adds the pending photo to the photos array
- Clears the pending verification state

## Testing Checklist

- [ ] User can upload new profile picture
- [ ] Verification dialog appears immediately
- [ ] Dialog cannot be dismissed by back button
- [ ] Dialog cannot be dismissed by tapping outside
- [ ] "Verify myself" option opens LivenessVerificationScreen
- [ ] Liveness verification completes successfully
- [ ] Photo is added to profile after verification
- [ ] "Change picture" option discards pending photo
- [ ] User can upload new picture after discard
- [ ] Pending verification persists after app restart
- [ ] Pending verification persists after phone reboot
- [ ] Verification dialog shows on app load if pending

## Security Considerations

1. **Anti-Spoofing:** Uses existing face detection service
2. **Liveness Detection:** Requires multiple challenges (smile, head turns, etc.)
3. **Face Matching:** Compares new photo with profile photo
4. **Fresh Photos Only:** Rejects gallery photos (must be live camera)
5. **State Persistence:** Verification state stored in Firestore (server-side)

## Error Handling

- Network errors: Show snackbar with retry option
- Face detection failures: Show error message and allow retry
- Firestore update failures: Show error and allow retry
- Missing profile photo: Show error message

## Future Enhancements

1. **Batch Verification:** Allow multiple photos to be verified at once
2. **Expiry Dates:** Require re-verification after certain period
3. **Admin Override:** Allow admins to approve/reject verifications
4. **Analytics:** Track verification completion rates
5. **Notifications:** Notify users about pending verifications

## Troubleshooting

### Dialog doesn't appear on app load
- Check if `_checkAndShowPendingVerification()` is called in initState
- Verify Firestore has `pendingProfilePictureVerification: true`
- Check app logs for errors

### Dialog can be dismissed
- Ensure `barrierDismissible: false` in showDialog
- Ensure WillPopScope has `onWillPop: () async => false`
- Check if dialog is being popped elsewhere

### Verification doesn't complete
- Check if LivenessVerificationScreen receives `isProfilePictureVerification: true`
- Verify `completeProfilePictureVerification()` is called in _submitVerification
- Check Firestore for pending picture URL

### Picture not added after verification
- Check if `photos` array is updated in Firestore
- Verify pending picture URL is valid
- Check if `pendingProfilePictureVerification` is set to false

## Files Modified

1. `lib/services/profile_picture_verification_service.dart` (NEW)
2. `lib/widgets/profile_picture_verification_dialog.dart` (NEW)
3. `lib/screens/profile/edit_profile_screen.dart` (MODIFIED)
4. `lib/screens/profile/profile_screen.dart` (MODIFIED)
5. `lib/screens/verification/liveness_verification_screen.dart` (MODIFIED)

## Dependencies

- firebase_auth
- cloud_firestore
- image_picker
- animate_do
- cached_network_image

All dependencies already exist in the project.
