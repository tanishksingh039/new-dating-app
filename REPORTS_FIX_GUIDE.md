# 🔧 Admin Reports Tab - Fix Guide

## Problem
The Reports tab shows "Error fetching reports" message.

## Common Causes

### 1. Missing Firestore Index
The query uses `.orderBy('createdAt', descending: true)` which requires a Firestore index.

**Solution:**
1. Check the error message in the console
2. If it mentions "index", click the link in the error
3. Firebase will create the index automatically
4. Wait 1-2 minutes for index to build

### 2. Firestore Rules
Reports collection might not have read permissions.

**Check Rules:**
```firestore
match /reports/{reportId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
}
```

**For Admin Panel (Temporary):**
```firestore
match /reports/{reportId} {
  allow read: if true;  // Open read for admin panel
  allow create: if isAuthenticated();
}
```

### 3. No Reports Exist
If there are no reports in the database, it will show empty state.

**Test by creating a report:**
- Use the app to report a user
- Check Firestore Console → reports collection

---

## Debugging Steps

### Step 1: Check Console Logs
1. Open browser console (F12)
2. Look for logs starting with `[AdminReportsTab]`
3. Check the error message

### Step 2: Check Firestore Console
1. Go to Firebase Console
2. Firestore Database → Data
3. Check if `reports` collection exists
4. Check if documents have `createdAt` field

### Step 3: Check Firestore Rules
1. Go to Firebase Console
2. Firestore Database → Rules
3. Search for `match /reports/{reportId}`
4. Verify `allow read` rule exists

### Step 4: Create Test Report
```dart
// In Firestore Console, add a test document
{
  "reporterId": "test123",
  "reportedUserId": "user456",
  "reportedUserName": "Test User",
  "reason": "inappropriate_content",
  "description": "Test report",
  "status": "pending",
  "createdAt": Timestamp.now()
}
```

---

## Quick Fixes

### Fix 1: Remove orderBy (Temporary)
If index is the issue, temporarily remove ordering:

```dart
stream: FirebaseFirestore.instance
    .collection('reports')
    // .orderBy('createdAt', descending: true)  // Comment out
    .snapshots(),
```

### Fix 2: Update Firestore Rules
Add open read access for admin panel:

```firestore
match /reports/{reportId} {
  allow read: if true;
  allow create: if isAuthenticated();
  allow update: if isAuthenticated();
  allow delete: if isAuthenticated();
}
```

### Fix 3: Create Firestore Index
1. Run the app
2. Check console for error with link
3. Click the link to create index
4. Wait for index to build

---

## Expected Behavior

### Success State
- Shows tabs: All, Pending, Reviewing, Resolved
- Lists reports with user names
- Shows status badges
- Allows viewing details

### Empty State
- Shows "No reports found" message
- Shows inbox icon
- No error message

### Error State
- Shows error icon
- Shows error message
- Shows "Retry" button

---

## Verification

After fixing, verify:
- [ ] Reports tab loads without error
- [ ] Can see list of reports (if any exist)
- [ ] Can switch between tabs
- [ ] Can click on report to view details
- [ ] Status badges show correctly

---

## Next Steps

1. **Hot restart the app**
2. **Go to Admin Panel → Reports tab**
3. **Check console logs** for error details
4. **Apply appropriate fix** based on error message
5. **Verify reports load** successfully

---

**The error message will now show the exact issue!** 🎯
