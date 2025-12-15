# Leaderboard Anti-Farming System

## Overview

A fair leaderboard system that prevents point farming by limiting interactions with a single user to 35 minutes per 6-hour window. This ensures users must engage with multiple different users to climb the leaderboard, promoting healthier ecosystem engagement.

## Golden Rule

**A single user can contribute a maximum of 35 minutes of leaderboard points every 6 hours.**

## Time Window System

### 6-Hour Windows

The day is divided into 4 rolling 6-hour windows:

| Window | Time Range |
|--------|-----------|
| Window 1 | 12:00 AM – 6:00 AM |
| Window 2 | 6:00 AM – 12:00 PM |
| Window 3 | 12:00 PM – 6:00 PM |
| Window 4 | 6:00 PM – 12:00 AM |

### Daily Maximum

- **Per Window:** 35 minutes with one user
- **Per Day:** 35 × 4 = 140 minutes (2 hours 20 minutes) with same user
- **To Grow:** Must engage with multiple different users

## Implementation Details

### Files Created

**`lib/services/leaderboard_anti_farming_service.dart`**

Core service that manages interaction tracking and enforces limits:

```dart
class LeaderboardAntiArmingService {
  // Constants
  static const int WINDOW_DURATION_HOURS = 6;
  static const int MAX_POINTS_MINUTES_PER_USER_PER_WINDOW = 35;
  static const int WINDOWS_PER_DAY = 4;
  static const int MAX_POINTS_MINUTES_PER_DAY = 140;

  // Key Methods
  Future<bool> canEarnPointsWithUser(String femaleUserId, String maleUserId)
  Future<void> recordInteraction(String femaleUserId, String maleUserId, int durationSeconds)
  Future<int> getRemainingPointsMinutes(String femaleUserId, String maleUserId)
  Future<Map<String, dynamic>> getDailyStats(String femaleUserId)
  Future<void> cleanupOldRecords()
}
```

### Files Modified

**`lib/services/rewards_service.dart`**

Updated methods to check anti-farming limits:

```dart
// Award points for message sent
Future<void> awardMessagePoints(
  String userId,
  String conversationId,
  String messageText, {
  String? otherUserId,  // NEW: Required for anti-farming check
}) async {
  // Check anti-farming limits FIRST
  if (otherUserId != null) {
    final antiArmingService = LeaderboardAntiArmingService();
    final canEarnPoints = await antiArmingService.canEarnPointsWithUser(userId, otherUserId);
    if (!canEarnPoints) {
      return; // No points awarded
    }
  }
  // ... rest of logic
}

// Award points for image sent
Future<void> awardImagePoints(
  String userId,
  String conversationId,
  String imagePath, {
  String? profileImagePath,
  String? otherUserId,  // NEW: Required for anti-farming check
}) async {
  // Check anti-farming limits FIRST
  if (otherUserId != null) {
    final antiArmingService = LeaderboardAntiArmingService();
    final canEarnPoints = await antiArmingService.canEarnPointsWithUser(userId, otherUserId);
    if (!canEarnPoints) {
      return; // No points awarded
    }
  }
  // ... rest of logic
}
```

**`lib/screens/chat/chat_screen.dart`**

Updated to pass `otherUserId` parameter:

```dart
// When awarding message points
await _rewardsService.awardMessagePoints(
  widget.currentUserId,
  chatId,
  messageText,
  otherUserId: widget.otherUserId,  // NEW
);

// When awarding image points
await _rewardsService.awardImagePoints(
  widget.currentUserId,
  chatId,
  imageFile.path,
  profileImagePath: profilePhotoPath,
  otherUserId: widget.otherUserId,  // NEW
);
```

## Firestore Data Structure

### Collection: `interaction_tracking`

Document ID: `{femaleUserId}_{maleUserId}_{windowId}`

```json
{
  "femaleUserId": "user123",
  "maleUserId": "user456",
  "windowId": "2024-12-14_window_2",
  "windowStart": Timestamp(2024-12-14 06:00:00),
  "pointsMinutesUsed": 35,
  "lastUpdated": Timestamp(2024-12-14 11:45:00),
  "interactions": [
    {
      "timestamp": Timestamp(2024-12-14 06:15:00),
      "durationSeconds": 1200,
      "durationMinutes": 20
    },
    {
      "timestamp": Timestamp(2024-12-14 10:30:00),
      "durationSeconds": 900,
      "durationMinutes": 15
    }
  ]
}
```

## How It Works

### Step 1: Check Eligibility

When a user sends a message or image:

```
User sends message/image
  ↓
Extract otherUserId from conversation
  ↓
Get current 6-hour window
  ↓
Query interaction_tracking document
  ↓
Check: pointsMinutesUsed < 35?
  ├─ YES → Continue to award points
  └─ NO → Return without awarding points
```

### Step 2: Award Points (if eligible)

```
Points awarded
  ↓
Record interaction in Firestore
  ↓
Update pointsMinutesUsed
  ↓
Add to interactions array
```

### Step 3: Window Reset

```
6-hour window ends
  ↓
New window begins
  ↓
pointsMinutesUsed resets to 0
  ↓
User can earn 35 minutes with same user again
```

## Example Scenarios

### Scenario 1: Within 35-Minute Cap

**Time:** 6:00 AM – 12:00 PM (Window 2)

**Actions:**
- 6:15 AM: Female sends 20-minute message → +10 points ✅
- 10:30 AM: Female sends 15-minute message → +10 points ✅
- Total: 35 minutes used

**Result:** Both messages earn points

### Scenario 2: Exceeding 35-Minute Cap

**Time:** 6:00 AM – 12:00 PM (Window 2)

**Actions:**
- 6:15 AM: Female sends 30-minute message → +10 points ✅
- 10:30 AM: Female sends 20-minute message → 0 points ❌
- Total: 30 minutes used (cap exceeded)

**Result:** Second message sent but NO points awarded

### Scenario 3: Multiple Users

**Time:** 6:00 AM – 12:00 PM (Window 2)

**Actions:**
- 6:15 AM: Female sends 35 minutes to Male A → +10 points ✅
- 10:30 AM: Female sends 30 minutes to Male B → +10 points ✅
- Total: 65 minutes (different users)

**Result:** Both earn points (different user pairs)

### Scenario 4: Window Reset

**Time:** 11:50 AM – 12:10 PM (Window 2 → Window 3)

**Actions:**
- 11:50 AM: Female sends 30 minutes to Male A (Window 2) → +10 points ✅
- 12:10 PM: Female sends 20 minutes to Male A (Window 3) → +10 points ✅
- Total: 50 minutes (different windows)

**Result:** Both earn points (new window resets cap)

## Enforcement Rules

✅ **Server-Side Only** - All calculations enforced on backend
✅ **No Rollover** - Unused minutes don't carry to next window
✅ **No Stacking** - Can't earn 70 minutes in one window
✅ **No Client Bypass** - App restart doesn't reset limits
✅ **Persistent Tracking** - Limits enforced across sessions

## User Experience

### Success Message

```
✅ "Message sent! +10 points earned"
- Points awarded
- Interaction recorded
```

### Cap Reached Message

```
⚠️ "Message sent but no points earned"
- Message delivered
- No points awarded
- Remaining time: 0 minutes with this user
```

### Remaining Time Display (Optional)

```
"You have 15 minutes remaining with this user in this window"
- Shows how much time left before cap
- Encourages engagement with other users
```

## Debug Logging

Console logs show anti-farming checks:

```
[AntiArmingService] 🔍 Checking points eligibility
[AntiArmingService] Female: user123, Male: user456
[AntiArmingService] Window: 2024-12-14_window_2

[AntiArmingService] 📊 Points minutes used: 20 / 35
[AntiArmingService] ✅ Can still earn points (15 minutes remaining)

// OR

[AntiArmingService] ❌ Points cap reached for this user in this window
```

## Benefits

✅ **Fair Competition** - Prevents single-user farming
✅ **Encourages Diversity** - Users must engage with multiple people
✅ **Healthier Ecosystem** - Better engagement ratios
✅ **Higher Retention** - Users stay engaged longer
✅ **Prevents Abuse** - Stops point manipulation

## Cleanup

Old interaction records (>7 days) are automatically cleaned up:

```dart
// Runs periodically
await antiArmingService.cleanupOldRecords();
```

This keeps the `interaction_tracking` collection lean and performant.

## Future Enhancements

1. **Admin Dashboard** - View anti-farming metrics
2. **User Analytics** - Show engagement distribution
3. **Warnings** - Notify users when approaching cap
4. **Adjustable Caps** - Admin can modify limits per event
5. **Exemptions** - Allow certain users to bypass limits

## Summary

The anti-farming system ensures fair leaderboard rankings by:

✅ **Limiting interactions** to 35 minutes per user per 6-hour window
✅ **Enforcing server-side** with no client-side bypass
✅ **Resetting daily** with 4 independent windows
✅ **Encouraging diversity** by requiring multiple users for growth
✅ **Maintaining fairness** across all users

**Result:** A healthy, fair leaderboard that rewards genuine engagement over point farming.
