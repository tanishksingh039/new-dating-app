# 🔍 Phone OTP Login - Debug Guide

**Status:** Enhanced error handling added  
**Date:** November 20, 2025

---

## 🎯 What Was Fixed

### 1. **Comprehensive Error Handling in Wrapper**
- Added error check in FutureBuilder
- Added null check before type casting
- Added type check with runtime type logging
- Added stack trace logging
- Multiple fallback points to WelcomeScreen

### 2. **Enhanced OTP Verification**
- Increased delay to 1 second after Firestore write
- Added document verification after save
- Better logging at each step

### 3. **Global Error Handler**
- Catches all Flutter errors
- Logs exception and stack trace
- Helps identify exact error location

---

## 🔍 Debug Flow

When you test phone OTP login, you should see these logs:

```
[OtpScreen] Verifying OTP...
[OtpScreen] OTP verified successfully! User ID: xxx
[OtpScreen] User data saved to Firestore with phone number
[OtpScreen] User document verified in Firestore
[OtpScreen] Navigating to wrapper screen...
[WrapperScreen] Document data is null OR
[WrapperScreen] User data is null or empty, navigating to WelcomeScreen OR
[WrapperScreen] Onboarding incomplete, navigating to WelcomeScreen OR
[WrapperScreen] Onboarding complete, navigating to HomeScreen
```

---

## 🚨 If Error Still Occurs

### The error screen will now show:
```
Flutter Error: type 'Null' is not a subtype of type 'Map<dynamic, dynamic>'
Stack trace: [full stack trace]
```

### Check the console for:
1. **Which line caused the error** (from stack trace)
2. **What the data type was** (from runtime type log)
3. **Whether document exists** (from existence check)

---

## 🧪 Testing Steps

### 1. Clean Build
```bash
cd c:\CampusBound\frontend
flutter clean
flutter pub get
```

### 2. Run on Android Device
```bash
flutter run
# Select your Android device (not Windows/Chrome)
```

### 3. Test Login
1. Enter phone number
2. Enter OTP
3. **Watch the console output**
4. Take screenshot of any error
5. Copy console logs

---

## 📝 What to Report

If error still occurs, provide:

1. **Full console output** starting from:
   ```
   [OtpScreen] Verifying OTP...
   ```

2. **Error screenshot** (if different from before)

3. **Stack trace** from console

4. **Device info:**
   - Android version
   - Device model
   - App version

---

## 🎯 Expected Behavior

### For New User:
```
Login → OTP → Splash (3s) → Wrapper → WelcomeScreen (onboarding)
```

### For Existing User (Incomplete Profile):
```
Login → OTP → Splash (3s) → Wrapper → WelcomeScreen (continue onboarding)
```

### For Existing User (Complete Profile):
```
Login → OTP → Splash (3s) → Wrapper → HomeScreen
```

---

## 🔧 Technical Details

### Error Location Possibilities:

1. **Wrapper Screen (Line 65-74)** - Document data casting
2. **Wrapper Screen (Line 86)** - Onboarding flag check
3. **Wrapper Screen (Line 100)** - Name field access
4. **Wrapper Screen (Line 102-107)** - Photos field access

All these are now wrapped in try-catch with logging.

---

## ✅ What Should Work Now

1. ✅ Null document data → Navigate to WelcomeScreen
2. ✅ Empty document data → Navigate to WelcomeScreen
3. ✅ Wrong data type → Navigate to WelcomeScreen
4. ✅ Cast error → Navigate to WelcomeScreen
5. ✅ Any error → Log and recover gracefully

---

**Next Step:** Run the app and check console logs

---

*Debug Guide Created: November 20, 2025*  
*ShooLuv - Campus Dating Made Simple* 💕
