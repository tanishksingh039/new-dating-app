# App Signing Configuration - Complete Setup Guide

## ✅ What Was Done

The `build.gradle.kts` file has been updated to support release signing. Now you need to:

1. Create a keystore file
2. Create the key.properties file
3. Build the signed release bundle

---

## Step 1: Create Keystore File

Open **Command Prompt** or **PowerShell** and run:

```bash
keytool -genkey -v -keystore c:\CampusBound\campusbound.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campusbound
```

**You'll be prompted to enter information. Here's an example:**

```
Enter keystore password: MySecurePassword123!
Re-enter new password: MySecurePassword123!
What is your first and last name? [Unknown]: Your Name
What is the name of your organizational unit? [Unknown]: Development
What is the name of your organization? [Unknown]: CampusBound
What is the name of your City or Locality? [Unknown]: Your City
What is the name of your State or Province? [Unknown]: Your State
What is the two-letter country code for this unit? [Unknown]: IN
Is CN=Your Name, OU=Development, O=CampusBound, L=Your City, ST=Your State, C=IN correct? [no]: yes
Enter key password for <campusbound>: MySecurePassword123!
Re-enter new password: MySecurePassword123!
```

**⚠️ IMPORTANT**: 
- Save the keystore password somewhere safe
- Save the key password somewhere safe
- You'll need these every time you build

**Output**: A file `campusbound.jks` will be created in `c:\CampusBound\`

---

## Step 2: Create key.properties File

Create a new file at: `c:\CampusBound\frontend\android\key.properties`

**Copy this template and fill in your values:**

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=campusbound
storeFile=../campusbound.jks
```

**Example with actual values:**

```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=campusbound
storeFile=../campusbound.jks
```

**⚠️ SECURITY WARNING**: 
- This file is already in `.gitignore` (won't be committed)
- Never share this file
- Never commit it to Git
- Keep it safe and secure

---

## Step 3: Verify File Locations

Make sure these files exist:

```
c:\CampusBound\
├── campusbound.jks                          ← Keystore file
└── frontend\
    └── android\
        └── key.properties                   ← Properties file
```

---

## Step 4: Build Signed Release Bundle

Open **Command Prompt** in the project directory and run:

```bash
cd c:\CampusBound\frontend

# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Build the signed app bundle
flutter build appbundle --release
```

**Expected output:**
```
Running Gradle task 'bundleRelease'...
✓ Built build/app/outputs/bundle/release/app-release.aab
```

---

## Step 5: Verify the Signature

To verify your app bundle is properly signed, run:

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

**You should see:**
```
jar verified.
```

If you see `jar is unsigned`, something went wrong. Go back to Step 2.

---

## Step 6: Upload to Google Play Console

1. Go to **Google Play Console**
2. Navigate to **"Test and release" → "Internal testing"**
3. Click **"Create new release"**
4. Upload the AAB file: `build/app/outputs/bundle/release/app-release.aab`
5. Add release notes
6. Click **"Save"**
7. Click **"Review release"**
8. Click **"Start rollout to Internal testing"**

---

## Troubleshooting

### ❌ Error: "key.properties not found"
**Solution**: 
- Make sure the file is at: `c:\CampusBound\frontend\android\key.properties`
- Check spelling and path

### ❌ Error: "Invalid keystore format"
**Solution**:
- Delete `campusbound.jks` and recreate it from Step 1
- Make sure you used the exact command

### ❌ Error: "Wrong password"
**Solution**:
- Verify passwords in `key.properties` match what you entered
- Make sure there are no extra spaces
- Passwords are case-sensitive

### ❌ Error: "jar is unsigned"
**Solution**:
- Go back to Step 2 and verify `key.properties`
- Make sure all values are correct
- Run `flutter clean` and rebuild

### ❌ Error: "Cannot find keystore file"
**Solution**:
- Make sure `campusbound.jks` is in `c:\CampusBound\`
- Check the path in `key.properties` is correct: `../campusbound.jks`

---

## File Contents Reference

### key.properties (Example)
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=campusbound
storeFile=../campusbound.jks
```

### build.gradle.kts (Updated)
The file now includes:
- Keystore properties loading
- Release signing configuration
- Proper signing config for release builds

---

## Security Best Practices

✅ **DO**:
- Keep `key.properties` secure
- Keep `campusbound.jks` safe
- Use strong passwords
- Back up your keystore file
- Store passwords in a password manager

❌ **DON'T**:
- Commit `key.properties` to Git
- Commit `campusbound.jks` to Git
- Share these files
- Use weak passwords
- Lose your keystore file (you can't recover it!)

---

## Next Steps

1. ✅ Create keystore file (Step 1)
2. ✅ Create key.properties (Step 2)
3. ✅ Verify file locations (Step 3)
4. ✅ Build signed bundle (Step 4)
5. ✅ Verify signature (Step 5)
6. ✅ Upload to Play Console (Step 6)

---

## Quick Commands Reference

```bash
# Create keystore
keytool -genkey -v -keystore c:\CampusBound\campusbound.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campusbound

# Build signed bundle
flutter clean && flutter pub get && flutter build appbundle --release

# Verify signature
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# Check Java version
java -version

# Check Flutter setup
flutter doctor -v
```

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all file paths are correct
3. Run `flutter doctor -v` to check setup
4. Check that Java is installed: `java -version`
5. Contact Google Play Support if account issues persist

---

## Summary

Your app is now configured for release signing! The build.gradle.kts file will:
- Load your keystore properties
- Sign the release bundle with your key
- Create a properly signed APK/AAB for Google Play

Once you complete the steps above, your app will be ready for internal testing on Google Play Console.
