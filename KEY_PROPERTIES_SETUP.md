# Key.properties Setup - Detailed Instructions

## ⚠️ Important: Your key.properties File is Missing or Incomplete

The build failed because the `key.properties` file either:
1. Doesn't exist
2. Has empty values
3. Has incorrect paths

---

## Step 1: Verify Keystore File Exists

Check if this file exists:
```
c:\CampusBound\campusbound.jks
```

**If it doesn't exist**, create it first:

```bash
keytool -genkey -v -keystore c:\CampusBound\campusbound.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campusbound
```

When prompted:
- Keystore password: `[Create a strong password - SAVE IT]`
- Re-enter password: `[Same password]`
- First and last name: Your Name
- Organization unit: Development
- Organization: CampusBound
- City: Your City
- State: Your State
- Country code: IN
- Confirm: yes
- Key password: `[Same as keystore password]`

---

## Step 2: Create key.properties File

**File location:** `c:\CampusBound\frontend\android\key.properties`

**⚠️ IMPORTANT**: This file is gitignored (won't be committed). You must create it manually.

### Option A: Using Text Editor

1. Open Notepad
2. Copy this content (replace YOUR_PASSWORD):

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=campusbound
storeFile=../campusbound.jks
```

3. Save as: `c:\CampusBound\frontend\android\key.properties`
   - File type: All Files (*)
   - Encoding: UTF-8

### Option B: Using Command Prompt

Run this command (replace YOUR_PASSWORD):

```bash
(
echo storePassword=YOUR_PASSWORD
echo keyPassword=YOUR_PASSWORD
echo keyAlias=campusbound
echo storeFile=../campusbound.jks
) > c:\CampusBound\frontend\android\key.properties
```

### Option C: Using PowerShell

Run this command (replace YOUR_PASSWORD):

```powershell
@"
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=campusbound
storeFile=../campusbound.jks
"@ | Out-File -FilePath "c:\CampusBound\frontend\android\key.properties" -Encoding UTF8
```

---

## Step 3: Verify File Contents

**Open the file and verify:**

```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=campusbound
storeFile=../campusbound.jks
```

**Check:**
- [ ] storePassword is filled in (not empty)
- [ ] keyPassword is filled in (not empty)
- [ ] keyAlias is "campusbound"
- [ ] storeFile is "../campusbound.jks"
- [ ] No extra spaces or quotes
- [ ] File is saved as UTF-8

---

## Step 4: Verify File Location

Make sure the file is at the correct location:

```
c:\CampusBound\frontend\android\key.properties
```

**NOT at:**
- `c:\CampusBound\frontend\key.properties` ❌
- `c:\CampusBound\key.properties` ❌
- `c:\CampusBound\frontend\android\key.properties.example` ❌

---

## Step 5: Rebuild

Now try building again:

```bash
cd c:\CampusBound\frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## Troubleshooting

### ❌ Error: "Execution failed for task ':app:signReleaseBundle'"
**Solution**: 
- Check key.properties file exists at correct location
- Verify all values are filled in (not empty)
- Make sure passwords match what you used for keystore

### ❌ Error: "java.lang.NullPointerException"
**Solution**:
- One or more values in key.properties is null/empty
- Check storeFile path is correct: `../campusbound.jks`
- Verify keyAlias is exactly: `campusbound`

### ❌ Error: "File not found"
**Solution**:
- Check keystore file exists: `c:\CampusBound\campusbound.jks`
- Check storeFile path in key.properties is correct

### ❌ Error: "Invalid keystore"
**Solution**:
- Keystore file might be corrupted
- Delete `campusbound.jks` and recreate it
- Make sure you used the exact keytool command

### ❌ Error: "Wrong password"
**Solution**:
- Passwords in key.properties must match keystore passwords exactly
- Passwords are case-sensitive
- No extra spaces

---

## File Format Reference

### Correct Format:
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=campusbound
storeFile=../campusbound.jks
```

### Incorrect Formats (DON'T DO THIS):

```properties
# ❌ Extra spaces
storePassword = MySecurePassword123!

# ❌ Quotes around values
storePassword="MySecurePassword123!"

# ❌ Empty values
storePassword=
keyPassword=

# ❌ Wrong path
storeFile=c:\CampusBound\campusbound.jks

# ❌ Wrong alias
keyAlias=my-key
```

---

## Security Reminder

✅ **DO**:
- Keep passwords safe
- Use strong passwords
- Back up keystore file
- Keep key.properties secure

❌ **DON'T**:
- Commit to Git (it's gitignored)
- Share with anyone
- Use weak passwords
- Lose keystore file

---

## Next Steps

1. Create keystore file (if not done)
2. Create key.properties file with correct values
3. Verify file location and contents
4. Run: `flutter build appbundle --release`
5. Verify signature: `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`
6. Upload to Google Play Console

---

## Quick Checklist

- [ ] Keystore file exists: `c:\CampusBound\campusbound.jks`
- [ ] key.properties file exists: `c:\CampusBound\frontend\android\key.properties`
- [ ] storePassword is filled in
- [ ] keyPassword is filled in
- [ ] keyAlias is "campusbound"
- [ ] storeFile is "../campusbound.jks"
- [ ] No extra spaces or quotes
- [ ] File saved as UTF-8

Once all checked, run: `flutter build appbundle --release`
