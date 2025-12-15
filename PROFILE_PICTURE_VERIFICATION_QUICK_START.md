# Profile Picture Verification - Quick Start

## What Was Implemented

Mandatory live face verification whenever users change their profile picture. The system enforces identity authenticity and prevents impersonation/misuse.

## Key Features

✅ **Non-Dismissible Dialog** - Cannot be closed by back button or tapping outside
✅ **Persistent State** - Survives app restart and phone reboot
✅ **Two Options Only** - Verify now OR change picture (discard)
✅ **Live Detection** - Uses existing face detection service
✅ **Firestore Integration** - State stored server-side

## How It Works

### User Flow

1. **User uploads new profile picture** → EditProfileScreen
2. **Picture marked as pending** → Firestore updated
3. **App shows mandatory dialog** → ProfilePictureVerificationDialog
4. **User chooses option:**
   - **"Verify myself"** → LivenessVerificationScreen → Complete verification → Photo added
   - **"Change picture"** → Discard pending → Upload new picture

### State Persistence

- Pending verification state stored in Firestore
- Checked on every app load (`_checkAndShowPendingVerification()`)
- Dialog shown if `pendingProfilePictureVerification == true`
- Persists across app restarts and phone reboots

## Files Created

| File | Purpose |
|------|---------|
| `lib/services/profile_picture_verification_service.dart` | Manages verification state |
| `lib/widgets/profile_picture_verification_dialog.dart` | Non-dismissible dialog UI |
| `PROFILE_PICTURE_VERIFICATION_GUIDE.md` | Detailed documentation |

## Files Modified

| File | Changes |
|------|---------|
| `lib/screens/profile/edit_profile_screen.dart` | Triggers verification on photo upload |
| `lib/screens/profile/profile_screen.dart` | Checks for pending verification on load |
| `lib/screens/verification/liveness_verification_screen.dart` | Supports profile picture context |

## Firestore Schema

```dart
users/{userId} {
  // New fields for profile picture verification
  "pendingProfilePictureVerification": bool,
  "pendingProfilePictureUrl": String,
  "pendingProfilePictureUploadedAt": Timestamp,
  "lastProfilePictureVerifiedAt": Timestamp,
}
```

## API Reference

### ProfilePictureVerificationService

```dart
// Check if user has pending verification
hasPendingProfilePictureVerification() → Future<bool>

// Get pending picture URL
getPendingProfilePictureUrl() → Future<String?>

// Mark picture as pending (called when uploading)
markProfilePictureAsPending(String newPictureUrl) → Future<void>

// Complete verification (called after liveness verification)
completeProfilePictureVerification() → Future<void>

// Discard pending picture (called when user chooses to change)
discardPendingProfilePicture() → Future<void>

// Get verification status
getVerificationStatus() → Future<ProfilePictureVerificationStatus>
```

## Dialog Options

### Option 1: "I Want to Verify Myself Once Again"
- Opens LivenessVerificationScreen
- User completes 4 liveness challenges
- Photo is matched with profile picture
- Face consistency verified
- Photo added to profile after success

### Option 2: "I Want to Change My Profile Picture"
- Discards pending picture immediately
- User can upload different picture
- No verification required for discard
- Allows users to fix wrong/unclear photos

## Testing

### Quick Test Steps

1. Go to Profile → Edit Profile
2. Add new photo
3. Tap Save Changes
4. Verify dialog appears (non-dismissible)
5. Try to dismiss with back button (should fail)
6. Try to dismiss by tapping outside (should fail)
7. Tap "Verify myself" option
8. Complete liveness verification
9. Verify photo is added to profile

### Test App Restart

1. Upload new photo (dialog appears)
2. Don't complete verification
3. Close app completely
4. Reopen app
5. Verify dialog appears again (persisted)

## Error Handling

| Error | Solution |
|-------|----------|
| Dialog doesn't appear | Check Firestore has `pendingProfilePictureVerification: true` |
| Dialog can be dismissed | Ensure `barrierDismissible: false` in showDialog |
| Verification doesn't complete | Check LivenessVerificationScreen receives `isProfilePictureVerification: true` |
| Photo not added | Verify `photos` array is updated in Firestore |

## Security Features

- **Anti-Spoofing:** Rejects gallery photos (live camera only)
- **Liveness Detection:** Multiple challenges required
- **Face Matching:** New photo compared with profile photo
- **Fresh Photos:** Photos must be taken within 10 seconds
- **Server-Side State:** Verification state in Firestore (can't be bypassed)

## Integration Points

### EditProfileScreen
```dart
// When new photos are added:
await ProfilePictureVerificationService.markProfilePictureAsPending(firstNewPhotoUrl);
Navigator.pop(context, true); // Return with success flag
```

### ProfileScreen
```dart
// On app load:
_checkAndShowPendingVerification();

// Shows dialog if pending:
_showProfilePictureVerificationDialog();
```

### LivenessVerificationScreen
```dart
// After verification completes:
if (widget.isProfilePictureVerification) {
  await ProfilePictureVerificationService.completeProfilePictureVerification();
}
```

## Enforcement Rules

✅ **Zero Bypass Paths** - No way to skip verification
✅ **Mandatory Dialog** - Appears immediately after photo upload
✅ **Non-Dismissible** - Cannot close by back button or tapping outside
✅ **Persistent** - Survives app restart and phone reboot
✅ **Server-Side** - State stored in Firestore (enforced server-side)

## Next Steps

1. Test the implementation thoroughly
2. Monitor verification completion rates
3. Gather user feedback on UX
4. Consider future enhancements:
   - Batch verification for multiple photos
   - Expiry dates for verifications
   - Admin approval workflow
   - Analytics dashboard

## Support

For detailed information, see: `PROFILE_PICTURE_VERIFICATION_GUIDE.md`

For issues or questions, check the troubleshooting section in the detailed guide.
