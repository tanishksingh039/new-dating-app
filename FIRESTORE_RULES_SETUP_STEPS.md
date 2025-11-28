# 🔧 Firestore Rules Setup - Step by Step

## ❌ Error You're Getting
```
Error sending notification: [cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation
```

## ✅ Solution: Update Firestore Security Rules

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project (CampusBound)
3. Go to **Firestore Database** (left sidebar)
4. Click on **Rules** tab

### Step 2: Copy the Updated Rules

Copy the complete rules from the file: `FIRESTORE_RULES_UPDATED.txt`

**Key sections to ensure are present:**

#### A. User Notifications Subcollection (Lines 68-77)
```firestore
match /users/{userId} {
  // ... other rules ...
  
  match /notifications/{notificationId} {
    allow read: if isOwner(userId);
    allow write: if isAuthenticated();  // ✅ CRITICAL
    allow delete: if isOwner(userId) || isAuthenticated();
  }
}
```

#### B. Global Notifications Collection (Lines 262-273)
```firestore
match /notifications/{notificationId} {
  allow read: if true;
  allow create: if isAuthenticated();
  allow update: if isAuthenticated();
  allow delete: if isAuthenticated();
}
```

### Step 3: Paste Rules into Firebase Console

1. In Firebase Console, click the **Edit** button in the Rules tab
2. **Clear all existing rules** (Ctrl+A, Delete)
3. **Paste the complete updated rules** from `FIRESTORE_RULES_UPDATED.txt`
4. Review the rules to ensure they look correct

### Step 4: Publish Rules

1. Click the **Publish** button (top right)
2. Wait for confirmation message: "Rules updated successfully"
3. ✅ Rules are now live

### Step 5: Test in Firebase Console (Optional)

1. Go to **Rules** tab
2. Click **Simulate** button
3. Fill in test parameters:
   - **Collection path**: `users/test-user/notifications`
   - **Document ID**: `test-notification`
   - **Request type**: `write`
   - **Authenticated**: Toggle ON
   - **UID**: `any-uid`
4. Click **Run** - should show ✅ **Allowed**

---

## 🧪 Testing the Fix

### After Publishing Rules:

1. **Go to Admin Dashboard** → **Notifications** tab
2. **Fill in the form:**
   - Select Target Audience: "Male Users" (or any option)
   - Notification Type: "Match"
   - Title: "Test Title"
   - Message: "Test Message"
3. **Click "Send Notification"**
4. ✅ Should see success message instead of error

---

## 🔍 Troubleshooting

### Still Getting Permission Denied?

**Check 1: Rules are Published**
- Go to Firebase Console → Firestore → Rules
- Verify the rules are showing (not in draft mode)
- Look for green checkmark next to "Published"

**Check 2: Correct Rules are in Place**
- Search for `allow write: if isAuthenticated();` in the notifications subcollection
- Verify it's inside the `match /users/{userId}/notifications/{notificationId}` block

**Check 3: Admin is Authenticated**
- Make sure you're logged in to the admin panel
- Check browser console: `FirebaseAuth.instance.currentUser` should not be null

**Check 4: Firestore Database Exists**
- Go to Firebase Console → Firestore Database
- Verify the database is created and active
- Should show "Cloud Firestore" in the left sidebar

**Check 5: Clear Browser Cache**
- Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
- Clear all browser cache
- Reload the admin panel

---

## 📋 Complete Rules Checklist

Before publishing, verify these sections exist in your rules:

- [ ] `function isAuthenticated()` defined
- [ ] `function isOwner(userId)` defined
- [ ] `function isAdmin()` defined
- [ ] `/users/{userId}` collection rules
- [ ] `/users/{userId}/notifications/{notificationId}` subcollection with `allow write: if isAuthenticated();`
- [ ] `/notifications/{notificationId}` global collection with `allow create: if isAuthenticated();`
- [ ] `/matches/{matchId}` collection rules
- [ ] `/chats/{chatId}` collection rules
- [ ] `/swipes/{swipeId}` collection rules
- [ ] `/payment_orders/{orderId}` collection rules
- [ ] Default deny rule at the end: `match /{document=**} { allow read, write: if false; }`

---

## 🚀 After Rules are Published

1. **Restart the app** (optional but recommended)
2. **Test sending a notification**
3. **Check Firestore Console** to verify data is being written
4. **View notification history** in the History & Stats tab

---

## 📞 If Still Having Issues

1. **Check Firebase Console Logs:**
   - Go to Firestore → Data
   - Look for `notifications` collection
   - Verify documents are being created

2. **Check Browser Console:**
   - Open Developer Tools (F12)
   - Go to Console tab
   - Look for any error messages

3. **Verify Admin User:**
   - Make sure you're logged in as an admin
   - Check that `FirebaseAuth.instance.currentUser` is not null

4. **Test with Firestore Emulator (Advanced):**
   - Use Firebase Emulator Suite for local testing
   - Helps isolate permission issues

---

## ✨ Success Indicators

After rules are published and working:

✅ No "permission denied" error  
✅ Notification appears in global `notifications` collection  
✅ Notifications appear in user subcollections  
✅ Admin can view notification history  
✅ Sent count increases  

---

## 📝 Important Notes

- Rules take **1-2 minutes** to propagate globally
- Always test after publishing
- Keep a backup of working rules
- Don't modify rules during testing

---

**Need help? Check the error message in the red banner at the bottom of the admin panel for specific details!**
