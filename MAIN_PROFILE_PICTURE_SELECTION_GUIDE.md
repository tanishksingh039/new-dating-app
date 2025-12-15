# Main Profile Picture Selection - Feature Guide

## Overview

Users can now select which photo should be their main profile picture before the verification process begins. This eliminates the need to delete and re-upload photos just to change the main picture.

## How It Works

### User Flow

1. **Edit Profile** → User goes to Edit Profile screen
2. **Add/Modify Photos** → User adds new photos or removes existing ones
3. **Save Changes** → User taps "Save Changes"
4. **Main Picture Selection Dialog** → Dialog appears showing all photos (existing + new)
5. **Select Main Picture** → User taps on the photo they want as main
6. **Confirm Selection** → User taps "Confirm" button
7. **Photos Reordered** → Selected photo moved to position 0 (main)
8. **Verification Dialog** → Mandatory verification dialog appears for the new main photo
9. **Complete Verification** → User completes liveness verification
10. **Profile Updated** → Main photo is now verified and set

## Components

### SelectMainProfilePictureDialog
**File:** `lib/widgets/select_main_profile_picture_dialog.dart`

A dialog widget that displays all photos in a 3-column grid and allows users to select which one should be the main profile picture.

**Features:**
- Shows all photos (existing + newly uploaded)
- Visual selection indicator (pink border + checkmark)
- Cancel and Confirm buttons
- Returns selected index or null if cancelled

**Parameters:**
```dart
SelectMainProfilePictureDialog(
  allPhotos: List<String>,      // All photos to display
  currentMainIndex: int = 0,     // Current main photo index
)
```

**Returns:**
- `int` - Index of selected photo
- `null` - If user cancelled

### EditProfileScreen Changes
**File:** `lib/screens/profile/edit_profile_screen.dart`

Modified `_saveProfile()` method to:
1. Detect when new photos are added
2. Show main picture selection dialog
3. Reorder photos based on selection
4. Mark the new main photo for verification

**Key Changes:**
```dart
// Show main picture selection dialog
final selectedMainIndex = await showDialog<int>(
  context: context,
  barrierDismissible: false,
  builder: (context) => SelectMainProfilePictureDialog(
    allPhotos: allPhotos,
    currentMainIndex: 0,
  ),
);

// Reorder photos so selected one is first
final reorderedPhotos = <String>[];
reorderedPhotos.add(allPhotos[selectedMainIndex]);
for (int i = 0; i < allPhotos.length; i++) {
  if (i != selectedMainIndex) {
    reorderedPhotos.add(allPhotos[i]);
  }
}

// Save reordered photos to Firestore
```

## Data Flow

```
User taps "Save Changes"
    ↓
Upload new photos to R2
    ↓
Combine existing + new photos
    ↓
New photos detected?
    ├─ YES → Show SelectMainProfilePictureDialog
    │         ↓
    │         User selects main photo
    │         ↓
    │         Reorder photos (selected = index 0)
    │         ↓
    │         Save reordered photos to Firestore
    │         ↓
    │         Mark main photo as pending verification
    │         ↓
    │         Return to ProfileScreen
    │         ↓
    │         Verification dialog appears
    │
    └─ NO → Save photos normally
            ↓
            Return to ProfileScreen
```

## User Interface

### Main Picture Selection Dialog

```
┌─────────────────────────────────────┐
│  Select Main Profile Picture        │
│                                     │
│  Choose which photo will be your    │
│  main profile picture               │
│                                     │
│  ┌────────┬────────┬────────┐      │
│  │ Photo1 │ Photo2 │ Photo3 │      │
│  │        │   ✓    │        │      │
│  └────────┴────────┴────────┘      │
│  ┌────────┬────────┬────────┐      │
│  │ Photo4 │ Photo5 │ Photo6 │      │
│  │        │        │        │      │
│  └────────┴────────┴────────┘      │
│                                     │
│  ┌──────────────┬──────────────┐   │
│  │   Cancel     │   Confirm    │   │
│  └──────────────┴──────────────┘   │
└─────────────────────────────────────┘
```

**Features:**
- 3-column grid layout
- Pink border (3px) on selected photo
- Checkmark icon on selected photo
- Scrollable if more than 6 photos
- Cancel button (gray) - discards changes
- Confirm button (pink) - saves selection

## Firestore Updates

### Before Selection
```dart
photos: [
  "existing_photo_1.jpg",
  "existing_photo_2.jpg",
  "new_photo_1.jpg",  // Just uploaded
  "new_photo_2.jpg",  // Just uploaded
]
```

### After Selection (if user selects index 2)
```dart
photos: [
  "new_photo_1.jpg",  // Moved to index 0 (main)
  "existing_photo_1.jpg",
  "existing_photo_2.jpg",
  "new_photo_2.jpg",
]
```

## Verification Flow

After main picture selection:

1. **Main photo marked as pending** → `pendingProfilePictureVerification: true`
2. **Verification dialog appears** → Non-dismissible dialog
3. **User completes liveness verification** → Face detection checks
4. **Photo verified** → Added to verified photos
5. **Pending state cleared** → `pendingProfilePictureVerification: false`

## Benefits

✅ **No Need to Delete Photos** - Users can reorder without deleting
✅ **Flexible Selection** - Choose any photo as main, not just new ones
✅ **Clear Intent** - Users explicitly choose their main photo
✅ **Maintains Verification** - New main photo still requires verification
✅ **Preserves History** - All photos kept in correct order

## Edge Cases Handled

### Case 1: User Cancels Selection
- Dialog closes
- No photos saved
- User returns to EditProfileScreen
- Can try again or discard changes

### Case 2: User Has 10 Photos, Adds 1 New
- Dialog shows all 11 photos
- User can select any of the 11 as main
- Only the selected photo is marked for verification
- Other 10 photos remain unchanged

### Case 3: User Removes Photos, Adds New
- Dialog shows remaining photos + new ones
- User selects main from available photos
- Reordering happens correctly

### Case 4: User Selects Already-Main Photo
- If user selects index 0 (already main)
- Photos stay in same order
- Still marked for verification (new photo added)

## Testing Checklist

- [ ] User can add new photos
- [ ] Main picture selection dialog appears
- [ ] Dialog shows all photos in 3-column grid
- [ ] User can tap photos to select
- [ ] Selected photo shows pink border and checkmark
- [ ] Cancel button closes dialog without saving
- [ ] Confirm button saves selection
- [ ] Photos are reordered correctly in Firestore
- [ ] New main photo is marked for verification
- [ ] Verification dialog appears after selection
- [ ] User can complete verification
- [ ] Main photo is updated in profile

## Debug Logging

The feature includes comprehensive logging:

```
🔴 [EditProfileScreen] NEW PHOTOS DETECTED
🔴 [EditProfileScreen] New photos count: 2
🔴 [EditProfileScreen] Uploaded URLs: 2
🔴 [EditProfileScreen] Selected main picture index: 2
🔴 [EditProfileScreen] Reordered photos - main: {url}
🔴 [EditProfileScreen] Profile updated in Firestore with reordered photos
🔴 [EditProfileScreen] Picture marked as pending verification
```

## Files Modified

1. **Created:** `lib/widgets/select_main_profile_picture_dialog.dart`
   - New dialog widget for main picture selection

2. **Modified:** `lib/screens/profile/edit_profile_screen.dart`
   - Added import for SelectMainProfilePictureDialog
   - Updated _saveProfile() to show dialog and reorder photos

## Future Enhancements

1. **Drag-to-Reorder** - Allow users to drag photos to reorder all of them
2. **Preview** - Show selected photo as main in real-time
3. **Batch Verification** - Verify multiple new photos at once
4. **Photo Captions** - Add captions to each photo
5. **Photo Filters** - Apply filters before saving

## Summary

The main profile picture selection feature provides a seamless way for users to choose their main photo without the hassle of deleting and re-uploading. The dialog appears automatically when new photos are added, making the process intuitive and efficient.
