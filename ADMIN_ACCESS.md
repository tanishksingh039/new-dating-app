# Hidden Admin Access - Quick Guide

## 🔐 How to Access Admin Panel

### Method 1: Secret Logo Tap (Camouflaged Access)
1. Open the app and go to the **Login Screen**
2. **Tap the Shooluv logo 5 times** quickly (within 2 seconds)
3. A purple **Admin Access** dialog will appear
4. Select one of the 4 admin accounts:
   - **ADMIN USER**
   - **TANISHK ADMIN**
   - **SHOOLUV ADMIN**
   - **DEV ADMIN**
5. You'll be taken directly to the **Admin Dashboard**

### Method 2: Settings Screen (For Logged-in Admins)
1. Login with one of the 4 admin user IDs
2. Go to **Profile** → **Settings**
3. Scroll down to see the **Admin** section
4. Tap **Admin Dashboard** or **Manage Reports**

## 👥 Admin User IDs

The following 4 user IDs have admin access:

```dart
1. admin_user
2. tanishk_admin
3. shooluv_admin
4. dev_admin
```

**To use these:**
- In Firebase Console, set your user's `uid` field to one of these IDs
- Or use the secret logo tap to access without logging in

## 🎯 Admin Panel Features

Once you access the admin panel, you get:

### 1. **Admin Dashboard**
- Real-time user statistics
- Active users count
- Verified & Premium users
- Total reports & pending reports
- Total matches
- Today's signups
- Recent activity feed

### 2. **User Management**
- View all users with real-time updates
- Search by name or phone
- Filter: All, Active, Verified, Premium
- View detailed user profiles
- Admin actions:
  - Verify/unverify users
  - Grant/remove premium
  - Block users
  - Delete accounts

### 3. **Report Management**
- Real-time report feed
- Filter: All, Pending, Reviewing, Resolved
- View report details
- Update report status
- Block reported users
- Add admin notes

## 🎨 Visual Indicators

### Logo Tap Counter
- Tap the logo 5 times within 2 seconds
- Counter resets after 2 seconds of inactivity
- No visual feedback until dialog appears (stealth mode)

### Admin Access Dialog
- Purple gradient background
- Admin panel settings icon
- 4 purple buttons for each admin ID
- Clean, modern UI

## 🔧 Technical Details

### Login Screen Changes
**File:** `lib/screens/auth/login_screen.dart`

```dart
// Admin access variables
int _logoTapCount = 0;
DateTime? _lastTapTime;
final List<String> _adminUserIds = [
  'admin_user',
  'tanishk_admin',
  'shooluv_admin',
  'dev_admin',
];

// Logo tap handler
void _onLogoTap() {
  final now = DateTime.now();
  
  // Reset counter if more than 2 seconds since last tap
  if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
    _logoTapCount = 0;
  }
  
  _lastTapTime = now;
  _logoTapCount++;
  
  if (_logoTapCount >= 5) {
    _logoTapCount = 0;
    _showAdminAccessDialog();
  }
}
```

### Settings Screen Changes
**File:** `lib/screens/settings/settings_screen.dart`

```dart
// Admin user IDs
final List<String> _adminUserIds = [
  'admin_user',
  'tanishk_admin',
  'shooluv_admin',
  'dev_admin',
];

bool get _isAdmin => _adminUserIds.contains(currentUserId);

// Admin section only shows if user ID matches
if (_isAdmin)
  _buildSection('Admin', [...])
```

## 🚀 Usage Examples

### Example 1: Quick Admin Access (No Login)
1. Open app
2. Tap logo 5 times
3. Select "ADMIN USER"
4. View dashboard immediately

### Example 2: Admin Login
1. In Firebase Console:
   - Go to Firestore
   - Find your user document
   - Change `uid` to `tanishk_admin`
2. Login normally
3. Go to Settings
4. Access admin panel

### Example 3: Testing Different Admin Accounts
- Use different admin IDs to test permissions
- Each ID can be assigned different roles in future
- Currently all 4 IDs have full admin access

## 🔒 Security Notes

### Current Implementation:
- ✅ Hidden access (no visible admin button)
- ✅ Multiple admin IDs supported
- ✅ Works without authentication
- ⚠️ No password protection on logo tap

### Production Recommendations:
1. Add password/PIN for logo tap access
2. Implement role-based permissions per admin ID
3. Add audit logging for admin actions
4. Require authentication before admin access
5. Add session timeout for admin panel
6. Implement 2FA for admin accounts

## 📱 Demo Flow

```
Login Screen
    ↓ (Tap logo 5x)
Admin Access Dialog
    ↓ (Select admin ID)
Admin Dashboard
    ├── View Statistics
    ├── User Management → User Details
    └── Report Management → Report Details
```

## 🎯 Quick Tips

1. **Fast Access**: Tap logo quickly - you have 2 seconds
2. **No Visual Feedback**: The tap counter is invisible (stealth)
3. **Direct Navigation**: Bypasses normal login flow
4. **Real-time Data**: All data updates automatically
5. **Multiple Sessions**: Can have multiple admin sessions open

## 🐛 Troubleshooting

### Logo tap not working?
- Tap faster (within 2 seconds)
- Make sure you're tapping the logo itself
- Try tapping exactly 5 times

### Admin section not showing in Settings?
- Check your user ID in Firebase
- Must be one of the 4 admin IDs
- Logout and login again

### Can't see real-time updates?
- Check internet connection
- Verify Firebase rules allow read access
- Check console for errors

## 📝 Notes

- The logo tap feature is **completely hidden** - no hints in UI
- Admin IDs are **hardcoded** for security
- All admin features use **real-time Firebase data**
- No mock data anywhere in admin panel
- Admin access works **without location check**
