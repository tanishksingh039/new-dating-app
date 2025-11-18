# Admin Panel - Real-Time Data Documentation

## Overview
The CampusBound admin panel now features **100% real-time data** from Firebase Firestore with no mock data. All statistics and information update automatically as changes occur in the database.

## Features

### 1. Admin Dashboard (`admin_dashboard_screen.dart`)
**Real-time Statistics:**
- **Total Users** - Live count of all registered users
- **Active Users** - Users active in the last 7 days (auto-updates)
- **Verified Users** - Count of verified users
- **Premium Users** - Count of premium subscribers
- **Total Reports** - All reports filed
- **Pending Reports** - Reports awaiting review (needs attention)
- **Total Matches** - Platform-wide match count
- **Today's Signups** - New users registered today

**Real-time Activity Feed:**
- Shows the 5 most recent reports
- Updates automatically when new reports are filed
- Displays report status with color-coded badges

**Data Source:** 
- Uses Firebase Firestore `snapshots()` for real-time streaming
- Automatically recalculates statistics on every database change
- Green "Real-time data" indicator shows live connection status

### 2. User Management (`admin_users_screen.dart`)
**Features:**
- **Real-time user list** - Updates as users join/leave
- **Search functionality** - Search by name or email
- **Filter tabs:**
  - All Users
  - Active (last 7 days)
  - Verified users
  - Premium users
- **User details:**
  - Profile photos
  - Active status indicator (green dot)
  - Verification badge
  - Premium badge
  - Age and college information

**Data Source:**
- StreamBuilder with `users` collection
- Ordered by creation date (newest first)
- Real-time filtering and search

### 3. User Details (`user_details_screen.dart`)
**Real-time Information:**
- Complete user profile
- **Activity statistics:**
  - Total matches (live count)
  - Likes received (live count)
  - Reports filed against user (live count)
- Last active timestamp
- Account creation date

**Admin Actions:**
- Toggle verification status
- Grant/remove premium status
- Block user
- Delete user account (with cascading deletion)

**Data Source:**
- Real-time queries for matches, likes, and reports
- Updates immediately when user data changes

### 4. Report Management (`admin_reports_screen.dart`)
**Real-time Features:**
- **Live report feed** - New reports appear instantly
- **Tabs with live counts:**
  - All reports
  - Pending reports
  - Under review
  - Resolved/dismissed
- **Report details:**
  - Reporter and reported user info
  - Timestamps
  - Status badges
  - Quick action buttons

**Data Source:**
- StreamBuilder on `reports` collection
- Ordered by creation date (newest first)
- Auto-updates when report status changes

### 5. Report Details (`report_details_screen.dart`)
**Features:**
- Full report information
- Reporter and reported user profiles
- Admin notes (editable)
- Status management
- Block user option

## Access Control

**Current Setup:**
```dart
if (currentUserId == 'admin_user') // Show admin options
```

**Production Recommendation:**
Add a proper role-based access control:
```dart
// In user_model.dart, add:
final String role; // 'user', 'admin', 'moderator'

// In settings_screen.dart, check:
if (currentUser.role == 'admin' || currentUser.role == 'moderator')
```

## Database Collections Used

### 1. `users` Collection
```dart
{
  'uid': String,
  'name': String,
  'email': String,
  'isVerified': bool,
  'isPremium': bool,
  'lastActive': Timestamp,
  'createdAt': Timestamp,
  // ... other fields
}
```

### 2. `reports` Collection
```dart
{
  'id': String,
  'reporterId': String,
  'reportedUserId': String,
  'reason': String,
  'description': String,
  'status': String, // 'pending', 'underReview', 'resolved', 'dismissed'
  'createdAt': Timestamp,
  'resolvedAt': Timestamp?,
  'adminNotes': String?,
}
```

### 3. `matches` Collection
```dart
{
  'users': [String, String], // Array of user IDs
  'createdAt': Timestamp,
}
```

### 4. `swipes` Collection
```dart
{
  'userId': String,
  'targetUserId': String,
  'isLike': bool,
  'createdAt': Timestamp,
}
```

## Real-time Updates Mechanism

### StreamBuilder Pattern
All admin screens use Firebase's `snapshots()` method:

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('reports')
      .orderBy('createdAt', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    // Automatically rebuilds when data changes
  },
)
```

### Benefits:
- ✅ No manual refresh needed
- ✅ Instant updates across all admin sessions
- ✅ Accurate real-time statistics
- ✅ No stale data
- ✅ Automatic error handling

## Navigation

**From Settings Screen:**
1. **Admin Dashboard** - Main entry point with overview
2. **Manage Reports** - Direct access to report management

**From Dashboard:**
- Click on any stat card to navigate to detailed view
- Recent activity items link to report management
- User management accessible from user stats

## Performance Considerations

### Optimizations:
1. **Indexed queries** - Ensure Firestore indexes are created for:
   - `reports` ordered by `createdAt`
   - `users` ordered by `createdAt`
   - `matches` with `users` array

2. **Pagination** - Consider adding pagination for large datasets:
   ```dart
   .limit(100) // Limit initial load
   ```

3. **Composite indexes** - For complex queries, create composite indexes in Firebase Console

### Current Limits:
- Reports: No limit (loads all)
- Users: No limit (loads all)
- Matches: No limit (loads all)

**Recommendation:** Add pagination when counts exceed 1000 items.

## Error Handling

All screens include:
- Loading states (CircularProgressIndicator)
- Error states with user-friendly messages
- Empty states with helpful icons
- Try-catch blocks for all Firebase operations
- SnackBar notifications for user feedback

## Testing the Admin Panel

### 1. Access Admin Panel:
```dart
// Temporarily set your user ID to 'admin_user' in Firebase
// Or update the condition in settings_screen.dart
```

### 2. Test Real-time Updates:
- Open admin dashboard
- In another session/device, create a report
- Watch it appear instantly in the admin panel
- Update report status and see live changes

### 3. Test User Management:
- Search for users
- Filter by status
- View user details
- Test admin actions (verify, premium, block)

## Future Enhancements

### Recommended Additions:
1. **Analytics Charts** - Add graphs for user growth, match trends
2. **Bulk Actions** - Select multiple reports for batch processing
3. **Export Data** - Download reports/user data as CSV
4. **Push Notifications** - Alert admins of new pending reports
5. **Audit Log** - Track all admin actions
6. **Advanced Filters** - Date ranges, custom queries
7. **Role Management** - Assign moderator roles
8. **Automated Actions** - Auto-flag suspicious accounts

## Security Notes

⚠️ **Important:**
- Never expose admin credentials in code
- Implement proper Firebase Security Rules
- Use Firebase Authentication for admin verification
- Add rate limiting for admin actions
- Log all admin activities for audit trail

### Recommended Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only admins can read/write reports
    match /reports/{reportId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Support

For issues or questions about the admin panel:
1. Check Firebase Console for data
2. Review error logs in debug console
3. Verify Firestore indexes are created
4. Ensure proper permissions in Security Rules
