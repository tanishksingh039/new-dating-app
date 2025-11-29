# Warning Popup Test Guide 🔍

## Quick Test Steps

### Step 1: Issue Warning from Admin Panel

1. **Open Admin Panel**
   - Navigate to Reports tab
   - Find a report to action

2. **Issue Warning**
   - Click on a report
   - Select "Issue Warning" (orange button)
   - Confirm the action

3. **Check Console Logs**
   Look for these logs:
   ```
   [AdminReportsTab] Updating user account: {userId}
   [AdminReportsTab] ✅ User account updated
   [AdminReportsTab] Sending notification to user
   [AdminReportsTab] ✅ Notification sent to user
   [AdminReportsTab] Notification ID: {notificationId}
   [AdminReportsTab] Path: users/{userId}/notifications/{notificationId}
   ```

### Step 2: Verify in Firestore

1. **Open Firebase Console**
   - Go to Firestore Database
   - Navigate to: `users/{reportedUserId}/notifications`

2. **Check Notification Document**
   Should contain:
   ```javascript
   {
     title: "⚠️ Warning Issued",
     body: "You have received a warning for...",
     type: "admin_action",
     data: {
       screen: "settings",
       action: "warning",  // ← CRITICAL: Must be "warning"
       reason: "Inappropriate behavior",
       reportId: "report123"
     },
     read: false,  // ← CRITICAL: Must be false
     createdAt: Timestamp,
     priority: "high"
   }
   ```

### Step 3: Test Warning Popup

#### Method 1: Close and Reopen App
1. Close the app completely
2. Reopen the app
3. Warning screen should appear immediately

#### Method 2: Switch Tabs
1. Stay in the app
2. Switch to a different tab (e.g., from Discovery to Likes)
3. Warning screen should appear

#### Method 3: Hot Restart
1. In VS Code/Android Studio
2. Press hot restart button
3. Warning screen should appear

### Expected Behavior

**Warning Screen Should Show:**
```
┌─────────────────────────────────────┐
│         ⚠️ (Orange Circle)          │
│       ⚠️ Warning Issued             │
│      [First Warning Badge]          │
│                                     │
│  Reason: Inappropriate behavior     │
│                                     │
│  Important Notice:                  │
│  Repeated violations may result     │
│  in suspension                      │
│                                     │
│  Community Guidelines:              │
│  ✓ Be respectful                   │
│  ✓ No harassment                   │
│  ✓ No spam                         │
│                                     │
│      [I Understand Button]          │
└─────────────────────────────────────┘
```

## Console Logs to Watch

### When Warning is Checked:

```
[AdminActionChecker] ═══════════════════════════════════════
[AdminActionChecker] 🔍 Checking admin actions for: user123
[AdminActionChecker] Step 1: Checking ban status...
[AdminActionChecker] Ban status result: {isBanned: false}
[AdminActionChecker] Step 2: Fetching pending notifications...
[ActionNotificationService] 📡 Fetching pending action notifications
[ActionNotificationService] User ID: user123
[ActionNotificationService] Path: users/user123/notifications
[ActionNotificationService] Query: type=admin_action, read=false
[ActionNotificationService] 📊 Query completed
[ActionNotificationService] Found 1 documents
[ActionNotificationService] 📄 Notification ID: notif123
[ActionNotificationService]    Title: ⚠️ Warning Issued
[ActionNotificationService]    Type: admin_action
[ActionNotificationService]    Read: false
[ActionNotificationService]    Action: warning
[AdminActionChecker] 📬 Notifications count: 1
[AdminActionChecker] Action type: warning
[AdminActionChecker] 🔔 Showing warning screen...
```

### When No Warning Found:

```
[ActionNotificationService] Found 0 documents
[ActionNotificationService] ℹ️ No pending notifications found
[AdminActionChecker] 📬 Notifications count: 0
```

## Troubleshooting

### Issue 1: Warning Not Appearing

**Check 1: Notification Exists?**
```
1. Open Firebase Console
2. Go to: users/{userId}/notifications
3. Look for document with:
   - type: "admin_action"
   - data.action: "warning"
   - read: false
```

**Check 2: Console Logs**
```
Look for:
[ActionNotificationService] Found X documents

If X = 0:
  → Notification not created or already read
  
If X > 0 but no warning shows:
  → Check action field value
  → Should be "warning" not "AdminAction.warning"
```

**Check 3: Firestore Rules**
```
Verify rules allow reading notifications:
match /users/{userId}/notifications/{notificationId} {
  allow read: if isOwner(userId) || true;
  allow write: if isAuthenticated() || true;
}
```

### Issue 2: Permission Denied Error

**Symptoms:**
```
[ActionNotificationService] ❌ Error fetching notifications
[ActionNotificationService] 🔐 PERMISSION DENIED
```

**Solution:**
1. Deploy Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. Or copy from `FIRESTORE_RULES_ADMIN_BYPASS.txt`

3. Wait 1-2 minutes for rules to propagate

### Issue 3: Warning Shows Multiple Times

**Cause:** Notification not being marked as read

**Solution:**
1. Check console for:
   ```
   [ActionNotificationService] Marking notification as read: notif123
   [ActionNotificationService] ✅ Notification marked as read
   ```

2. Verify in Firestore that `read: true` after acknowledging

3. If still showing, manually set `read: true` in Firestore

### Issue 4: Action Field Wrong Value

**Problem:** `data.action` might be "AdminAction.warning" instead of "warning"

**Check:**
```javascript
// In Firestore, should be:
data: {
  action: "warning"  // ✅ Correct
}

// NOT:
data: {
  action: "AdminAction.warning"  // ❌ Wrong
}
```

**Fix:** Update admin_reports_tab.dart line 290:
```dart
'action': action.name,  // This should output "warning"
```

## Manual Test in Firestore

If warning still not showing, create a test notification manually:

1. **Open Firebase Console → Firestore**

2. **Navigate to:** `users/{yourUserId}/notifications`

3. **Add Document:**
   ```javascript
   {
     title: "⚠️ Warning Issued",
     body: "Test warning message",
     type: "admin_action",
     data: {
       screen: "settings",
       action: "warning",
       reason: "Test",
       reportId: "test123"
     },
     read: false,
     createdAt: {current timestamp},
     priority: "high"
   }
   ```

4. **Close and reopen app** → Warning should appear

## Debug Mode

To enable detailed logging, add these debug prints:

### In `home_screen.dart`:
```dart
Future<void> _checkForWarnings() async {
  debugPrint('[HomeScreen] 🔍 Checking for warnings...');
  
  final userId = FirebaseAuth.instance.currentUser?.uid;
  debugPrint('[HomeScreen] User ID: $userId');
  
  if (userId == null) {
    debugPrint('[HomeScreen] ❌ No user ID');
    return;
  }
  
  final notificationService = ActionNotificationService();
  final notifications = await notificationService.getPendingActionNotifications(userId);
  
  debugPrint('[HomeScreen] 📬 Found ${notifications.length} notifications');
  
  if (notifications.isNotEmpty) {
    debugPrint('[HomeScreen] First notification: ${notifications[0]}');
    // ... rest of code
  }
}
```

## Success Indicators

✅ **Warning System Working When:**
1. Admin issues warning → Console shows "✅ Notification sent"
2. Notification appears in Firestore with correct fields
3. User opens app → Warning screen appears
4. User switches tabs → Warning screen appears
5. User clicks "I Understand" → Returns to app
6. Notification marked as `read: true` in Firestore
7. Warning doesn't appear again

## Quick Verification Checklist

- [ ] Admin can issue warning from Reports screen
- [ ] Console shows "✅ Notification sent to user"
- [ ] Notification exists in Firestore
- [ ] Notification has `type: "admin_action"`
- [ ] Notification has `data.action: "warning"`
- [ ] Notification has `read: false`
- [ ] User reopens app → Warning appears
- [ ] User switches tabs → Warning appears
- [ ] Warning screen shows correct reason
- [ ] User can click "I Understand"
- [ ] Notification marked as read after acknowledgment
- [ ] Warning doesn't appear again

## Common Mistakes

❌ **Wrong action value:**
```javascript
data: { action: "AdminAction.warning" }  // Wrong
data: { action: "warning" }              // Correct
```

❌ **Wrong type:**
```javascript
type: "notification"     // Wrong
type: "admin_action"     // Correct
```

❌ **Already read:**
```javascript
read: true   // Won't show
read: false  // Will show
```

❌ **Wrong user ID:**
```javascript
// Notification in: users/user123/notifications
// But checking for: users/user456/notifications
// Won't find it!
```

## Summary

The warning popup system is **fully implemented** and should work when:

1. ✅ Admin issues warning from Reports screen
2. ✅ Notification created with correct structure
3. ✅ User opens app or switches tabs
4. ✅ `AdminActionChecker` detects pending warning
5. ✅ Warning screen appears (full-screen)
6. ✅ User acknowledges warning
7. ✅ Notification marked as read

If warning is not appearing, follow the troubleshooting steps above and check console logs for errors.

---

**Test Now:**
1. Issue warning from admin panel
2. Check console logs
3. Verify in Firestore
4. Close and reopen app
5. Warning should appear!

**Last Updated**: Nov 29, 2025
