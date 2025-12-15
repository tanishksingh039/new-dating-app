# Firebase SHA-1 Fingerprint Fix

## Problem
Google Sign-In failing with error: `com.google.android.gms.common.api.j: 10`

This means the app's SHA-1 fingerprint doesn't match what's registered in Firebase Console.

## Your Release SHA-1 Fingerprint
```
4C:1B:78:18:9B:5E:D1:6E:76:C8:20:56:A0:BB:4F:FF:F5:80:16:15
```

## Solution: Add SHA-1 to Firebase Console

### Step 1: Go to Firebase Console
1. Open https://console.firebase.google.com
2. Select your project: **campusbound-f31d8**
3. Go to **Project Settings** (gear icon)

### Step 2: Add Android App SHA-1
1. Click on the **Android** app (com.campusbound.app)
2. Scroll down to **SHA certificate fingerprints**
3. Click **Add fingerprint**
4. Paste the SHA-1:
   ```
   4C:1B:78:18:9B:5E:D1:6E:76:C8:20:56:A0:BB:4F:FF:F5:80:16:15
   ```
5. Click **Save**

### Step 3: Download Updated google-services.json
1. After adding the SHA-1, download the updated `google-services.json`
2. Replace the file at: `android/app/google-services.json`

### Step 4: Rebuild and Test
```bash
cd c:\CampusBound\frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

## Why This Happened
- You changed the package name from `com.example.campusbound` to `com.campusbound.app`
- This generated a new keystore with a different SHA-1
- Firebase Console still had the old SHA-1 registered
- Google Play Services rejected the app because the fingerprints didn't match

## Verification
After adding the SHA-1 to Firebase:
1. Upload the new app bundle to Google Play Console
2. Test Google Sign-In on a real device
3. The error should be resolved

## Files Involved
- Keystore: `c:\CampusBound\campusbound.jks`
- Release SHA-1: `4C:1B:78:18:9B:5E:D1:6E:76:C8:20:56:A0:BB:4F:FF:F5:80:16:15`
- Package: `com.campusbound.app`
