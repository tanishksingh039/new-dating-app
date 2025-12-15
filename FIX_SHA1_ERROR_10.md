# Fix Google Sign-In Error 10 (SHA-1 Mismatch)

## Error Details
```
Google Sign-In Failed.

Details:
PlatformException(sign_in_failed, 
com.google.android.gms.common.api.j: 10: , null, null)
```

**Error Code 10 = SHA-1 fingerprint mismatch**

---

## Root Cause

Your release APK is signed with a keystore that has SHA-1:
```
4c:1b:78:18:9b:5e:d1:6e:76:c8:20:56:a0:bb:4f:ff:f5:80:16:15
```

But Firebase Console doesn't have this SHA-1 registered for your app.

---

## Solution: Add SHA-1 to Firebase Console

### Step 1: Go to Firebase Console
1. Open https://console.firebase.google.com
2. Select project: **campusbound-f31d8**
3. Click ⚙️ **Project Settings** (gear icon)

### Step 2: Select Android App
1. Click on **Android** tab
2. Select app: **com.campusbound.app**

### Step 3: Add SHA-1 Fingerprint
1. Scroll down to **SHA certificate fingerprints**
2. Click **Add fingerprint**
3. Paste this SHA-1:
   ```
   4c:1b:78:18:9b:5e:d1:6e:76:c8:20:56:a0:bb:4f:ff:f5:80:16:15
   ```
4. Click **Save**

### Step 4: Download Updated google-services.json
1. After adding SHA-1, the page will show a download button
2. Click **Download google-services.json**
3. Replace file: `android/app/google-services.json`

### Step 5: Rebuild and Test
```bash
cd c:\CampusBound\frontend
flutter clean
flutter pub get
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Step 6: Test Login
Try Google Sign-In again. It should now work!

---

## Verify SHA-1 is Correct

Your release keystore SHA-1:
```
4c:1b:78:18:9b:5e:d1:6e:76:c8:20:56:a0:bb:4f:ff:f5:80:16:15
```

This is stored in:
```
c:\CampusBound\campusbound.jks
```

---

## Why This Happens

1. **Debug keystore** (used by `flutter run`):
   - SHA-1: `bc:23:f6:68:47:86:d3:8d:66:42:b0:2d:27:8f:49:ec:1a:99:a3:2a`
   - Located: `~/.android/debug.keystore`
   - Works locally

2. **Release keystore** (used by Play Store):
   - SHA-1: `4c:1b:78:18:9b:5e:d1:6e:76:c8:20:56:a0:bb:4f:ff:f5:80:16:15`
   - Located: `c:\CampusBound\campusbound.jks`
   - Must be registered in Firebase

---

## Quick Checklist

- [ ] Go to Firebase Console
- [ ] Select campusbound-f31d8 project
- [ ] Go to Project Settings → Android app
- [ ] Add SHA-1: `4c:1b:78:18:9b:5e:d1:6e:76:c8:20:56:a0:bb:4f:ff:f5:80:16:15`
- [ ] Download updated google-services.json
- [ ] Replace `android/app/google-services.json`
- [ ] Run: `flutter clean && flutter pub get && flutter build apk --release`
- [ ] Install and test

---

## If Still Not Working

1. **Verify SHA-1 in Firebase Console:**
   - Go to Firebase Console
   - Check if SHA-1 is showing as registered
   - Should show: `4c1b78189b5ed16e76c82056a0bb4ffff5801615` (without colons)

2. **Check google-services.json:**
   - Open `android/app/google-services.json`
   - Look for `"certificate_hash": "4c1b78189b5ed16e76c82056a0bb4ffff5801615"`
   - Should be present in the file

3. **Verify Keystore:**
   - Run: `cd android && ./gradlew.bat signingReport`
   - Look for release SHA-1
   - Should match: `4c:1b:78:18:9b:5e:d1:6e:76:c8:20:56:a0:bb:4f:ff:f5:80:16:15`

4. **Clear Cache:**
   - Uninstall app from device
   - Clear app cache
   - Rebuild and reinstall

---

## Success Indicator

After fixing, you should see:
```
✅ Welcome Back
Where Connections Meets Compatibility !!

[Google Sign-In button]
```

No error message = Success! 🎉

---

**Status:** Follow these steps to fix the error
