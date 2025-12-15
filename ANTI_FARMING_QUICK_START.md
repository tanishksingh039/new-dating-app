# Anti-Farming System - Quick Start

## What Was Implemented

A fair leaderboard system that prevents point farming by limiting interactions with a single user to **35 minutes per 6-hour window**.

## The Golden Rule

**A single user can contribute a maximum of 35 minutes of leaderboard points every 6 hours.**

## How It Works

### Time Windows

Day is split into 4 windows:
- **Window 1:** 12:00 AM – 6:00 AM
- **Window 2:** 6:00 AM – 12:00 PM
- **Window 3:** 12:00 PM – 6:00 PM
- **Window 4:** 6:00 PM – 12:00 AM

### Per-User Cap

Within each window:
- **First 35 minutes** with one user → Points awarded ✅
- **After 35 minutes** with same user → No points ❌
- **With different user** → Full 35 minutes again ✅

### Daily Maximum

- Max 35 minutes × 4 windows = **140 minutes (2 hours 20 minutes) per day** with same user
- To grow on leaderboard → **Must engage with multiple different users**

## Example

**Scenario:** Female user talks to Male user A

- **6:15 AM:** Sends 20-minute message → +10 points ✅
- **10:30 AM:** Sends 15-minute message → +10 points ✅
- **11:45 AM:** Sends 10-minute message → 0 points ❌ (35-minute cap reached)

**Result:** First 35 minutes earn points, rest don't

## Key Features

✅ **Server-side enforcement** - No client-side bypass
✅ **Automatic window reset** - Every 6 hours
✅ **No rollover** - Unused minutes don't carry over
✅ **Persistent** - App restart doesn't reset limits
✅ **Per-user tracking** - Different users = different caps

## User Experience

### When Points Are Awarded
```
✅ "Message sent! +10 points earned"
```

### When Cap Is Reached
```
⚠️ "Message sent but no points earned"
(Can still message, just no leaderboard points)
```

## Implementation

### Service Created
- `lib/services/leaderboard_anti_farming_service.dart`
  - Tracks interactions per user per window
  - Enforces 35-minute cap
  - Manages Firestore data

### Services Updated
- `lib/services/rewards_service.dart`
  - Added anti-farming check to `awardMessagePoints()`
  - Added anti-farming check to `awardImagePoints()`

### UI Updated
- `lib/screens/chat/chat_screen.dart`
  - Passes `otherUserId` for anti-farming checks

## Firestore Collection

**Collection:** `interaction_tracking`

Tracks:
- Female user ID
- Male user ID
- Current window
- Minutes used in window
- Interaction history

## Benefits

✅ **Fair Competition** - No single-user farming
✅ **Encourages Diversity** - Must engage with multiple users
✅ **Healthier Ecosystem** - Better engagement distribution
✅ **Higher Retention** - Users stay engaged longer
✅ **Prevents Abuse** - Stops point manipulation

## Testing

1. **Test within cap:**
   - Send messages to one user for 30 minutes
   - Should earn points ✅

2. **Test exceeding cap:**
   - Continue messaging same user past 35 minutes
   - Should NOT earn points ❌

3. **Test different user:**
   - Switch to different user
   - Should earn points again ✅

4. **Test window reset:**
   - Wait for 6-hour window to change
   - Should earn points with same user again ✅

## Debug Logs

Check console for anti-farming checks:

```
[AntiArmingService] 🔍 Checking points eligibility
[AntiArmingService] 📊 Points minutes used: 20 / 35
[AntiArmingService] ✅ Can still earn points (15 minutes remaining)
```

## Summary

The anti-farming system ensures fair leaderboard rankings by:

✅ **Limiting** interactions to 35 minutes per user per window
✅ **Enforcing** server-side with no bypass
✅ **Resetting** every 6 hours
✅ **Encouraging** engagement with multiple users
✅ **Maintaining** fairness for all users

**Result:** Healthy, fair leaderboard that rewards genuine engagement over point farming.
