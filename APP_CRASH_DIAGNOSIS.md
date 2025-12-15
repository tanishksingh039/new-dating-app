# App Crash Diagnosis & Recovery

## Current Status
- ✅ Debug APK builds successfully
- ❌ App not opening on Play Store version
- ❌ App not opening on flutter run

## Root Cause Analysis

### What Changed Recently
1. Added Crashlytics initialization to main.dart
2. Modified google-services.json (removed debug SHA-1)
3. Added GoogleSignIn scopes to login_screen.dart
4. Removed clientId from GoogleSignIn (reverted)

### Most Likely Issue
The app is crashing during initialization, likely in one of these areas:
1. **Firebase Initialization** - Crashlytics or Analytics
2. **GoogleSignIn Initialization** - Scopes configuration
3. **Location Service** - Being called too early
4. **Notification Service** - Initialization failure

## Immediate Fix Steps

### Step 1: Disable Problematic Services
Comment out non-critical services in main.dart to isolate the issue:

```dart
// Temporarily disable these to test
// await NotificationService().initialize();
// FirestoreMonitor.startMonitoring();
```

### Step 2: Simplify GoogleSignIn
Revert to minimal configuration:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn();
```

### Step 3: Test Debug Build
```bash
flutter clean
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Step 4: Check Logcat
```bash
adb logcat | grep -i "flutter\|error\|exception"
```

## Files to Check

1. **lib/main.dart** - Firebase initialization
2. **lib/screens/auth/login_screen.dart** - GoogleSignIn config
3. **lib/services/notification_service.dart** - Initialization logic
4. **android/app/google-services.json** - Configuration

## Recovery Plan

If app still crashes:

1. **Disable Crashlytics temporarily:**
   ```dart
   // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
   ```

2. **Disable Analytics temporarily:**
   ```dart
   // await FirebaseAnalytics.instance.logAppOpen();
   ```

3. **Disable Notifications temporarily:**
   ```dart
   // await NotificationService().initialize();
   ```

4. **Disable Firestore Monitor:**
   ```dart
   // FirestoreMonitor.startMonitoring();
   ```

5. **Rebuild and test** - This will help identify which service is causing the crash

## Testing Procedure

1. Build debug APK
2. Install on device
3. Check logcat for errors
4. Re-enable services one by one
5. Identify which service causes the crash
6. Fix that specific service

## Expected Outcome

Once you identify the crashing service, we can:
- Fix the initialization logic
- Add proper error handling
- Rebuild release APK
- Upload to Play Store

## Quick Commands

```bash
# Clean build
flutter clean && flutter pub get

# Build debug
flutter build apk --debug

# Install
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# View logs
adb logcat -c && adb logcat | grep -i flutter
```
