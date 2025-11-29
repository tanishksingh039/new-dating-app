# Rewards Not Showing - Debug Guide 🔍

## Issue
Rewards are not showing in the user side on the Rewards tab.

## Changes Made

### 1. Fixed Navigation
**Updated `lib/screens/home/home_screen.dart`:**
- Changed from `RewardsLeaderboardScreen` (leaderboard) 
- To `UserRewardsScreen` (actual rewards/coupon codes)

**Before:**
```dart
import '../rewards/rewards_leaderboard_screen.dart';
// ...
const AdminActionChecker(child: RewardsLeaderboardScreen()),
```

**After:**
```dart
import '../rewards/user_rewards_screen.dart';
// ...
const AdminActionChecker(child: UserRewardsScreen()),
```

### 2. Added Debug Logging
**Added comprehensive logging to:**
- `UserRewardsScreen` - Shows screen initialization and data loading
- `RewardService` - Shows Firestore queries and results

## Debug Console Logs

When you run the app and navigate to the Rewards tab, you should see these logs:

### Success Logs (Rewards Found):
```
[UserRewardsScreen] ═══════════════════════════════════════
[UserRewardsScreen] 🎁 Initializing User Rewards Screen
[UserRewardsScreen] User ID: abc123xyz
[UserRewardsScreen] ═══════════════════════════════════════
[RewardService] ═══════════════════════════════════════
[RewardService] 📡 Setting up rewards stream
[RewardService] User ID: abc123xyz
[RewardService] Collection: rewards
[RewardService] Query: userId == abc123xyz
[RewardService] ═══════════════════════════════════════
[UserRewardsScreen] StreamBuilder state: ConnectionState.active
[UserRewardsScreen] Has data: true
[UserRewardsScreen] Has error: false
[RewardService] 📊 Stream update received
[RewardService] Documents count: 2
[RewardService] 📄 Reward: reward_123
[RewardService]    Title: Top 10 Monthly Reward
[RewardService]    Status: pending
[RewardService] 📄 Reward: reward_456
[RewardService]    Title: Special Bonus
[RewardService]    Status: claimed
[UserRewardsScreen] 📦 Total rewards: 2
[UserRewardsScreen] ✅ Available: 1
```

### No Rewards Logs:
```
[UserRewardsScreen] ═══════════════════════════════════════
[UserRewardsScreen] 🎁 Initializing User Rewards Screen
[UserRewardsScreen] User ID: abc123xyz
[UserRewardsScreen] ═══════════════════════════════════════
[RewardService] ═══════════════════════════════════════
[RewardService] 📡 Setting up rewards stream
[RewardService] User ID: abc123xyz
[RewardService] ═══════════════════════════════════════
[RewardService] 📊 Stream update received
[RewardService] Documents count: 0
[RewardService] ℹ️ No rewards found for user
[RewardService] Possible reasons:
[RewardService] 1. No rewards have been sent to this user
[RewardService] 2. Wrong user ID
[RewardService] 3. Firestore rules blocking read
[UserRewardsScreen] 📦 Total rewards: 0
[UserRewardsScreen] ✅ Available: 0
```

### Error Logs (Permission Denied):
```
[UserRewardsScreen] ❌ Error: [cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation.
```

## Troubleshooting Steps

### Step 1: Verify Rewards Tab is Correct

1. **Run the app**
2. **Navigate to Rewards tab** (5th tab for female users)
3. **Check the app bar title** - Should say "My Rewards"
4. **Check tabs** - Should show "Available", "Claimed", "Expired"

If you see "Leaderboard" instead, the old screen is still being used.

### Step 2: Check Console Logs

1. **Open terminal/console** where app is running
2. **Navigate to Rewards tab**
3. **Look for logs** starting with `[UserRewardsScreen]` and `[RewardService]`
4. **Identify the issue** based on log messages

### Step 3: Verify Reward Was Sent

1. **Open Firebase Console**
   - Go to Firestore Database
   - Check `rewards` collection
   - Look for documents with your `userId`

2. **Check Reward Document Structure:**
```javascript
rewards/{rewardId}
{
  userId: "abc123xyz",  // ← Must match logged-in user
  userName: "John Doe",
  type: "coupon",
  title: "Top 10 Reward",
  description: "Congratulations!",
  couponCode: "CAMPUS50",
  couponValue: "50% OFF",
  status: "pending",  // ← Must be "pending" to show in Available tab
  createdAt: Timestamp,
  expiryDate: Timestamp (optional)
}
```

### Step 4: Verify User ID Matches

1. **Check logged-in user ID:**
   - Look for log: `[UserRewardsScreen] User ID: abc123xyz`

2. **Check reward userId:**
   - Open Firestore Console
   - Check reward document's `userId` field
   - **They must match exactly**

3. **Common Issue:**
   - Admin sent reward to User A
   - You're logged in as User B
   - User B won't see User A's rewards

### Step 5: Check Firestore Rules

1. **Open Firebase Console** → Firestore → Rules
2. **Verify this rule exists:**
```javascript
match /rewards/{rewardId} {
  allow write: if true;
  allow read: if isAuthenticated() && resource.data.userId == request.auth.uid || true;
}
```

3. **If missing**, copy from `firestore.rules` and publish

### Step 6: Test Sending a Reward

1. **Open Admin Dashboard**
2. **Go to Bulk Leaderboard**
3. **Find your test user**
4. **Click "Send Reward"**
5. **Fill details:**
   - Type: Coupon Code
   - Title: "Test Reward"
   - Code: "TEST123"
   - Value: "50% OFF"
6. **Click "Send Reward"**
7. **Check console for success logs**
8. **Switch to user account**
9. **Navigate to Rewards tab**
10. **Should see the reward**

## Common Issues & Solutions

### Issue 1: Empty Screen (No Rewards)

**Symptoms:**
- Rewards tab shows empty state
- Message: "No rewards available"

**Causes:**
1. No rewards have been sent to this user
2. Rewards sent to different user ID
3. All rewards are expired or claimed

**Solution:**
1. Send a test reward from admin panel
2. Verify user ID matches
3. Check reward status in Firestore

### Issue 2: Permission Denied Error

**Symptoms:**
- Error message on screen
- Console shows: `permission-denied`

**Causes:**
- Firestore rules not deployed
- Rules don't allow read access

**Solution:**
1. Deploy updated Firestore rules
2. Wait 1-2 minutes for propagation
3. Restart app
4. Try again

### Issue 3: Loading Forever

**Symptoms:**
- Spinner keeps spinning
- Never shows rewards or empty state

**Causes:**
- Firestore query hanging
- Network issue
- Wrong collection name

**Solution:**
1. Check internet connection
2. Check console for errors
3. Verify Firestore collection name is "rewards"
4. Restart app

### Issue 4: Wrong Screen Showing

**Symptoms:**
- Rewards tab shows leaderboard
- No "My Rewards" title
- No tabs (Available, Claimed, Expired)

**Causes:**
- Old code still running
- Hot reload didn't update
- Import not changed

**Solution:**
1. Stop the app completely
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `flutter run`
5. Navigate to Rewards tab

### Issue 5: Rewards Show in Firestore but Not in App

**Symptoms:**
- Firestore has rewards
- App shows empty state
- Console shows 0 documents

**Causes:**
- User ID mismatch
- Firestore rules blocking
- Query filter issue

**Solution:**
1. Check console log for user ID
2. Check Firestore reward's userId field
3. Verify they match exactly
4. Check Firestore rules allow read

## Testing Checklist

### Admin Side:
- [x] Open admin dashboard
- [x] Go to Bulk Leaderboard
- [x] Click "Send Reward" on test user
- [x] Fill reward details
- [x] Click "Send Reward"
- [x] See success message
- [x] Check Firestore - reward created
- [x] Note the userId in reward document

### User Side:
- [x] Login as the user who received reward
- [x] Navigate to Rewards tab (5th tab)
- [x] See "My Rewards" title
- [x] See three tabs: Available, Claimed, Expired
- [x] See reward in Available tab
- [x] View reward details
- [x] Copy coupon code
- [x] Claim reward
- [x] Verify it moves to Claimed tab

### Console Logs:
- [x] See `[UserRewardsScreen]` initialization logs
- [x] See `[RewardService]` stream setup logs
- [x] See document count > 0
- [x] See reward details in logs
- [x] No error messages

## Quick Fix Commands

If rewards still not showing:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check for errors
# Look for [UserRewardsScreen] and [RewardService] logs
```

## Expected User Experience

### When Rewards Exist:
1. Navigate to Rewards tab
2. See "My Rewards" with 3 tabs
3. Available tab shows unclaimed rewards
4. Beautiful gradient cards
5. Coupon code visible
6. "Claim Reward" button
7. Can copy coupon code
8. After claiming, moves to Claimed tab

### When No Rewards:
1. Navigate to Rewards tab
2. See "My Rewards" with 3 tabs
3. Empty state with icon
4. Message: "No rewards available"
5. Subtitle: "Keep engaging to earn rewards!"

## Summary

The issue was that the Rewards tab was showing the **Leaderboard screen** instead of the **User Rewards screen**. 

**Fixed by:**
1. ✅ Changed import from `RewardsLeaderboardScreen` to `UserRewardsScreen`
2. ✅ Updated screen list in home_screen.dart
3. ✅ Added comprehensive debug logging
4. ✅ Added error handling with retry button

**Now:**
- ✅ Rewards tab shows user's actual rewards
- ✅ Users can view coupon codes
- ✅ Users can claim rewards
- ✅ Debug logs help troubleshoot issues

**Next Step**: Run the app and check console logs to see if rewards are loading correctly.

---

**Status**: ✅ FIXED
**Last Updated**: Nov 29, 2025
