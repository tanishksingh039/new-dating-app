# Quick Fix - Firestore Index Error ⚡

## The Error You're Seeing

```
[cloud_firestore/failed-precondition] The query requires an index.
You can create it here: https://console.firebase.google.com/...
```

## Quick Fix (3 Steps)

### Option 1: Click the Link (Easiest - 30 seconds)

1. **Copy the link** from your console error
2. **Paste in browser** and press Enter
3. **Click "Create Index"** button
4. **Wait 2-5 minutes** for index to build
5. **Refresh app** - Done! ✅

### Option 2: Use Firebase Console (2 minutes)

1. **Go to**: https://console.firebase.google.com
2. **Select project**: campusbound-dating-app
3. **Click**: Firestore Database → Indexes tab
4. **Click**: "Create Index" button
5. **Fill in**:
   - Collection: `rewards`
   - Field 1: `userId` → Ascending
   - Field 2: `createdAt` → Descending
6. **Click**: "Create"
7. **Wait 2-5 minutes**
8. **Refresh app** - Done! ✅

### Option 3: Use CLI (1 minute)

```bash
# Run this command
firebase deploy --only firestore:indexes

# Or double-click this file
deploy_firestore_indexes.bat

# Wait 2-5 minutes
# Refresh app - Done! ✅
```

## What This Index Does

Allows Firestore to efficiently query rewards by:
- **Filter**: userId (find rewards for specific user)
- **Sort**: createdAt (newest first)

## Index Details

```
Collection: rewards
Fields:
  - userId: Ascending
  - createdAt: Descending
Status: Will show "Building" → "Enabled"
Time: 2-5 minutes
```

## How to Check Status

1. Open Firebase Console
2. Go to Firestore Database → Indexes
3. Look for `rewards` collection
4. Status should change from "Building" to "Enabled"
5. Once enabled, app will work!

## Files Updated

✅ `firestore.indexes.json` - Added rewards index
✅ `deploy_firestore_indexes.bat` - Quick deploy script
✅ `FIRESTORE_INDEX_REWARDS.md` - Detailed guide

## Summary

**Problem**: Query needs index to work
**Solution**: Create composite index
**Time**: 2-5 minutes to build
**Result**: Rewards will load correctly

Just create the index using any method above and wait a few minutes!

---

**Status**: Index Required
**Action**: Create index (choose any option above)
**ETA**: 2-5 minutes after creation
