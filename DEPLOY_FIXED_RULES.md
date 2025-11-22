# Deploy Fixed Firestore Rules

## Issue Fixed
The `isAdmin()` function had syntax warnings that were preventing it from working correctly.

## What Was Fixed
- Removed `exists()` check (causing warning)
- Removed `.get('role', '')` method (causing warning)  
- Simplified to: `get(...).data.role == 'admin'`
- Used `isAdmin()` function instead of inline checks

## Deploy Now

```bash
cd c:\CampusBound\frontend
firebase deploy --only firestore:rules
```

## Expected Output (No Warnings)
```
+  cloud.firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
+  firestore: released rules firestore.rules to cloud.firestore
+  Deploy complete!
```

## Then Set Admin Role

1. Go to Firebase Console: https://console.firebase.google.com
2. Firestore Database → Data
3. Click `users` collection
4. Find YOUR user document
5. Add field:
   - Field: `role`
   - Type: `string`
   - Value: `admin`
6. Save

## Then Restart App

```bash
# Stop app (Ctrl+C)
flutter run
```

## This Will Fix
- ✅ No more warnings in rules
- ✅ `isAdmin()` function works correctly
- ✅ Admin panel users tab will load
- ✅ All permission errors resolved

Deploy now!
