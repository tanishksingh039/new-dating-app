# 🔍 Debugging Duplicate Document Creation

## ✅ What I've Done

### 1. Fixed All Update Methods
Changed from `.update()` to `.set(merge: true)` in:
- ✅ `updateUserProfile()` - All onboarding screens use this
- ✅ `savePhotos()` - Photo uploads
- ✅ `completeOnboarding()` - Completion flag
- ✅ `saveOnboardingStep()` - Already correct

### 2. Added Comprehensive Monitoring
Created `FirestoreMonitor` that tracks:
- ✅ When documents are created (with stack trace!)
- ✅ When documents are updated
- ✅ Duplicate document detection
- ✅ Real-time monitoring of all Firestore operations

### 3. Enhanced Logging
All Firebase operations now log:
- ✅ User ID being operated on
- ✅ Fields being updated
- ✅ Success/failure status
- ✅ Detailed context

## 🧪 Testing Steps

### Step 1: Clean Start
1. **Delete ALL existing user documents** in Firebase Console
2. **Uninstall the app** completely
3. **Reinstall the app**

### Step 2: Run the App
```bash
flutter run
```

### Step 3: Watch Console Logs

You'll now see **DETAILED LOGS** showing exactly when documents are created:

#### When You Sign In:
```
[FirebaseServices] ═══════════════════════════════════════
[FirebaseServices] Saving user data to Firestore...
[FirebaseServices] User ID: abc123xyz
[FirebaseServices] Email: your@email.com
[FirebaseServices] 🆕 Creating NEW user document...
[FirebaseServices] ✅ New user document created successfully!
[FirebaseServices] 📋 Document ID: abc123xyz
[FirebaseServices] ═══════════════════════════════════════

[FirestoreMonitor] ═══════════════════════════════════════
[FirestoreMonitor] 🆕 DOCUMENT CREATED!
[FirestoreMonitor] Document ID: abc123xyz
[FirestoreMonitor] Current User ID: abc123xyz
[FirestoreMonitor] Match: ✅ SAME
[FirestoreMonitor] Email: your@email.com
[FirestoreMonitor] Stack trace: [shows where it was created]
[FirestoreMonitor] ═══════════════════════════════════════
```

#### During Onboarding (Basic Info):
```
[FirebaseServices] ═══════════════════════════════════════
[FirebaseServices] 📝 Saving onboarding step...
[FirebaseServices] User ID: abc123xyz  ← SHOULD BE SAME!
[FirebaseServices] Fields: name, dateOfBirth, age, gender
[FirebaseServices] ✅ Onboarding step saved successfully
[FirebaseServices] ═══════════════════════════════════════

[FirestoreMonitor] ───────────────────────────────────────
[FirestoreMonitor] 📝 DOCUMENT UPDATED
[FirestoreMonitor] Document ID: abc123xyz  ← SHOULD BE SAME!
[FirestoreMonitor] Fields updated: name, dateOfBirth, age, gender
[FirestoreMonitor] ───────────────────────────────────────
```

#### If Duplicate is Created (THIS IS THE PROBLEM):
```
[FirestoreMonitor] ═══════════════════════════════════════
[FirestoreMonitor] 🆕 DOCUMENT CREATED!
[FirestoreMonitor] Document ID: xyz789abc  ← DIFFERENT!!!
[FirestoreMonitor] Current User ID: abc123xyz
[FirestoreMonitor] Match: ❌ DIFFERENT!  ← PROBLEM DETECTED!
[FirestoreMonitor] Stack trace:
  #0      FirestoreMonitor.startMonitoring.<anonymous closure>
  #1      _RootZone.runUnaryGuarded
  ... [this will show EXACTLY where the duplicate was created]
[FirestoreMonitor] ═══════════════════════════════════════
```

### Step 4: Check for Duplicates

The app will automatically check for duplicates:

```
[FirestoreMonitor] ═══════════════════════════════════════
[FirestoreMonitor] 🔍 CHECKING FOR DUPLICATE DOCUMENTS
[FirestoreMonitor] Current User ID: abc123xyz
[FirestoreMonitor] Email: your@email.com
[FirestoreMonitor] ───────────────────────────────────────
[FirestoreMonitor] ✅ Only ONE document found
[FirestoreMonitor] Document ID: abc123xyz
[FirestoreMonitor] Matches current user: ✅ YES
[FirestoreMonitor] ═══════════════════════════════════════
```

OR if duplicates exist:

```
[FirestoreMonitor] ❌ DUPLICATE DOCUMENTS DETECTED!
[FirestoreMonitor] Found 2 documents:
[FirestoreMonitor] 
[FirestoreMonitor] Document 1:
[FirestoreMonitor]   ID: abc123xyz
[FirestoreMonitor]   Current: ✅ YES
[FirestoreMonitor]   Name: John Doe
[FirestoreMonitor]   Onboarding: true
[FirestoreMonitor] 
[FirestoreMonitor] Document 2:
[FirestoreMonitor]   ID: xyz789abc
[FirestoreMonitor]   Current: ❌ NO
[FirestoreMonitor]   Name: 
[FirestoreMonitor]   Onboarding: false
```

## 🎯 What to Look For

### ✅ GOOD SIGNS (Working Correctly):
1. **Same User ID** in all logs
2. **Only ONE "DOCUMENT CREATED"** message (at sign-in)
3. **All subsequent operations show "DOCUMENT UPDATED"**
4. **Duplicate check shows "Only ONE document found"**

### ❌ BAD SIGNS (Still Has Issues):
1. **Different User IDs** in logs
2. **Multiple "DOCUMENT CREATED"** messages
3. **"Match: ❌ DIFFERENT!"** in monitor logs
4. **Duplicate check shows multiple documents**

## 📋 Copy This Console Output

When you run the app, **copy the ENTIRE console output** and send it to me. Look for:

1. **All lines with `[FirebaseServices]`** - Shows when data is saved
2. **All lines with `[FirestoreMonitor]`** - Shows when documents are created/updated
3. **Any lines with `❌ DIFFERENT!`** - Shows if wrong document is being used
4. **Stack traces** - Shows WHERE the duplicate is being created

## 🔧 If Duplicates Still Occur

If you still see duplicates being created, the stack trace will tell us EXACTLY where it's happening. Look for the stack trace in the "DOCUMENT CREATED" log - it will show the file and line number.

## 📝 Example of What to Send Me

```
[LoginScreen] Starting Google Sign-In flow...
[LoginScreen] User ID: abc123xyz
[FirebaseServices] User ID: abc123xyz
[FirebaseServices] 🆕 Creating NEW user document...
[FirestoreMonitor] 🆕 DOCUMENT CREATED! Document ID: abc123xyz

[BasicInfoScreen] Saving basic info...
[FirebaseServices] User ID: abc123xyz  ← Check if SAME
[FirestoreMonitor] 📝 DOCUMENT UPDATED Document ID: abc123xyz  ← Check if SAME

[FirestoreMonitor] ✅ Only ONE document found  ← This is what we want!
```

OR if there's a problem:

```
[LoginScreen] User ID: abc123xyz
[FirebaseServices] User ID: abc123xyz
[FirestoreMonitor] 🆕 DOCUMENT CREATED! Document ID: abc123xyz

[BasicInfoScreen] Saving basic info...
[FirebaseServices] User ID: xyz789abc  ← DIFFERENT! PROBLEM!
[FirestoreMonitor] 🆕 DOCUMENT CREATED! Document ID: xyz789abc  ← DUPLICATE!
[FirestoreMonitor] Match: ❌ DIFFERENT!
[FirestoreMonitor] Stack trace:
  #0 ... [shows where duplicate was created]

[FirestoreMonitor] ❌ DUPLICATE DOCUMENTS DETECTED!
```

## 🚀 Next Steps

1. **Run the app** with these monitoring tools
2. **Sign in** and complete onboarding
3. **Copy ALL console logs**
4. **Send them to me**
5. I'll analyze the stack trace to find EXACTLY where the duplicate is being created

The monitoring is now so detailed that we'll catch the exact moment and location where any duplicate document is created! 🎯
