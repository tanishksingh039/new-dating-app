# Main Profile Picture Selection - Quick Start

## What's New

Users can now **select which photo should be their main profile picture** before the verification process starts. No more deleting and re-uploading photos!

## How to Use

### Step 1: Edit Profile
- Go to Profile → Tap "Edit Profile"

### Step 2: Add Photos
- Add new photos or remove existing ones
- Tap "Save Changes"

### Step 3: Select Main Picture
- **Main Picture Selection Dialog appears**
- Shows all your photos in a grid
- Tap the photo you want as main
- A pink border and checkmark appear on selected photo

### Step 4: Confirm
- Tap "Confirm" button
- Photos are reordered (selected one becomes main)

### Step 5: Verification
- Mandatory verification dialog appears
- Complete liveness verification
- Your new main photo is now verified!

## Dialog Layout

```
Select Main Profile Picture
├─ Photo Grid (3 columns)
│  ├─ Photo 1
│  ├─ Photo 2 ✓ (selected)
│  ├─ Photo 3
│  └─ More photos...
└─ Buttons
   ├─ Cancel (gray)
   └─ Confirm (pink)
```

## Key Features

✅ **No Photo Deletion** - Keep all photos, just reorder
✅ **Visual Selection** - Pink border + checkmark shows selection
✅ **Easy to Use** - Tap photo to select, tap Confirm to save
✅ **Automatic Verification** - New main photo requires verification
✅ **Flexible** - Choose any photo as main, not just new ones

## Example Scenario

**Before:**
- You have 10 existing photos
- Photo 1 is main
- You want Photo 7 to be main instead

**Old Way:**
1. Delete photos 2-10
2. Upload new photos
3. Re-upload photos 2-10
4. Wait for verification

**New Way:**
1. Add new photos
2. Tap "Save Changes"
3. Select Photo 7 from dialog
4. Tap "Confirm"
5. Complete verification
6. Done! Photo 7 is now main

## What Happens Behind the Scenes

1. **Photos Uploaded** → New photos uploaded to R2 Storage
2. **Dialog Shows** → All photos displayed in grid
3. **Selection Made** → User selects main photo
4. **Reordering** → Selected photo moved to position 0
5. **Firestore Update** → Photos array reordered in database
6. **Verification** → New main photo marked for verification
7. **Dialog Appears** → Mandatory verification dialog shows
8. **Liveness Check** → User completes face verification
9. **Profile Updated** → Main photo is now verified

## Files Created/Modified

**Created:**
- `lib/widgets/select_main_profile_picture_dialog.dart` - Selection dialog

**Modified:**
- `lib/screens/profile/edit_profile_screen.dart` - Shows dialog on save

## Testing

1. Go to Profile → Edit Profile
2. Add a new photo
3. Tap "Save Changes"
4. Main picture selection dialog should appear
5. Select a photo by tapping it
6. Tap "Confirm"
7. Verification dialog should appear
8. Complete verification
9. Check profile - main photo should be updated

## Troubleshooting

**Dialog doesn't appear:**
- Make sure you added NEW photos (not just editing text)
- Check console logs for errors

**Photos not reordering:**
- Check Firestore to see if photos array was updated
- Verify the selected index was correct

**Verification dialog doesn't appear:**
- Check if main photo was marked as pending
- Verify ProfileScreen is checking for pending verification

## Debug Logs

Look for these logs in console:
```
🔴 [EditProfileScreen] NEW PHOTOS DETECTED
🔴 [EditProfileScreen] Selected main picture index: X
🔴 [EditProfileScreen] Reordered photos - main: {url}
🔴 [EditProfileScreen] Picture marked as pending verification
```

## Summary

The main profile picture selection feature makes it easy to choose which photo is your main profile picture without any hassle. Just add photos, select the one you want as main, and you're done!
