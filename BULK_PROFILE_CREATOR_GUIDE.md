# 👥 Bulk Profile Creator - Complete Guide

## Overview
Create multiple user profiles at once for testing and demo purposes.

---

## Features

### ✅ Bulk Profile Creation
- Create 1-100 profiles at once
- Random names from Indian database
- Random ages (18-32 years)
- Random phone numbers
- Random interests (3-5 per profile)
- Random bio descriptions

### ✅ Gender Options
- **Mixed**: Random mix of male and female profiles
- **Female Only**: All female profiles
- **Male Only**: All male profiles

### ✅ Profile Data
Each profile includes:
- Unique user ID
- Name (Indian names)
- Phone number
- Gender
- Date of birth (age 18-32)
- Bio
- Interests (3-5 random)
- Marked as test profile
- Created timestamp

---

## How to Use

### Step 1: Access Bulk Creator
1. Go to **Admin Panel** → **My Profile**
2. Click the **group_add** icon in the top right
3. Opens **Bulk Profile Creator** screen

### Step 2: Configure Settings
1. **Number of Profiles**: Enter 1-100
2. **Gender Distribution**: Choose Mixed, Female, or Male
3. Review the features list

### Step 3: Create Profiles
1. Click **"Create Profiles"** button
2. Watch progress bar
3. Wait for completion
4. See success message

---

## Example Profiles Created

### Female Profile Example
```
Name: Priya 4523
Gender: Female
Age: 24
Phone: 987654321
Bio: Love to travel and explore new places 🌍
Interests: Travel, Music, Photography, Fitness, Art
```

### Male Profile Example
```
Name: Rahul 7891
Gender: Male
Age: 26
Phone: 876543210
Bio: Foodie | Music Lover | Adventure Seeker
Interests: Sports, Gaming, Movies, Cooking
```

---

## Profile Fields

### Generated Fields
```dart
{
  'uid': 'test_1234567890_5678',
  'name': 'Priya 4523',
  'phoneNumber': '987654321',
  'gender': 'Female',
  'dateOfBirth': Timestamp,
  'bio': 'Love to travel...',
  'interests': ['Travel', 'Music', 'Photography'],
  'photos': [],
  'createdAt': Timestamp,
  'lastActive': Timestamp,
  'isOnline': false,
  'isPremium': false,
  'isVerified': false,
  'accountStatus': 'active',
  'createdBy': 'admin_bulk_creator',
  'isTestProfile': true
}
```

### Key Markers
- `createdBy`: 'admin_bulk_creator'
- `isTestProfile`: true
- Empty `photos` array

---

## Name Database

### Male Names (20)
Rahul, Arjun, Rohan, Aarav, Vihaan, Aditya, Aryan, Sai, Shaurya, Reyansh, Ayaan, Arnav, Vivaan, Aayan, Krishna, Ishaan, Shiv, Atharv, Advait, Pranav

### Female Names (20)
Priya, Ananya, Aadhya, Saanvi, Kiara, Diya, Pari, Navya, Anika, Sara, Myra, Aaradhya, Avni, Riya, Ishita, Anvi, Kavya, Zara, Shanaya, Tara

### Interests (12)
Travel, Music, Movies, Sports, Reading, Cooking, Photography, Art, Dancing, Fitness, Gaming, Fashion

### Bios (10)
- Love to travel and explore new places 🌍
- Foodie | Music Lover | Adventure Seeker
- Living life one day at a time ✨
- Passionate about fitness and wellness 💪
- Coffee addict ☕ | Book lover 📚
- Making memories around the world 🌏
- Dance like nobody's watching 💃
- Fitness enthusiast | Healthy lifestyle
- Art lover | Creative soul 🎨
- Music is my therapy 🎵

---

## Progress Tracking

### Real-time Updates
```
Creating Profiles...
[Progress Bar]
15 / 50 profiles created
```

### Success Message
```
Successfully created 50 profiles!
```

---

## Use Cases

### 1. Testing Discovery Feature
- Create 50 mixed profiles
- Test swiping functionality
- Test matching algorithm

### 2. Demo Purposes
- Create 20 female profiles
- Show app to investors
- Demonstrate features

### 3. Load Testing
- Create 100 profiles
- Test app performance
- Test database queries

### 4. UI Testing
- Create profiles with various data
- Test profile display
- Test search and filters

---

## Performance

### Creation Speed
- ~100ms per profile
- 10 profiles = ~1 second
- 50 profiles = ~5 seconds
- 100 profiles = ~10 seconds

### Firestore Impact
- Uses batch writes where possible
- Small delays between writes
- Minimal impact on quota

---

## Cleanup

### Identifying Test Profiles
All test profiles have:
```dart
'isTestProfile': true
'createdBy': 'admin_bulk_creator'
```

### Deleting Test Profiles
```dart
// Firestore query
db.collection('users')
  .where('isTestProfile', '==', true)
  .get()
  .then(batch delete)
```

---

## Limitations

### Current Limitations
- No photos (empty array)
- No email addresses
- No location data
- No premium status
- No verification

### Maximum Limits
- 100 profiles per batch
- Prevents overwhelming Firestore
- Can run multiple times

---

## Future Enhancements

### Planned Features
- [ ] Add profile photos
- [ ] Add location data
- [ ] Add email addresses
- [ ] Custom name lists
- [ ] Custom bio templates
- [ ] Age range selection
- [ ] Premium profile option
- [ ] Verified profile option

---

## Troubleshooting

### Issue: Profiles Not Creating
**Check:**
- Firestore rules allow writes
- Internet connection active
- Admin authenticated

### Issue: Slow Creation
**Normal:** 100ms per profile is expected
**Solution:** Create smaller batches

### Issue: Duplicate Names
**Normal:** Names have random numbers
**Example:** Priya 4523, Priya 7891

---

## Testing Checklist

- [ ] Create 10 mixed profiles
- [ ] Create 20 female profiles
- [ ] Create 20 male profiles
- [ ] Verify profiles in Firestore
- [ ] Check profiles appear in Users tab
- [ ] Test discovery with new profiles
- [ ] Verify test profile markers

---

## Summary

✅ **Quick Profile Creation** - 1-100 profiles in seconds  
✅ **Realistic Data** - Indian names, ages, interests  
✅ **Flexible Options** - Mixed, Female, or Male  
✅ **Test Markers** - Easy to identify and cleanup  
✅ **Progress Tracking** - Real-time creation updates  

**Perfect for testing, demos, and development!** 🎉
