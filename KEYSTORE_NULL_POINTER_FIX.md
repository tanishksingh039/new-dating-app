# NullPointerException Fix - Keystore Configuration

## The Problem

```
Execution failed for task ':app:signReleaseBundle'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.FinalizeBundleTask$BundleToolRunnable
   > java.lang.NullPointerException (no error message)
```

This means one or more of these values in `key.properties` is null/empty:
- `storePassword`
- `keyPassword`
- `keyAlias`
- `storeFile`

---

## Solution: Verify and Recreate key.properties

### Option 1: Use the Batch Script (Easiest)

Run this in Command Prompt:

```bash
cd c:\CampusBound\frontend
verify_and_fix_keystore.bat
```

This will:
1. Check if keystore file exists
2. Check if key.properties exists
3. Show file contents
4. Create/fix key.properties if needed

---

### Option 2: Manual Fix

**Step 1: Verify keystore file exists**

Check if this file exists:
```
c:\CampusBound\frontend\campusbound.jks
```

If NOT, create it:
```bash
keytool -genkey -v -keystore c:\CampusBound\frontend\campusbound.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campusbound
```

**Step 2: Delete old key.properties**

```bash
cd c:\CampusBound\frontend\android
del key.properties
```

**Step 3: Create new key.properties**

Replace `YOUR_PASSWORD` with your keystore password:

```bash
(
echo storePassword=YOUR_PASSWORD
echo keyPassword=YOUR_PASSWORD
echo keyAlias=campusbound
echo storeFile=../campusbound.jks
) > key.properties
```

**Example** (if password is `MyPassword123!`):
```bash
(
echo storePassword=MyPassword123!
echo keyPassword=MyPassword123!
echo keyAlias=campusbound
echo storeFile=../campusbound.jks
) > key.properties
```

**Step 4: Verify file contents**

```bash
type key.properties
```

You should see:
```
storePassword=MyPassword123!
keyPassword=MyPassword123!
keyAlias=campusbound
storeFile=../campusbound.jks
```

---

## Step 5: Rebuild

```bash
cd c:\CampusBound\frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## Checklist

- [ ] Keystore file exists: `c:\CampusBound\frontend\campusbound.jks`
- [ ] key.properties file exists: `c:\CampusBound\frontend\android\key.properties`
- [ ] storePassword is NOT empty
- [ ] keyPassword is NOT empty
- [ ] keyAlias is "campusbound"
- [ ] storeFile is "../campusbound.jks"
- [ ] No extra spaces or quotes
- [ ] File saved as UTF-8

---

## Expected Output

If successful:
```
✓ Built build/app/outputs/bundle/release/app-release.aab
```

---

## Troubleshooting

### Still getting NullPointerException?

1. Delete key.properties
2. Recreate it with the exact command above
3. Make sure passwords match your keystore password exactly
4. Run `flutter clean` before rebuilding

### File not found error?

1. Check keystore file location: `c:\CampusBound\frontend\campusbound.jks`
2. Check key.properties location: `c:\CampusBound\frontend\android\key.properties`
3. Verify storeFile path is: `../campusbound.jks`

### Wrong password error?

1. Passwords must match exactly
2. Passwords are case-sensitive
3. No extra spaces before or after

---

## Quick Fix Command

If you know your keystore password, run this (replace YOUR_PASSWORD):

```bash
cd c:\CampusBound\frontend\android
del key.properties
(
echo storePassword=YOUR_PASSWORD
echo keyPassword=YOUR_PASSWORD
echo keyAlias=campusbound
echo storeFile=../campusbound.jks
) > key.properties
cd ..
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## Do This Now

1. Run: `verify_and_fix_keystore.bat`
2. Follow the prompts
3. Run: `flutter build appbundle --release`
4. Report the result!
