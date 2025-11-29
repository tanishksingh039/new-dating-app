# Firestore Index Required - Rewards Collection

## Error
You're seeing an index error when trying to load rewards because Firestore requires a composite index for queries that use both `where()` and `orderBy()` on different fields.

## The Query Causing the Error

```dart
_firestore
  .collection('rewards')
  .where('userId', isEqualTo: userId)  // Filter by userId
  .orderBy('createdAt', descending: true)  // Sort by createdAt
  .snapshots()
```

## Solution: Create Composite Index

### Method 1: Click the Link in Console (Easiest)

1. **Run the app** and navigate to Rewards tab
2. **Check the console** - You'll see an error like:
   ```
   [cloud_firestore/failed-precondition] The query requires an index.
   You can create it here: https://console.firebase.google.com/...
   ```
3. **Click the link** in the error message
4. **Firebase Console will open** with the index pre-configured
5. **Click "Create Index"** button
6. **Wait 2-5 minutes** for index to build
7. **Refresh the app** - Rewards should now load

### Method 2: Manual Creation in Firebase Console

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Select your project: `campusbound-dating-app`

2. **Navigate to Firestore Indexes**
   - Click "Firestore Database" in left sidebar
   - Click "Indexes" tab at the top
   - Click "Create Index" button

3. **Configure the Index**
   - **Collection ID**: `rewards`
   - **Fields to index**:
     - Field 1: `userId` → Ascending
     - Field 2: `createdAt` → Descending
   - **Query scope**: Collection

4. **Create the Index**
   - Click "Create" button
   - Wait for "Building" status to change to "Enabled"
   - Usually takes 2-5 minutes

### Method 3: Use Firebase CLI (Advanced)

1. **Create `firestore.indexes.json` file** in project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "rewards",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

2. **Deploy the index**:
```bash
firebase deploy --only firestore:indexes
```

3. **Wait for index to build** (2-5 minutes)

## Index Configuration Details

### Index Name
`rewards_userId_createdAt`

### Collection
`rewards`

### Fields
| Field Path | Order |
|------------|-------|
| userId | Ascending |
| createdAt | Descending |

### Query Scope
Collection

### Status
Should show "Enabled" when ready

## Verification Steps

### 1. Check Index Status

1. Open Firebase Console → Firestore → Indexes
2. Look for index on `rewards` collection
3. Status should be "Enabled" (not "Building")

### 2. Test in App

1. Run the app
2. Navigate to Rewards tab
3. Should load without errors
4. Console should show:
   ```
   [RewardService] 📊 Stream update received
   [RewardService] Documents count: X
   ```

### 3. Check Console Logs

**Before Index (Error):**
```
[cloud_firestore/failed-precondition] The query requires an index.
You can create it here: https://console.firebase.google.com/...
```

**After Index (Success):**
```
[RewardService] 📡 Setting up rewards stream
[RewardService] User ID: abc123
[RewardService] 📊 Stream update received
[RewardService] Documents count: 2
```

## Why This Index is Needed

Firestore requires a composite index when you:
1. ✅ Filter by one field (`where('userId', isEqualTo: ...)`)
2. ✅ Sort by a different field (`orderBy('createdAt', descending: true)`)

Without the index, Firestore doesn't know how to efficiently query and sort the data.

## Alternative Solution (If Index Creation Fails)

If you can't create the index, you can modify the query to not use `orderBy`:

**Update `reward_service.dart`:**

```dart
// Option 1: Remove orderBy (rewards won't be sorted)
static Stream<List<RewardModel>> getUserRewards(String userId) {
  return _firestore
      .collection('rewards')
      .where('userId', isEqualTo: userId)
      // Remove: .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    // Sort in memory instead
    final rewards = snapshot.docs
        .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
        .toList();
    
    rewards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rewards;
  });
}
```

**Note**: This is less efficient but works without an index.

## Other Indexes You Might Need

If you see similar errors for other queries, you may need these indexes:

### 1. Rewards by Status
```json
{
  "collectionGroup": "rewards",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "userId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

### 2. Reports by Status
```json
{
  "collectionGroup": "reports",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

## Troubleshooting

### Issue: Index Still Building After 10 Minutes

**Solution:**
1. Refresh Firebase Console page
2. Check if status changed to "Enabled"
3. If still building, wait longer (can take up to 30 minutes for large collections)
4. If fails, delete and recreate index

### Issue: Can't Click Link in Console

**Solution:**
1. Copy the URL from console
2. Paste in browser
3. Or use Manual Creation method above

### Issue: Index Creation Fails

**Solution:**
1. Check Firebase project permissions
2. Make sure you're project owner/editor
3. Try using Firebase CLI method
4. Contact Firebase support if persistent

## Summary

**Quick Fix:**
1. ✅ Run the app
2. ✅ Navigate to Rewards tab
3. ✅ Copy error link from console
4. ✅ Click link to open Firebase Console
5. ✅ Click "Create Index"
6. ✅ Wait 2-5 minutes
7. ✅ Refresh app - Rewards should load!

**Index Details:**
- **Collection**: `rewards`
- **Field 1**: `userId` (Ascending)
- **Field 2**: `createdAt` (Descending)
- **Time**: 2-5 minutes to build

---

**Status**: Index Required
**Action**: Create composite index in Firebase Console
**ETA**: 2-5 minutes after creation
