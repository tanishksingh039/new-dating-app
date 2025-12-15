# App Signing - Quick Checklist

## ✅ Pre-Setup Checklist

- [ ] Java is installed (`java -version` works)
- [ ] Flutter is installed (`flutter --version` works)
- [ ] You have the project open
- [ ] You know a strong password to use

---

## ✅ Step 1: Create Keystore

**Command:**
```bash
keytool -genkey -v -keystore c:\CampusBound\campusbound.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campusbound
```

**When prompted, enter:**
- Keystore password: `[YOUR_PASSWORD]` ← SAVE THIS
- Key password: `[YOUR_PASSWORD]` ← SAVE THIS
- First and last name: Your Name
- Organization unit: Development
- Organization: CampusBound
- City: Your City
- State: Your State
- Country code: IN
- Confirm: yes

**Verify:**
- [ ] File created: `c:\CampusBound\campusbound.jks`
- [ ] Passwords saved safely

---

## ✅ Step 2: Create key.properties

**File location:** `c:\CampusBound\frontend\android\key.properties`

**Content:**
```properties
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=campusbound
storeFile=../campusbound.jks
```

**Example:**
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=campusbound
storeFile=../campusbound.jks
```

**Verify:**
- [ ] File created at correct location
- [ ] Passwords match what you entered
- [ ] No extra spaces in file

---

## ✅ Step 3: Verify File Locations

```
c:\CampusBound\
├── campusbound.jks                          ✓
└── frontend\
    └── android\
        ├── key.properties                   ✓
        └── app\
            └── build.gradle.kts             ✓ (already updated)
```

**Verify:**
- [ ] campusbound.jks exists in c:\CampusBound\
- [ ] key.properties exists in c:\CampusBound\frontend\android\
- [ ] build.gradle.kts is updated (check for signingConfigs)

---

## ✅ Step 4: Build Signed Bundle

**Commands:**
```bash
cd c:\CampusBound\frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

**Expected output:**
```
✓ Built build/app/outputs/bundle/release/app-release.aab
```

**Verify:**
- [ ] Build completes successfully
- [ ] AAB file created at: `build/app/outputs/bundle/release/app-release.aab`
- [ ] File size is reasonable (50-100 MB)

---

## ✅ Step 5: Verify Signature

**Command:**
```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

**Expected output:**
```
jar verified.
```

**Verify:**
- [ ] Output shows "jar verified"
- [ ] No "jar is unsigned" message

---

## ✅ Step 6: Upload to Google Play Console

1. [ ] Go to Google Play Console
2. [ ] Navigate to "Test and release" → "Internal testing"
3. [ ] Click "Create new release"
4. [ ] Upload: `build/app/outputs/bundle/release/app-release.aab`
5. [ ] Add release notes
6. [ ] Click "Save"
7. [ ] Click "Review release"
8. [ ] Click "Start rollout to Internal testing"

**Verify:**
- [ ] Upload successful
- [ ] No signing errors
- [ ] Release shows as "Rolled out"

---

## 🚨 If Something Goes Wrong

| Error | Solution |
|-------|----------|
| key.properties not found | Check file path: `c:\CampusBound\frontend\android\key.properties` |
| Invalid keystore format | Delete `campusbound.jks` and recreate from Step 1 |
| Wrong password | Verify passwords in `key.properties` match exactly |
| jar is unsigned | Check `key.properties` values are correct, rebuild |
| Build fails | Run `flutter clean` and try again |

---

## 📝 Passwords to Save

**Keystore Password:** `_____________________`

**Key Password:** `_____________________`

(Write these down somewhere safe!)

---

## ✅ Final Verification

- [ ] All steps completed
- [ ] AAB file created and signed
- [ ] Signature verified
- [ ] Uploaded to Google Play Console
- [ ] No errors in upload
- [ ] Ready for internal testing!

---

## 🎉 You're Done!

Your app is now:
✅ Properly signed for release
✅ Ready for Google Play Console
✅ Ready for internal testing
✅ Ready for production release

Next: Monitor internal testers and collect feedback!
