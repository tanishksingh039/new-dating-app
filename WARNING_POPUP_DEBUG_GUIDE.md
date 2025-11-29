# Warning Popup Not Showing - Debug Guide 🔍

## Issue
Warning popup is not appearing on the reported user's screen when they switch tabs.

## Enhanced Debug Logging Added

I've added comprehensive logging to help diagnose the issue. When you run the app, look for these logs in the console:

### 1. AdminActionChecker Logs
```
[AdminActionChecker] ═══════════════════════════════════════
[AdminActionChecker] 🔍 Checking admin actions for: {userId}
[AdminActionChecker] ═══════════════════════════════════════
[AdminActionChecker] Step 1: Checking ban status...
[AdminActionChecker] Ban status result: {banStatus}
[AdminActionChecker] Step 2: Fetching pending notifications...
[AdminActionChecker] 📬 Notifications count: {count}
```

### 2. ActionNotificationService Logs
```
[ActionNotificationService] ═══════════════════════════════════════
[ActionNotificationService] 📡 Fetching pending action notifications
[ActionNotificationService] User ID: {userId}
[ActionNotificationService] Path: users/{userId}/notifications
[ActionNotificationService] Query: type=admin_action, read=false
[ActionNotificationService] 📊 Query completed
[ActionNotificationService] Found {count} documents
```

## Debugging Steps

### Step 1: Check if Notification Was Created
When admin issues a warning, look for these logs:
```
[AdminReportsTab] Sending notification to user
[AdminReportsTab] User ID: {reportedUserId}
[AdminReportsTab] Notification Title: ⚠️ Warning Issued
[AdminReportsTab] Notification Body: You have received a warning for {reason}...
[AdminReportsTab] ✅ Notification sent to user
[AdminReportsTab] Notification ID: {notificationId}
[AdminReportsTab] Path: users/{userId}/notifications/{notificationId}
```

### Step 2: Verify User ID Matches
1. Check the **reported user's ID** in admin logs
2. Check the **logged-in user's ID** in AdminActionChecker logs
3. **They must match** for the warning to show

### Step 3: Check Firestore Data
Go to Firebase Console → Firestore Database:
```
users/{reportedUserId}/notifications/{notificationId}
{
  title: "⚠️ Warning Issued",
  body: "You have received a warning for Spam...",
  type: "admin_action",
  data: {
    action: "warning",
    reason: "Spam",
    reportId: "..."
  },
  read: false,  ← Must be false
  createdAt: Timestamp,
  priority: "high"
}
```

### Step 4: Check for Common Issues

#### Issue 1: Notification Not Created
**Symptoms:**
```
[AdminReportsTab] ❌ Error sending notification: permission-denied
```

**Solution:**
- Check Firestore rules allow write to `users/{userId}/notifications`
- Rule should be: `allow write: if true;`

#### Issue 2: Wrong User ID
**Symptoms:**
```
[ActionNotificationService] Found 0 documents
[ActionNotificationService] ℹ️ No pending notifications found
```

**Solution:**
- Verify you're logged in as the **reported user**, not the admin
- Check user ID in logs matches the notification path

#### Issue 3: Notification Already Read
**Symptoms:**
```
[ActionNotificationService] Found 0 documents
[ActionNotificationService] 2. All notifications are read
```

**Solution:**
- Check Firestore: notification has `read: true`
- Delete the notification and issue a new warning

#### Issue 4: Permission Denied
**Symptoms:**
```
[ActionNotificationService] 🔐 PERMISSION DENIED
```

**Solution:**
- Check Firestore rules allow read from `users/{userId}/notifications`
- Rule should be: `allow read: if true;`

#### Issue 5: Widget Not Mounted
**Symptoms:**
```
[AdminActionChecker] ⚠️ Widget not mounted, cannot show dialog
```

**Solution:**
- This is a timing issue
- Try switching tabs again
- The widget should be mounted on next tab switch

## Testing Checklist

### For Admin (Issuing Warning):
1. Open Reports tab
2. Click "Action" on a report
3. Select "Issue Warning"
4. Confirm action
5. Check console for:
   - ✅ `[AdminReportsTab] ✅ Notification sent to user`
   - ✅ `[AdminReportsTab] Notification ID: {id}`
   - Note the **reported user ID**

### For Reported User (Receiving Warning):
1. **Make sure you're logged in as the reported user**
2. Open the app
3. Switch to Discovery tab
4. Check console for:
   - ✅ `[AdminActionChecker] 🔍 Checking admin actions for: {userId}`
   - ✅ `[ActionNotificationService] Found {count} documents`
   - ✅ `[AdminActionChecker] 🔔 Showing notification dialog...`
5. Warning popup should appear

## Expected Console Output (Success)

```
[AdminActionChecker] ═══════════════════════════════════════
[AdminActionChecker] 🔍 Checking admin actions for: abc123xyz
[AdminActionChecker] ═══════════════════════════════════════
[AdminActionChecker] Step 1: Checking ban status...
[AdminActionChecker] Ban status result: {isBanned: false}
[AdminActionChecker] Step 2: Fetching pending notifications...
[ActionNotificationService] ═══════════════════════════════════════
[ActionNotificationService] 📡 Fetching pending action notifications
[ActionNotificationService] User ID: abc123xyz
[ActionNotificationService] Path: users/abc123xyz/notifications
[ActionNotificationService] Query: type=admin_action, read=false
[ActionNotificationService] 📊 Query completed
[ActionNotificationService] Found 1 documents
[ActionNotificationService] 📄 Notification ID: notif_123
[ActionNotificationService]    Title: ⚠️ Warning Issued
[ActionNotificationService]    Type: admin_action
[ActionNotificationService]    Read: false
[ActionNotificationService]    Action: warning
[ActionNotificationService] ✅ Returning 1 notifications
[ActionNotificationService] ═══════════════════════════════════════
[AdminActionChecker] 📬 Notifications count: 1
[AdminActionChecker] ✅ Found 1 pending notifications
[AdminActionChecker] First notification: {id: notif_123, title: ⚠️ Warning Issued, ...}
[AdminActionChecker] 🔔 Showing notification dialog...
```

## Quick Fix Commands

### If you need to test again:
1. Delete the notification from Firestore
2. Issue a new warning from admin panel
3. Switch tabs on reported user's device

### If popup still doesn't show:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`
4. Check console logs carefully

## Most Common Cause

**You're testing with the wrong user!**
- Admin issues warning to User A
- You're logged in as User B
- User B won't see the warning (it's for User A)
- **Solution**: Log in as the exact user who was reported

## Next Steps

1. Run the app with the updated code
2. Issue a warning from admin panel
3. **Copy the console logs** showing:
   - Admin issuing the warning
   - User checking for notifications
4. Share the logs so I can see exactly what's happening

The enhanced logging will show us exactly where the issue is!
