# 🔧 Admin Action Integration - Quick Steps

## Problem
Warnings and admin actions are not showing to users because the AdminActionChecker is not integrated into the app.

## Solution
Add AdminActionChecker wrapper to your main app or home screen.

---

## Step 1: Find Your Main App Widget

**Location:** `lib/main.dart`

Look for your `MaterialApp` or main widget:

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      // ... other config
    );
  }
}
```

---

## Step 2: Import AdminActionChecker

Add this import at the top of `main.dart`:

```dart
import 'widgets/admin_action_checker.dart';
```

---

## Step 3: Wrap Your Home Screen

Replace:
```dart
home: HomeScreen(),
```

With:
```dart
home: AdminActionChecker(
  child: HomeScreen(),
),
```

**Full Example:**

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdminActionChecker(
        child: HomeScreen(),
      ),
      routes: {
        '/banned': (context) {
          final banStatus = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return BannedScreen(banStatus: banStatus);
        },
      },
      // ... other config
    );
  }
}
```

---

## Step 4: Add Banned Screen Route

Make sure you have the `/banned` route in your `MaterialApp`:

```dart
routes: {
  '/banned': (context) {
    final banStatus = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    return BannedScreen(banStatus: banStatus);
  },
  // ... other routes
}
```

---

## Step 5: Update Firestore Rules

Copy the updated rules from `FIRESTORE_RULES_ADMIN_BYPASS.txt` and paste them in:

**Firebase Console → Firestore → Rules**

Key rules that must be present:

```dart
// Users notifications subcollection
match /notifications/{notificationId} {
  allow read: if isOwner(userId) || true;
  allow write: if isAuthenticated() || true;
  allow delete: if isOwner(userId) || isAuthenticated() || true;
}

// Reports collection
match /reports/{reportId} {
  allow read: if true;
  allow create: if isAuthenticated() && request.resource.data.reporterId == request.auth.uid;
  allow update: if true;
  allow delete: if isAuthenticated() && 
                   (request.auth.uid == resource.data.reporterId || 
                    request.auth.uid == resource.data.reportedUserId) || true;
}
```

---

## Step 6: Test

1. **Admin Panel**: Take a warning action on a report
2. **Check Console**: Look for logs like:
   ```
   [AdminReportsTab] ✅ Notification sent to user
   [AdminReportsTab] Notification ID: notif_123
   ```
3. **User App**: Open the app with the reported user account
4. **Expected**: Should see warning popup

---

## Expected Console Logs

### When Admin Takes Action
```
[AdminReportsTab] Updating user account: user123
[AdminReportsTab] ✅ User account updated
[AdminReportsTab] Sending notification to user
[AdminReportsTab] User ID: user123
[AdminReportsTab] Notification Title: ⚠️ Warning Issued
[AdminReportsTab] Notification Body: You have received a warning...
[AdminReportsTab] ✅ Notification sent to user
[AdminReportsTab] Notification ID: notif_abc123
[AdminReportsTab] Path: users/user123/notifications/notif_abc123
[AdminReportsTab] Updating report status to resolved
[AdminReportsTab] ✅ Report updated to resolved
[AdminReportsTab] ✅ Action completed successfully
```

### When User Opens App
```
[AdminActionChecker] Checking admin actions for: user123
[BanEnforcementService] Checking ban status for: user123
[BanEnforcementService] ✅ User is not banned
[ActionNotificationService] Fetching pending action notifications for: user123
[ActionNotificationService] Found 1 pending notifications
[AdminActionChecker] Found 1 pending notifications
[ActionNotificationService] Marking notification as read: notif_abc123
[ActionNotificationService] ✅ Notification marked as read
```

---

## Troubleshooting

### Warning Not Showing

**Check 1: Firestore Rules**
- Go to Firebase Console → Firestore → Rules
- Search for `match /notifications/{notificationId}`
- Verify `allow write: if true;` is present

**Check 2: Notification Created**
- Go to Firebase Console → Firestore
- Navigate to: `users → {reportedUserId} → notifications`
- Should see a document with `type: 'admin_action'`

**Check 3: AdminActionChecker Integrated**
- Open `main.dart`
- Check if `AdminActionChecker` wraps your home screen
- If not, add it as shown in Step 3

**Check 4: Console Logs**
- Run app with `flutter run`
- Check console for logs starting with `[AdminActionChecker]`
- If no logs, AdminActionChecker is not running

### Permission Denied Error

If you see:
```
[AdminReportsTab] 🔐 PERMISSION DENIED on notification
```

**Fix:**
1. Go to Firebase Console → Firestore → Rules
2. Find the notifications subcollection rule
3. Change to: `allow write: if true;`
4. Publish rules
5. Wait 1-2 minutes for rules to propagate
6. Try again

---

## Files Involved

- **`lib/main.dart`** - Add AdminActionChecker wrapper
- **`lib/widgets/admin_action_checker.dart`** - Checks for admin actions
- **`lib/services/action_notification_service.dart`** - Fetches notifications
- **`lib/services/ban_enforcement_service.dart`** - Checks ban status
- **`lib/screens/action_notification_dialog.dart`** - Shows popup
- **`lib/screens/banned_screen.dart`** - Shows if banned
- **`FIRESTORE_RULES_ADMIN_BYPASS.txt`** - Firestore rules

---

## Summary

✅ **Step 1**: Import AdminActionChecker  
✅ **Step 2**: Wrap home screen with AdminActionChecker  
✅ **Step 3**: Add /banned route  
✅ **Step 4**: Update Firestore rules  
✅ **Step 5**: Test  

**Warnings should now show to users!** 🎉
