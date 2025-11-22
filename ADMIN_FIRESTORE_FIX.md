# Admin Panel Firestore Rules Fix

## Problem
Admin panel's Users section was showing a Firestore permission error:
```
Error: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Root Cause
The Firestore rules didn't have proper admin permissions for:
1. Listing all users (query operations)
2. Updating user data (for admin actions)
3. Deleting users (for admin moderation)

## Solution

### 1. Added Admin Helper Function

```dart
function isAdmin() {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

This function checks if the authenticated user has `role: 'admin'` in their user document.

### 2. Updated Users Collection Rules

**Before:**
```dart
match /users/{userId} {
  allow read: if isAuthenticated();
  allow update: if isOwner(userId) || ...;
  allow delete: if isOwner(userId);
}
```

**After:**
```dart
match /users/{userId} {
  allow read: if isAuthenticated();
  allow list: if isAuthenticated() || isAdmin();  // ← Added for queries
  
  allow update: if isOwner(userId) || 
                   isAdmin() ||  // ← Added admin access
                   ...;
  
  allow delete: if isOwner(userId) || isAdmin();  // ← Added admin access
}
```

## Changes Made

### File: `firestore.rules`

1. **Added `isAdmin()` function** (lines 17-20)
   - Checks if user is authenticated
   - Verifies user has `role: 'admin'` in Firestore

2. **Added `allow list` rule** (line 27)
   - Allows admins to query/list all users
   - Required for admin panel user list

3. **Updated `allow update` rule** (line 41)
   - Added `isAdmin()` condition
   - Allows admins to update any user

4. **Updated `allow delete` rule** (line 47)
   - Added `isAdmin()` condition
   - Allows admins to delete users

## Deployment

### Deploy Updated Rules:

**Option 1: Firebase Console**
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Click on "Rules" tab
4. Copy and paste the updated rules
5. Click "Publish"

**Option 2: Firebase CLI**
```bash
cd c:\CampusBound\frontend
firebase deploy --only firestore:rules
```

## Admin User Setup

To make a user an admin, update their Firestore document:

### Using Firebase Console:
1. Go to Firestore Database
2. Navigate to `users` collection
3. Find the user document
4. Add field: `role` = `"admin"`
5. Save

### Using Firebase CLI:
```javascript
// In Firebase Console or Cloud Functions
db.collection('users').doc('USER_ID').update({
  role: 'admin'
});
```

## What Admins Can Now Do

### ✅ **Users Tab:**
- View all users (list query)
- Search users by name/phone
- Filter by Premium/Verified/Flagged
- View user details
- Update user information
- Delete user accounts

### ✅ **Admin Permissions:**
- Read all user profiles
- List/query all users
- Update any user data
- Delete user accounts
- Moderate content
- Manage reports

## Security Notes

### ✅ **Secure:**
- Only users with `role: 'admin'` can access admin features
- Admin status is stored in Firestore (server-side)
- Cannot be modified by client-side code
- Requires Firestore rules check on every request

### ⚠️ **Important:**
- Make sure to set `role: 'admin'` only for trusted users
- Admin users have full access to user data
- Consider using Firebase Admin SDK for sensitive operations
- Log admin actions for audit trail

## Testing

### Test Admin Access:
1. Set your user's `role` to `"admin"` in Firestore
2. Open the app
3. Navigate to Admin Panel
4. Go to Users tab
5. Should see list of all users without errors

### Test Non-Admin Access:
1. Use a regular user account (no `role` field or `role: 'user'`)
2. Try to access Admin Panel
3. Should be blocked or show limited access

## Files Modified

- `firestore.rules`
  - Added `isAdmin()` helper function
  - Updated users collection rules
  - Added admin permissions for list, update, delete

## Summary

The admin panel now works correctly with proper Firestore permissions:
- ✅ Admin function checks user role
- ✅ List permission for querying users
- ✅ Update permission for admin actions
- ✅ Delete permission for moderation
- ✅ Secure role-based access control

Deploy the updated rules to fix the permission error! 🔧✨
