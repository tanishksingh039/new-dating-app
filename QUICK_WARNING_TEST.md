# Quick Warning Test - 3 Steps ⚡

## Test the Warning Popup Right Now

### Step 1: Issue Warning (Admin Panel)
1. Open Admin Panel → Reports tab
2. Click on any report
3. Click "Issue Warning" (orange button)
4. Watch console for: `✅ Notification sent to user`

### Step 2: Verify in Firestore
1. Open Firebase Console → Firestore
2. Go to: `users/{reportedUserId}/notifications`
3. Find the newest notification
4. Check it has:
   - `type: "admin_action"`
   - `data.action: "warning"`
   - `read: false`

### Step 3: See Warning Popup
**Do ONE of these:**
- **Option A:** Close app completely, then reopen
- **Option B:** Hot restart the app
- **Option C:** Switch to a different tab (Discovery → Likes)

**Expected Result:** 
🟠 Orange warning screen should appear with:
- ⚠️ Warning Issued
- Reason for warning
- Community guidelines
- "I Understand" button

## If Warning Doesn't Appear

### Quick Fix 1: Check Console
Look for these logs:
```
[AdminActionChecker] 🔍 Checking admin actions
[ActionNotificationService] Found X documents
```

If `Found 0 documents` → Notification not created or already read

### Quick Fix 2: Create Test Notification
1. Firebase Console → Firestore
2. Go to: `users/{YOUR_USER_ID}/notifications`
3. Click "Add Document"
4. Paste this:
```json
{
  "title": "⚠️ Warning Issued",
  "body": "Test warning",
  "type": "admin_action",
  "data": {
    "action": "warning",
    "reason": "Test",
    "reportId": "test"
  },
  "read": false,
  "createdAt": "2025-11-29T16:00:00Z",
  "priority": "high"
}
```
5. Close and reopen app → Warning should appear

### Quick Fix 3: Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

## Console Logs When Working

**Success logs:**
```
[AdminReportsTab] ✅ Notification sent to user
[AdminActionChecker] 🔍 Checking admin actions
[ActionNotificationService] Found 1 documents
[ActionNotificationService] Action: warning
[AdminActionChecker] 🔔 Showing warning screen...
```

**Failure logs:**
```
[ActionNotificationService] Found 0 documents
[ActionNotificationService] ℹ️ No pending notifications found
```

## Summary

✅ Warning system is **fully implemented**
✅ Should work when admin issues warning
✅ Appears on app launch or tab change
✅ Full-screen orange warning with guidelines

If still not working after these steps, check `WARNING_POPUP_TEST_GUIDE.md` for detailed troubleshooting.
