# 🔍 SWIPE COUNT DOUBLING - DEBUG ANALYSIS

## 📊 Current System Architecture

### Data Flow
```
Firestore (swipe_stats collection)
    ↓
SwipeLimitService.getSwipeStats()
    ↓
SwipeStats model
    ↓
SwipeLimitService.getSwipeSummary()
    ↓
SwipeLimitIndicator widget
    ↓
UI Display
```

---

## 🧮 Calculation Logic

### Step 1: Get Swipe Stats from Firestore
```dart
// swipe_stats/{userId}
{
  totalSwipes: 10,              // Total swipes ever made (counter)
  freeSwipesUsed: 4,            // Free swipes used
  purchasedSwipesRemaining: 50, // Purchased swipes left
  lastResetDate: DateTime
}
```

### Step 2: Calculate Remaining Swipes

**In `getSwipeSummary()` (line 313-315):**
```dart
final freeSwipesLimit = SwipeConfig.getFreeSwipes(isPremium);
// Non-premium: 8, Premium: 50

final freeSwipesRemaining = stats.getRemainingFreeSwipes(freeSwipesLimit);
// Formula: (freeSwipesLimit - freeSwipesUsed).clamp(0, freeSwipesLimit)

final totalRemaining = stats.getTotalRemainingSwipes(freeSwipesLimit);
// Formula: freeSwipesRemaining + purchasedSwipesRemaining
```

### Step 3: Display in UI

**In `SwipeLimitIndicator` (line 24, 58):**
```dart
final totalRemaining = summary['totalRemaining'] as int;

Text('$totalRemaining swipe${totalRemaining == 1 ? '' : 's'}')
```

---

## 🐛 POTENTIAL BUG SOURCES

### Bug Source #1: Premium Limit Confusion ⚠️

**Issue:** When a non-premium user (8 swipes) upgrades to premium (50 swipes), the calculation might be wrong.

**Example:**
```
Non-Premium User:
├─ freeSwipesLimit: 8
├─ freeSwipesUsed: 4
├─ freeSwipesRemaining: 8 - 4 = 4 ✅
└─ purchasedSwipesRemaining: 0

User upgrades to PREMIUM (adds 50 swipes)
    ↓

Premium User:
├─ freeSwipesLimit: 50 (changed!)
├─ freeSwipesUsed: 4 (unchanged)
├─ freeSwipesRemaining: 50 - 4 = 46 ❌ WRONG!
└─ purchasedSwipesRemaining: 50

TOTAL: 46 + 50 = 96 swipes ❌ DOUBLE!
```

**Expected:**
```
Should be: 4 + 50 = 54 swipes
```

---

### Bug Source #2: `totalSwipes` Field Confusion

**Issue:** The `totalSwipes` field is incremented on every swipe but never used in display calculation. This could cause confusion if it's accidentally used somewhere.

**In `useSwipe()` (line 167, 174):**
```dart
updatedStats = stats.copyWith(
  totalSwipes: stats.totalSwipes + 1,  // ⚠️ Incremented but not used
  freeSwipesUsed: stats.freeSwipesUsed + 1,
);
```

**Check:** Is `totalSwipes` being used anywhere in the UI?
- ❌ NOT used in `getSwipeSummary()`
- ❌ NOT used in `SwipeLimitIndicator`
- ✅ Only used as a counter in Firestore

---

### Bug Source #3: Stream Double-Firing

**Issue:** The StreamBuilder might be firing twice, causing double updates.

**In `SwipeLimitIndicator` (line 13-14):**
```dart
stream: swipeLimitService.swipeStatsStream().asyncMap(
  (_) => swipeLimitService.getSwipeSummary(),
),
```

**Check:** Is `swipeStatsStream()` emitting duplicate events?

---

## 🔬 DIAGNOSTIC TESTS

### Test 1: Non-Premium User with 4 Swipes

**Firestore Data:**
```json
{
  "freeSwipesUsed": 4,
  "purchasedSwipesRemaining": 0
}
```

**Expected Calculation:**
```
freeSwipesLimit = 8
freeSwipesRemaining = 8 - 4 = 4
totalRemaining = 4 + 0 = 4 ✅
```

**UI Should Show:** `4 swipes`

---

### Test 2: Premium User After Upgrade (4 swipes → 54 swipes)

**Firestore Data BEFORE:**
```json
{
  "freeSwipesUsed": 4,
  "purchasedSwipesRemaining": 0
}
```

**After `upgradeToPremium()`:**
```json
{
  "freeSwipesUsed": 4,
  "purchasedSwipesRemaining": 50
}
```

**Calculation:**
```
freeSwipesLimit = 50 (premium)
freeSwipesRemaining = 50 - 4 = 46 ❌ WRONG!
totalRemaining = 46 + 50 = 96 ❌ DOUBLE!
```

**UI Shows:** `96 swipes` ❌ (Expected: 54)

---

## 🎯 ROOT CAUSE IDENTIFIED!

### **THE BUG IS IN THE PREMIUM UPGRADE LOGIC**

When upgrading to premium:
1. `freeSwipesLimit` changes from 8 → 50
2. `freeSwipesUsed` stays at 4
3. `freeSwipesRemaining` = 50 - 4 = **46** (should be 4!)
4. `purchasedSwipesRemaining` = 50 (added)
5. **Total = 46 + 50 = 96** ❌ WRONG!

**Expected:**
- `freeSwipesRemaining` should be 4 (not 46)
- `Total = 4 + 50 = 54` ✅

---

## 💡 THE FIX

### Option 1: Don't Change Free Swipes Limit for Existing Users

When upgrading to premium, keep the free swipes calculation based on the ORIGINAL limit (8), not the new premium limit (50).

```dart
// In getSwipeSummary()
final originalLimit = 8; // Always use 8 for non-premium users
final freeSwipesRemaining = stats.getRemainingFreeSwipes(originalLimit);
```

### Option 2: Reset Free Swipes Used on Premium Upgrade

When upgrading to premium, reset `freeSwipesUsed` to 0.

```dart
// In upgradeToPremium()
await _firestore
    .collection('swipe_stats')
    .doc(user.uid)
    .update({
  'freeSwipesUsed': 0,  // Reset!
  'purchasedSwipesRemaining': stats.purchasedSwipesRemaining + 50,
});
```

### Option 3: Track Original Limit in Firestore ✅ RECOMMENDED

Add a field `originalFreeSwipesLimit` to track the limit when the user started.

```dart
// In swipe_stats
{
  originalFreeSwipesLimit: 8,  // Set on account creation
  freeSwipesUsed: 4,
  purchasedSwipesRemaining: 50
}

// In getSwipeSummary()
final freeSwipesLimit = stats.originalFreeSwipesLimit ?? 8;
final freeSwipesRemaining = stats.getRemainingFreeSwipes(freeSwipesLimit);
```

---

## 🧪 VERIFICATION STEPS

1. **Check Firestore Data:**
   - Look at `swipe_stats/{userId}`
   - Check `freeSwipesUsed` value
   - Check `purchasedSwipesRemaining` value
   - Check if user is premium

2. **Add Debug Logging:**
   ```dart
   print('🔍 freeSwipesLimit: $freeSwipesLimit');
   print('🔍 freeSwipesUsed: ${stats.freeSwipesUsed}');
   print('🔍 freeSwipesRemaining: $freeSwipesRemaining');
   print('🔍 purchasedSwipesRemaining: ${stats.purchasedSwipesRemaining}');
   print('🔍 totalRemaining: $totalRemaining');
   ```

3. **Test Premium Upgrade:**
   - Start with 4 swipes left (non-premium)
   - Upgrade to premium
   - Check UI display
   - Expected: 54 swipes
   - If showing: 96 swipes → Bug confirmed!

---

## 📝 SUMMARY

### The Problem
UI is showing **double the swipe count** after premium upgrade.

### Root Cause
When upgrading to premium, `freeSwipesLimit` changes from 8 to 50, but `freeSwipesUsed` stays the same. This causes:
- `freeSwipesRemaining = 50 - 4 = 46` (should be 4)
- `Total = 46 + 50 = 96` (should be 54)

### The Fix
Use the **original free swipes limit** (8) for calculating remaining free swipes, not the new premium limit (50).

---

**Status**: 🔍 Bug identified, fix needed!
