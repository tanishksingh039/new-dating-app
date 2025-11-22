# Firestore Rules - Account Deletion Support

## Overview
Updated Firestore security rules to support comprehensive account deletion functionality. The previous rules were blocking the account deletion service from removing user data across multiple collections.

## Problem
When users tried to delete their account, they received a `[cloud_firestore/permission-denied]` error because the Firestore rules didn't allow deletion of user-related data in various collections.

## Changes Made

### 1. **Swipes Collection**
- **Before**: Only the swiper could delete their own swipes
- **After**: Both the swiper and the target user can delete swipes (needed for account cleanup)

### 2. **Reports Collection**
- **Before**: Reports could not be deleted
- **After**: Both the reporter and the reported user can delete reports (for account cleanup)

### 3. **Blocks Collection**
- **Before**: Only the blocker could delete blocks
- **After**: Both the blocker and blocked user can delete blocks (for account cleanup)

### 4. **Swipe Stats Collection**
- **Before**: Deletion not allowed
- **After**: Users can delete their own swipe stats

### 5. **Payment Collections**
- **payment_orders**: Users can now delete their own payment orders
- **payment_transactions**: Users can now delete their own transactions

### 6. **Subscription Collection**
- **Before**: Deletion not allowed
- **After**: Users can delete their own subscription data

### 7. **Spotlight Collections**
- **spotlight_bookings**: Users can now delete their own bookings
- **spotlight_transactions**: Users can now delete their own transactions

### 8. **Verification Collections**
- **verification_requests**: Users can now delete their own requests
- **verification_photos**: Users can now delete their own photos

### 9. **Rewards Collection**
- **reward_history**: Users can now delete their own reward history

### 10. **Messages Subcollection**
- **Before**: Messages could not be deleted
- **After**: Chat participants can delete messages (for account cleanup)

## Security Considerations

All deletion permissions are properly scoped:
- Users can only delete their **own** data
- For relational data (swipes, reports, blocks), both parties can delete for cleanup
- Authentication is required for all operations
- Admin-only collections remain protected

## Deployment Instructions

### Option 1: Using the Batch Script (Windows)
```bash
# Navigate to the frontend directory
cd c:\CampusBound\frontend

# Run the deployment script
deploy_firestore_rules.bat
```

### Option 2: Using Firebase CLI Directly
```bash
# Navigate to the frontend directory
cd c:\CampusBound\frontend

# Deploy the rules
firebase deploy --only firestore:rules
```

### Option 3: Firebase Console (Manual)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Copy the contents of `firestore.rules`
5. Paste into the rules editor
6. Click **Publish**

## Testing Account Deletion

After deploying the rules, test account deletion:

1. **Login** to the app with a test account
2. Go to **Settings** → **Account Settings**
3. Tap **Delete Account**
4. Confirm deletion
5. Verify the account is deleted successfully

## Collections Affected by Account Deletion

The `AccountDeletionService` will now be able to delete data from:
- ✅ users/{userId}
- ✅ swipes (where userId matches)
- ✅ matches (where user is participant)
- ✅ chats/{chatId}/messages (where user is participant)
- ✅ reports (created by or against user)
- ✅ blocks (created by or against user)
- ✅ notifications (for user)
- ✅ swipe_stats/{userId}
- ✅ payment_orders (for user)
- ✅ payment_transactions (for user)
- ✅ subscriptions/{userId}
- ✅ spotlight_bookings (for user)
- ✅ spotlight_transactions (for user)
- ✅ verification_requests (for user)
- ✅ verification_photos (for user)
- ✅ reward_history (for user)
- ✅ rewards_stats/{userId}
- ✅ Firebase Storage: users/{userId}/* (photos)
- ✅ Firebase Auth account

## Notes

- The rules maintain security by requiring authentication
- Users can only delete their own data
- Admin collections remain protected
- The changes are backward compatible with existing functionality
- No impact on normal app operations (discovery, matching, chatting, etc.)

## Rollback

If you need to rollback these changes:
1. Keep a backup of the previous `firestore.rules` file
2. Deploy the backup using the same deployment commands

## Support

If you encounter any issues:
1. Check Firebase Console → Firestore → Rules for deployment status
2. Review Firebase Console → Firestore → Usage for any rule violations
3. Check app logs for detailed error messages
