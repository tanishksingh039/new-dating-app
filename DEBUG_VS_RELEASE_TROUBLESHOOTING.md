# Debug vs Release Build Issues - Troubleshooting Guide

## Why `flutter run` Works But Release Build Doesn't

### Common Causes
1. **Minification/Obfuscation** - Release builds minify code, breaking reflection
2. **ProGuard Rules** - Firebase/Google libraries need specific rules
3. **Signing Certificate** - Release uses different keystore than debug
4. **SHA-1 Fingerprint** - Release SHA-1 doesn't match Firebase config
5. **Build Optimizations** - Release enables optimizations that break code
6. **Missing Permissions** - AndroidManifest.xml issues in release
7. **Firestore Security Rules** - Different behavior in release
8. **Environment Variables** - Debug vs release configuration differences

---

## Debugging Strategy #1: Build Release APK (Not Bundle)

Release APKs are easier to debug than bundles.

```bash
# Build release APK instead of bundle
flutter build apk --release

# Install on device
adb install -r build/app/outputs/flutter-apk/app-release.apk

# View logs
adb logcat -c
adb logcat | grep -i "flutter\|error\|exception"
```

**Why:** Bundles are optimized for Play Store. APKs show raw errors better.

---

## Debugging Strategy #2: Enable Verbose Logging

Add detailed logging to identify exactly where it fails.

### In login_screen.dart:

```dart
Future<void> signInWithGoogle() async {
  setState(() => _isGoogleLoading = true);

  try {
    _log('═══ GOOGLE SIGN-IN START ═══');
    _log('1. Starting Google Sign-In...');

    // Check location
    _log('2. Checking location...');
    final locationResult = await _locationService.checkLoginLocation();
    _log('2a. Location result: ${locationResult.isAllowed}');
    
    if (!locationResult.isAllowed) {
      _log('2b. Location check FAILED');
      return;
    }
    _log('2c. Location check PASSED');

    // Sign out
    _log('3. Signing out from Google...');
    await _googleSignIn.signOut();
    _log('3a. Signed out successfully');

    // Sign in
    _log('4. Starting Google Sign-In flow...');
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    _log('4a. Google user: ${googleUser?.email}');
    
    if (googleUser == null) {
      _log('4b. User cancelled sign-in');
      return;
    }

    // Get auth
    _log('5. Getting authentication tokens...');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    _log('5a. Got tokens - accessToken: ${googleAuth.accessToken != null}');
    _log('5b. Got tokens - idToken: ${googleAuth.idToken != null}');

    // Firebase
    _log('6. Creating Firebase credential...');
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    _log('6a. Credential created');

    _log('7. Signing in to Firebase...');
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    _log('7a. Firebase sign-in successful: ${userCredential.user?.uid}');

    _log('═══ GOOGLE SIGN-IN SUCCESS ═══');

  } catch (e) {
    _log('❌ ERROR: $e');
    _log('❌ Error type: ${e.runtimeType}');
    _log('❌ Stack trace: ${StackTrace.current}');
    
    // Log to Crashlytics
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
  } finally {
    if (mounted) {
      setState(() => _isGoogleLoading = false);
    }
  }
}
```

---

## Debugging Strategy #3: Compare Debug vs Release Builds

### Build both and compare:

```bash
# Build debug APK
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Check logs
adb logcat -c
# Try login
adb logcat | grep -i "flutter\|google\|sign"

# Build release APK
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Check logs
adb logcat -c
# Try login
adb logcat | grep -i "flutter\|google\|sign"

# Compare the two outputs
```

---

## Debugging Strategy #4: Check ProGuard Rules

Release builds use ProGuard which can break reflection. Firebase needs specific rules.

### Check `android/app/proguard-rules.pro`:

```proguard
# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.auth.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Dart/Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
```

### Enable ProGuard in build.gradle.kts:

```kotlin
buildTypes {
    release {
        isMinifyEnabled = true  // Enable minification
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

---

## Debugging Strategy #5: Check SHA-1 Fingerprint

Release uses different keystore than debug.

```bash
# Get release SHA-1
cd android
./gradlew.bat signingReport | grep -A 5 "release"

# Get debug SHA-1
./gradlew.bat signingReport | grep -A 5 "debug"

# Compare with Firebase Console
# Go to Firebase Console → Project Settings → Android app
# Verify both SHA-1s are registered
```

---

## Debugging Strategy #6: Disable Minification Temporarily

Minification can hide real errors. Disable it to see the actual error.

### In `android/app/build.gradle.kts`:

```kotlin
buildTypes {
    release {
        isMinifyEnabled = false  // Temporarily disable
        // ... rest of config
    }
}
```

Then rebuild:
```bash
flutter build apk --release
```

If it works without minification, the issue is in ProGuard rules.

---

## Debugging Strategy #7: Add Crash Handler

Catch all crashes and log them.

### In `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runZonedGuarded(() async {
    // ... Firebase init ...
    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('🚨 UNCAUGHT ERROR: $error');
    debugPrint('📚 STACK TRACE: $stackTrace');
    
    // Log to file for later analysis
    _logToFile('CRASH: $error\n$stackTrace');
  });
}

Future<void> _logToFile(String message) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/crash_logs.txt');
    await file.writeAsString('${DateTime.now()}: $message\n', mode: FileMode.append);
  } catch (e) {
    debugPrint('Failed to write log: $e');
  }
}
```

---

## Debugging Strategy #8: Check Firestore Rules

Release might have different Firestore access than debug.

### Test Firestore access:

```dart
Future<void> testFirestoreAccess() async {
  try {
    _log('Testing Firestore access...');
    
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    
    _log('✅ Firestore read successful: ${doc.exists}');
  } catch (e) {
    _log('❌ Firestore read failed: $e');
  }
}
```

---

## Debugging Strategy #9: Check Network Connectivity

Release might have different network behavior.

```dart
Future<void> testNetworkConnectivity() async {
  try {
    _log('Testing network connectivity...');
    
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      _log('✅ Network is available');
    }
  } catch (e) {
    _log('❌ Network error: $e');
  }
}
```

---

## Debugging Strategy #10: Compare Builds Side-by-Side

### Create test screen:

```dart
class DebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug Info')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Build Type'),
            subtitle: Text(kDebugMode ? 'DEBUG' : 'RELEASE'),
          ),
          ListTile(
            title: Text('Package Name'),
            subtitle: Text('com.campusbound.app'),
          ),
          ListTile(
            title: Text('Firebase Initialized'),
            subtitle: Text('${Firebase.apps.isNotEmpty}'),
          ),
          ListTile(
            title: Text('User Signed In'),
            subtitle: Text('${FirebaseAuth.instance.currentUser != null}'),
          ),
          ElevatedButton(
            onPressed: testGoogleSignIn,
            child: Text('Test Google Sign-In'),
          ),
        ],
      ),
    );
  }
}
```

---

## Quick Checklist

- [ ] Build release APK (not bundle)
- [ ] Check logcat for exact error
- [ ] Verify SHA-1 in Firebase Console
- [ ] Check ProGuard rules
- [ ] Disable minification temporarily
- [ ] Test Firestore access
- [ ] Test network connectivity
- [ ] Compare debug vs release logs
- [ ] Check AndroidManifest.xml permissions
- [ ] Verify google-services.json

---

## Most Likely Culprits (In Order)

1. **SHA-1 Fingerprint Mismatch** (70% probability)
   - Release uses different keystore
   - Firebase doesn't recognize the app

2. **ProGuard Minification** (15% probability)
   - Firebase reflection broken
   - Google Sign-In library stripped

3. **Firestore Security Rules** (10% probability)
   - Release build has different permissions
   - Rules block certain operations

4. **Missing Permissions** (5% probability)
   - AndroidManifest.xml issue
   - Runtime permissions not granted

---

## Commands to Run Now

```bash
# 1. Build release APK
flutter build apk --release

# 2. Install
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 3. Clear logs
adb logcat -c

# 4. Try login and capture logs
adb logcat | tee release_logs.txt

# 5. Search for errors
grep -i "error\|exception\|flutter" release_logs.txt
```

Share the output and we can identify the exact issue!
