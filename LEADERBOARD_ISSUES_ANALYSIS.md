# 🔍 Leaderboard Issues - Root Cause Analysis

## 📋 Issues Identified

### **Issue #1: Image Points Not Updating** ❌

**Symptom:** 
- Female user sends image with face
- System shows "+30 points" notification
- But points NOT added to leaderboard
- User score remains unchanged

**Root Cause Analysis:**

The image points flow is:
```
1. User sends image
2. awardImagePoints() called
3. Face detection ✅
4. _updateScore() called ✅
5. _updateImageTracking() called ✅
6. But... leaderboard NOT updated
```

**Problem Found:**
The issue is in how the leaderboard fetches data. Let me trace the flow:

```dart
// In rewards_leaderboard_screen.dart
Future<void> _loadData() async {
  final leaderboard = await _rewardsService.getMonthlyLeaderboard();
  // This queries rewards_stats collection
}

// In rewards_service.dart
Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
  final snapshot = await _firestore
      .collection('rewards_stats')
      .orderBy('monthlyScore', descending: true)
      .limit(20)
      .get();
  
  // ⚠️ PROBLEM: This is a one-time query, not real-time!
  // After points are awarded, this data is stale
}
```

**The Real Issue:**
1. ✅ Points ARE being awarded to `rewards_stats/{userId}`
2. ✅ `monthlyScore` is being updated in Firestore
3. ❌ But the leaderboard screen doesn't know about the update
4. ❌ It only loads data once at startup
5. ❌ No real-time listener to watch for changes

---

### **Issue #2: Top 20 Leaderboard Not Showing** ❌

**Symptom:**
- "No leaderboard data yet" message shown
- Top 20 section is empty
- Even though there should be data

**Root Cause Analysis:**

Looking at the code:

```dart
// In rewards_leaderboard_screen.dart line 115
final leaderboard = await _rewardsService.getMonthlyLeaderboard();

// In rewards_service.dart line 71-109
Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
  try {
    final snapshot = await _firestore
        .collection('rewards_stats')
        .orderBy('monthlyScore', descending: true)
        .limit(20)
        .get();

    List<LeaderboardEntry> leaderboard = [];
    int rank = 1;

    for (var doc in snapshot.docs) {
      final stats = UserRewardsStats.fromMap(doc.data());
      
      // Get user details
      final userDoc = await _firestore
          .collection('users')
          .doc(stats.userId)
          .get();
          
      if (userDoc.exists) {  // ⚠️ PROBLEM HERE!
        final user = UserModel.fromMap(userDoc.data()!);
        leaderboard.add(LeaderboardEntry(...));
        rank++;
      }
    }

    return leaderboard;
  } catch (e) {
    print('Error getting leaderboard: $e');
    return [];  // ⚠️ Returns empty list on ANY error!
  }
}
```

**Multiple Problems:**

1. **Silent Error Swallowing:**
   ```dart
   catch (e) {
     print('Error getting leaderboard: $e');
     return [];  // ❌ Returns empty list, no visibility!
   }
   ```
   If ANY error occurs, it returns empty list with no details.

2. **User Document Not Found:**
   ```dart
   if (userDoc.exists) {  // ❌ If user doc doesn't exist, entry is skipped!
     // Add to leaderboard
   }
   ```
   If a user in `rewards_stats` doesn't have a corresponding document in `users`, they're skipped.

3. **No Logging:**
   - No logs to show what's happening
   - No visibility into why leaderboard is empty
   - Can't debug the issue

4. **Firestore Query Issues:**
   - Query might be failing silently
   - No error details shown
   - Could be permission issues, missing indexes, etc.

---

## 🔧 Root Causes Summary

| Issue | Root Cause | Impact |
|-------|-----------|--------|
| **Image points not updating** | No real-time listener on leaderboard | Points awarded but not visible |
| **Top 20 not showing** | Silent error swallowing | Empty list shown, no error details |
| **Top 20 not showing** | Missing user documents | Valid users skipped |
| **Top 20 not showing** | No logging | Can't debug the issue |
| **Negative score (-19)** | Penalty applied but not visible | User sees wrong score |

---

## 🎯 The Complete Workflow

### **Current (Broken) Flow:**

```
User sends image
    ↓
awardImagePoints() called
    ↓
Face detection ✅
    ↓
_updateScore() called ✅
    ↓
rewards_stats/{userId}.monthlyScore += 30 ✅
    ↓
BUT: Leaderboard screen doesn't know about the update
    ↓
User sees old score (or negative score if penalty applied)
    ↓
"No leaderboard data yet" shown
```

### **Why Negative Score (-19)?**

Looking at the screenshot, the user has `-19` points. This suggests:
1. Penalties were applied (spam, duplicates, etc.)
2. But no positive points were awarded
3. Result: Negative total score

This happens because:
```dart
// In _updateScore():
if (!snapshot.exists) {
  // Create new stats with initial points
  final newStats = UserRewardsStats(
    totalScore: points,  // ← If points is negative (penalty), score is negative!
    monthlyScore: points,
  );
}
```

---

## 🔍 Detailed Code Analysis

### **Problem 1: No Real-Time Updates**

**File:** `lib/screens/rewards/rewards_leaderboard_screen.dart`

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  _loadCachedStats();
  _userStatsStream = _rewardsService.getUserStatsStream(currentUserId);
  _loadData();  // ← ONE-TIME LOAD
  _startAutoRefresh();  // ← Tries to refresh every 5 seconds
}

void _startAutoRefresh() {
  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) {
      setState(() {
        _userStatsStream = _rewardsService.getUserStatsStream(currentUserId);
      });
      _startAutoRefresh();
    }
  });
}
```

**Issues:**
1. `_loadData()` is called once at startup
2. `_startAutoRefresh()` recreates the stream every 5 seconds (inefficient)
3. But `_leaderboard` list is NOT updated in real-time
4. Leaderboard data is stale after initial load

---

### **Problem 2: Silent Error Swallowing**

**File:** `lib/services/rewards_service.dart`

```dart
Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
  try {
    final snapshot = await _firestore
        .collection('rewards_stats')
        .orderBy('monthlyScore', descending: true)
        .limit(20)
        .get();

    List<LeaderboardEntry> leaderboard = [];
    int rank = 1;

    for (var doc in snapshot.docs) {
      final stats = UserRewardsStats.fromMap(doc.data());
      
      final userDoc = await _firestore
          .collection('users')
          .doc(stats.userId)
          .get();
          
      if (userDoc.exists) {
        final user = UserModel.fromMap(userDoc.data()!);
        leaderboard.add(LeaderboardEntry(...));
        rank++;
      }
      // ⚠️ If user doc doesn't exist, silently skip!
    }

    return leaderboard;
  } catch (e) {
    print('Error getting leaderboard: $e');  // ⚠️ Only prints, no details!
    return [];  // ⚠️ Returns empty list!
  }
}
```

**Issues:**
1. If Firestore query fails, returns empty list
2. If user document doesn't exist, entry is skipped silently
3. No logging of skipped entries
4. No error details visible
5. Can't distinguish between "no data" and "error"

---

### **Problem 3: Negative Score Issue**

**File:** `lib/services/rewards_service.dart`

```dart
Future<void> _updateScore(String userId, int points, String? statField) async {
  try {
    final docRef = _firestore.collection('rewards_stats').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        // ⚠️ PROBLEM: If points is negative (penalty), score starts negative!
        final newStats = UserRewardsStats(
          userId: userId,
          totalScore: points,  // ← Could be negative!
          weeklyScore: points,
          monthlyScore: points,
          ...
        );
        transaction.set(docRef, newStats.toMap());
      } else {
        // Update existing
        final updates = {
          'totalScore': oldTotal + points,  // ← Could go negative!
          'monthlyScore': oldMonthly + points,
          ...
        };
        transaction.update(docRef, updates);
      }
    });
  } catch (e) {
    debugPrint('❌ ERROR updating score: $e');
    rethrow;
  }
}
```

**Issue:**
- If first action is a penalty (negative points), score becomes negative
- No minimum score check
- User sees `-19` instead of `0`

---

## 🚀 Fixes Required

### **Fix #1: Add Real-Time Leaderboard Listener**

Add a real-time listener to the leaderboard screen:

```dart
// In rewards_leaderboard_screen.dart
Stream<List<LeaderboardEntry>> _getLeaderboardStream() {
  return _firestore
      .collection('rewards_stats')
      .orderBy('monthlyScore', descending: true)
      .limit(20)
      .snapshots()
      .asyncMap((snapshot) async {
        List<LeaderboardEntry> leaderboard = [];
        int rank = 1;
        
        for (var doc in snapshot.docs) {
          final stats = UserRewardsStats.fromMap(doc.data());
          final userDoc = await _firestore
              .collection('users')
              .doc(stats.userId)
              .get();
          
          if (userDoc.exists) {
            final user = UserModel.fromMap(userDoc.data()!);
            leaderboard.add(LeaderboardEntry(...));
            rank++;
          }
        }
        
        return leaderboard;
      });
}
```

Then use it in the UI:

```dart
StreamBuilder<List<LeaderboardEntry>>(
  stream: _getLeaderboardStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Column(
        children: snapshot.data!
            .map((entry) => _buildLeaderboardEntry(entry))
            .toList(),
      );
    }
    return const CircularProgressIndicator();
  },
)
```

---

### **Fix #2: Add Detailed Logging**

```dart
Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
  print('[RewardsService] 🔄 getMonthlyLeaderboard STARTED');
  try {
    print('[RewardsService] 📊 Querying rewards_stats...');
    final snapshot = await _firestore
        .collection('rewards_stats')
        .orderBy('monthlyScore', descending: true)
        .limit(20)
        .get();
    
    print('[RewardsService] ✅ Query returned ${snapshot.docs.length} documents');

    List<LeaderboardEntry> leaderboard = [];
    int rank = 1;
    int skipped = 0;

    for (var doc in snapshot.docs) {
      final stats = UserRewardsStats.fromMap(doc.data());
      
      final userDoc = await _firestore
          .collection('users')
          .doc(stats.userId)
          .get();
          
      if (userDoc.exists) {
        final user = UserModel.fromMap(userDoc.data()!);
        leaderboard.add(LeaderboardEntry(...));
        rank++;
      } else {
        print('[RewardsService] ⚠️ User document not found: ${stats.userId}');
        skipped++;
      }
    }

    print('[RewardsService] ✅ Leaderboard built: ${leaderboard.length} entries, $skipped skipped');
    return leaderboard;
  } catch (e, stackTrace) {
    print('[RewardsService] ❌ EXCEPTION in getMonthlyLeaderboard: $e');
    print('[RewardsService] ❌ Stack trace: $stackTrace');
    return [];
  }
}
```

---

### **Fix #3: Prevent Negative Scores**

```dart
Future<void> _updateScore(String userId, int points, String? statField) async {
  try {
    final docRef = _firestore.collection('rewards_stats').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        // ✅ Ensure score never goes below 0
        final newStats = UserRewardsStats(
          userId: userId,
          totalScore: max(0, points),  // ← Never negative!
          weeklyScore: max(0, points),
          monthlyScore: max(0, points),
          ...
        );
        transaction.set(docRef, newStats.toMap());
      } else {
        final data = snapshot.data()!;
        final oldTotal = data['totalScore'] ?? 0;
        final oldMonthly = data['monthlyScore'] ?? 0;
        
        final updates = {
          'totalScore': max(0, oldTotal + points),  // ← Never negative!
          'monthlyScore': max(0, oldMonthly + points),
          ...
        };
        transaction.update(docRef, updates);
      }
    });
  } catch (e, stackTrace) {
    print('[RewardsService] ❌ ERROR updating score: $e');
    print('[RewardsService] ❌ Stack trace: $stackTrace');
    rethrow;
  }
}
```

---

## 📊 Expected Behavior After Fixes

### **Before Fixes:**
- ❌ Image sent → No points visible
- ❌ Leaderboard empty
- ❌ Negative score shown
- ❌ No error details

### **After Fixes:**
- ✅ Image sent → Points immediately visible
- ✅ Leaderboard updates in real-time
- ✅ Score always ≥ 0
- ✅ Detailed logs for debugging

---

## 🎯 Next Steps

1. **Implement real-time leaderboard listener**
2. **Add detailed logging to getMonthlyLeaderboard()**
3. **Add minimum score check (max(0, score))**
4. **Test with image uploads**
5. **Verify leaderboard updates in real-time**

---

## 📝 Summary

The leaderboard system has two main issues:

1. **Image points not updating** - No real-time listener, data is stale
2. **Top 20 not showing** - Silent errors, missing user documents, no logging

Both can be fixed by:
- Adding real-time listeners
- Adding detailed logging
- Preventing negative scores

**The points ARE being awarded to Firestore, but the UI doesn't know about it!**
