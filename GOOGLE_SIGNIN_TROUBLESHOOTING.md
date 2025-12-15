# Google Sign-In Error 10 - Troubleshooting Guide

## Error Details
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.j: 10: , null, null)
```

Error code 10 = SHA-1 fingerprint mismatch or configuration issue

## What I've Fixed

### 1. ✅ Removed Debug SHA-1 from google-services.json
- Removed duplicate OAuth client with debug SHA-1: `bc23f6684786d38d6642b02d278f49ec1a99a32a`
- Kept only release SHA-1: `4c1b78189b5ed16e76c82056a0bb4ffff5801615`

### 2. ✅ Added GoogleSignIn Configuration
- Added explicit `clientId` to GoogleSignIn initialization
- Added required scopes: `email`, `profile`
- Added better error logging for debugging

### 3. ✅ Improved Error Handling
- Added `.catchError()` to Google Sign-In call to capture exact error

## Files Modified
- `android/app/google-services.json` - Removed debug SHA-1
- `lib/screens/auth/login_screen.dart` - Added GoogleSignIn config

## Next Steps to Test

### Step 1: Clean Build
```bash
cd c:\CampusBound\frontend
flutter clean
flutter pub get
```

### Step 2: Build Release APK/Bundle
```bash
flutter build appbundle --release
```

### Step 3: Test on Device
1. Uninstall old app from device
2. Install new bundle via Google Play Console or ADB
3. Try Google Sign-In again

### Step 4: Check Logs
If still failing, check logcat:
```bash
adb logcat | grep -i "google\|sign_in\|firebase"
```

## Possible Remaining Issues

### Issue 1: Google Play Services Not Updated
- Device might have outdated Google Play Services
- Solution: Update Google Play Services on device

### Issue 2: Firebase Project Configuration
- Go to Firebase Console → Project Settings
- Verify Android app has correct SHA-1: `4c1b78189b5ed16e76c82056a0bb4ffff5801615`
- Verify package name: `com.campusbound.app`

### Issue 3: Google Cloud Console Configuration
- Go to Google Cloud Console → APIs & Services → Credentials
- Verify OAuth 2.0 Client ID is created for Android
- Verify package name and SHA-1 match

## Verification Checklist

- [ ] google-services.json has only release SHA-1
- [ ] Firebase Console shows correct SHA-1
- [ ] Google Cloud Console shows correct SHA-1
- [ ] Package name is `com.campusbound.app` everywhere
- [ ] Release keystore is being used for signing
- [ ] Device has latest Google Play Services

## If Still Not Working

1. Check exact error in logcat
2. Verify all SHA-1s match across:
   - Release keystore: `4c1b78189b5ed16e76c82056a0bb4ffff5801615`
   - Firebase Console
   - Google Cloud Console
   - google-services.json
3. Try clearing app data and cache
4. Try on different device/emulator
