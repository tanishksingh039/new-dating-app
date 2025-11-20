# Firestore Index Setup Guide

## Problem
When querying reports with `where('reporterId')` + `orderBy('createdAt')`, Firestore requires a composite index.

## Error You Might See
```
Error: The query requires an index. You can create it here: [link]
```

## Solution: Create Firestore Index

### **Option 1: Automatic (Recommended)**

1. **Run the app and navigate to "My Reports"**
2. **You'll see an error with a link**
3. **Click the link** - it will open Firebase Console
4. **Click "Create Index"**
5. **Wait 2-5 minutes** for index to build
6. **Refresh the app** - reports will now show!

---

### **Option 2: Manual Setup**

#### **Step 1: Go to Firebase Console**
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **CampusBound**
3. Click **Firestore Database** in left menu
4. Click **Indexes** tab

#### **Step 2: Create Composite Index**
1. Click **"Create Index"** button
2. Fill in the details:

```
Collection ID: reports
Fields to index:
  - reporterId (Ascending)
  - createdAt (Descending)
Query scope: Collection
```

3. Click **"Create"**
4. Wait 2-5 minutes for index to build

#### **Step 3: Verify**
1. Go back to your app
2. Navigate to Settings → My Reports
3. Your submitted reports should now appear!

---

### **Option 3: Deploy Index from File**

We've already added the index configuration to `firestore.indexes.json`.

To deploy it:

```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firestore (if not done)
firebase init firestore

# Deploy indexes
firebase deploy --only firestore:indexes
```

---

## Index Configuration

The index is already defined in `firestore.indexes.json`:

```json
{
  "collectionGroup": "reports",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "reporterId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

---

## What This Index Does

Allows efficient queries like:
```dart
FirebaseFirestore.instance
    .collection('reports')
    .where('reporterId', isEqualTo: currentUserId)
    .orderBy('createdAt', descending: true)
    .snapshots()
```

This query is used in:
- **My Reports Screen** (user-facing)
- Shows all reports submitted by the current user
- Sorted by most recent first

---

## Troubleshooting

### **Reports Still Not Showing?**

1. **Check if report was actually created:**
   - Go to Firebase Console → Firestore Database
   - Look for `reports` collection
   - Check if your report document exists
   - Verify `reporterId` matches your user ID

2. **Check index status:**
   - Firebase Console → Firestore → Indexes
   - Look for "reports" index
   - Status should be "Enabled" (not "Building")

3. **Check error message:**
   - Open "My Reports" screen
   - If there's an error, it will show the error message
   - Click "Retry" button after creating index

4. **Verify user ID:**
   ```dart
   print('Current User ID: ${FirebaseAuth.instance.currentUser?.uid}');
   ```

5. **Check Firestore rules:**
   ```javascript
   // Make sure users can read their own reports
   match /reports/{reportId} {
     allow read: if request.auth != null && 
                    resource.data.reporterId == request.auth.uid;
     allow create: if request.auth != null;
   }
   ```

---

## Testing

### **Test Flow:**
1. **Submit a report:**
   - Go to any user profile
   - Click "Report User"
   - Fill in reason and description
   - Submit

2. **View your reports:**
   - Go to Settings
   - Click "My Reports"
   - Should see your submitted report

3. **Check status updates:**
   - Reports update in real-time
   - When admin changes status, you'll see it immediately
   - No need to refresh!

---

## Summary

✅ **Updated:** `my_reports_screen.dart` to use StreamBuilder
✅ **Added:** Firestore index configuration
✅ **Added:** Better error handling and messages

**Next Steps:**
1. Create the Firestore index (Option 1 is easiest)
2. Wait for index to build (2-5 minutes)
3. Test "My Reports" screen
4. Reports should now appear!

---

**Need Help?** If reports still don't show after creating the index, check the troubleshooting section above.
