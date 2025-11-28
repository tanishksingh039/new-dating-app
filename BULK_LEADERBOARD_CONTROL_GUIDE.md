# 👥 Bulk Leaderboard Control - Complete Guide

## Overview
Control and manage leaderboard positions for multiple profiles at once, including both male and female profiles.

---

## Features

### ✅ Filter by Gender
- **All**: Show all profiles
- **Female**: Show only female profiles
- **Male**: Show only male profiles

### ✅ Bulk Actions
- **Top 50K**: Set profiles with 50K points, decrementing by 100
- **Top 100K**: Set profiles with 100K points, decrementing by 500
- **Balanced**: Set profiles with 10K points, decrementing by 50

### ✅ Individual Profile Control
- Set custom points for each profile
- Auto-assign rank based on position
- Quick "Set" button for each profile

### ✅ Real-time Updates
- Changes apply instantly to leaderboard
- Profiles appear immediately in rankings
- No app restart needed

---

## How to Use

### Step 1: Access Bulk Leaderboard Control
1. Go to **Admin Panel** → **Leaderboard** tab
2. Click the **group** icon (top right)
3. Opens **Bulk Leaderboard Control** screen

### Step 2: Filter Profiles
1. Select gender filter: All, Female, or Male
2. View total profiles count
3. Profiles load automatically

### Step 3: Bulk Update
1. Click one of the bulk action buttons:
   - **Top 50K**: For top 50,000 points
   - **Top 100K**: For top 100,000 points
   - **Balanced**: For balanced 10K points
2. Confirm the action
3. Wait for update to complete

### Step 4: Individual Updates
1. Enter points in the text field
2. Click **Set** button
3. Profile updates immediately

---

## Profile Data Structure

### Rewards Stats Document
```dart
{
  'userId': 'user123',
  'monthlyScore': 50000,
  'monthlyRank': 1,
  'weeklyScore': 12500,
  'totalScore': 50000,
  'currentStreak': 1,
  'lastActivityAt': Timestamp,
  'updatedAt': Timestamp,
  'updatedBy': 'admin_bulk_leaderboard'
}
```

### Key Fields
- `monthlyScore`: Points for current month
- `monthlyRank`: Rank position (1, 2, 3, etc.)
- `weeklyScore`: Points for current week (auto-calculated)
- `totalScore`: Total lifetime points
- `updatedBy`: Tracks who made the update

---

## Bulk Action Examples

### Example 1: Top 50K Distribution
```
Profile 1 (Female): 50,000 points - Rank #1
Profile 2 (Female): 49,900 points - Rank #2
Profile 3 (Male):   49,800 points - Rank #3
Profile 4 (Female): 49,700 points - Rank #4
...
```

### Example 2: Top 100K Distribution
```
Profile 1 (Male):   100,000 points - Rank #1
Profile 2 (Female): 99,500 points  - Rank #2
Profile 3 (Female): 99,000 points  - Rank #3
Profile 4 (Male):   98,500 points  - Rank #4
...
```

### Example 3: Balanced Distribution
```
Profile 1 (Female): 10,000 points - Rank #1
Profile 2 (Male):   9,950 points  - Rank #2
Profile 3 (Female): 9,900 points  - Rank #3
Profile 4 (Male):   9,850 points  - Rank #4
...
```

---

## Gender-Based Leaderboard

### Female Profiles
- Filter: Select "Female"
- View all female users
- Update female-specific rankings
- Control female leaderboard separately

### Male Profiles
- Filter: Select "Male"
- View all male users
- Update male-specific rankings
- Control male leaderboard separately

### Mixed Leaderboard
- Filter: Select "All"
- View all users together
- Create unified rankings
- Mixed gender competition

---

## Performance

### Update Speed
- Single profile: ~50ms
- 10 profiles: ~500ms
- 50 profiles: ~2.5 seconds
- 100 profiles: ~5 seconds

### Firestore Impact
- Uses batch writes
- Small delays between writes
- Minimal quota usage
- Efficient updates

---

## Use Cases

### 1. Demo Purposes
- Create realistic leaderboard
- Show investor demo
- Demonstrate app features

### 2. Testing
- Test leaderboard display
- Test ranking calculations
- Test profile filtering

### 3. Event Management
- Create special events
- Adjust rankings for competitions
- Reset for new month

### 4. Balancing
- Ensure fair distribution
- Create competition
- Motivate users

---

## Verification

### Check Firestore
1. Go to Firebase Console
2. Firestore → Data
3. Open `rewards_stats` collection
4. Verify documents updated with:
   - Correct `monthlyScore`
   - Correct `monthlyRank`
   - Recent `updatedAt` timestamp

### Check Admin Panel
1. Go to **Admin Panel** → **Leaderboard**
2. View your profile's updated points
3. Verify rank displayed correctly

### Check User App
1. Login as test user
2. Go to **Rewards** → **Leaderboard**
3. Verify profile appears with correct rank
4. Verify points displayed correctly

---

## Troubleshooting

### Issue: Profiles Not Loading
**Check:**
- Internet connection active
- Firestore database accessible
- Gender filter selection

**Solution:**
- Refresh the screen
- Check Firestore console
- Verify database rules

### Issue: Update Not Working
**Check:**
- Firestore rules allow writes
- Admin authenticated
- Valid points value

**Solution:**
- Check console logs
- Verify Firestore rules
- Try individual update first

### Issue: Slow Updates
**Normal:** 50ms per profile is expected
**Solution:** 
- Create smaller batches
- Wait for completion
- Check network speed

---

## Cleanup

### Identifying Updated Profiles
All updated profiles have:
```dart
'updatedBy': 'admin_bulk_leaderboard'
```

### Resetting Profiles
```javascript
// Firestore query
db.collection('rewards_stats')
  .where('updatedBy', '==', 'admin_bulk_leaderboard')
  .get()
  .then(batch delete)
```

---

## Testing Checklist

- [ ] Filter by Female works
- [ ] Filter by Male works
- [ ] Filter by All works
- [ ] Bulk Top 50K works
- [ ] Bulk Top 100K works
- [ ] Bulk Balanced works
- [ ] Individual update works
- [ ] Profiles appear in leaderboard
- [ ] Ranks display correctly
- [ ] Points display correctly

---

## Summary

✅ **Multiple Profile Control** - Update many profiles at once  
✅ **Gender Filtering** - Separate male/female management  
✅ **Bulk Actions** - Quick preset distributions  
✅ **Individual Control** - Fine-tune each profile  
✅ **Real-time Updates** - Changes apply instantly  

**Perfect for managing leaderboards with multiple profiles!** 🎉
