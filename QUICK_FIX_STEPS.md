# ⚡ QUICK FIX - 5 Steps (2 Minutes)

## Your User ID: `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`

---

## Step 1: Open Firebase Console

🔗 Go to: https://console.firebase.google.com/

Select your **CampusBound** project

---

## Step 2: Navigate to Firestore

Click: **Firestore Database** (left sidebar)

---

## Step 3: Find Your Document

1. Click on `users` collection
2. Find document: `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`
3. Click on it

---

## Step 4: Update These 4 Fields

### Field 1: `isOnboardingComplete`
```
Current: false (or missing)
Change to: true (boolean)
```

### Field 2: `onboardingCompleted`
```
Current: false (or missing)
Change to: true (boolean)
```

### Field 3: `onboardingStep`
```
Current: (anything else)
Change to: completed (string)
```

### Field 4: `profileComplete`
```
Current: (less than 100)
Change to: 100 (number)
```

**How to edit:**
- Click the pencil icon ✏️ next to each field
- Change the value
- Make sure the type is correct (boolean/string/number)

---

## Step 5: Test

1. **Close your app completely**
2. **Reopen the app**
3. **Login with the same account**
4. **You should see Home Screen** ✅

---

## ✅ Expected Result

After the fix, your document should look like this:

```
users/S6Bh0LbnLLPL60f1VkBcf8N1Wfm2
{
  "uid": "S6Bh0LbnLLPL60f1VkBcf8N1Wfm2",
  "email": "your@email.com",
  "name": "Your Name",
  "gender": "male",
  "dateOfBirth": [timestamp],
  "photos": ["url1", "url2"],
  "interests": ["interest1", "interest2"],
  "bio": "Your bio",
  
  // ✅ THESE SHOULD ALL BE SET:
  "isOnboardingComplete": true,
  "onboardingCompleted": true,
  "onboardingStep": "completed",
  "profileComplete": 100,
  
  "createdAt": [timestamp],
  "lastActive": [timestamp]
}
```

---

## 🚨 Troubleshooting

### Issue: Fields don't exist

**Solution:** Click **"Add field"** button and create them:
- Field name: `isOnboardingComplete`
- Type: `boolean`
- Value: `true`

Repeat for all 4 fields.

### Issue: Can't find the document

**Solution:** 
1. Make sure you're in the `users` collection
2. Use the search box to search for: `S6Bh0LbnLLPL60f1VkBcf8N1Wfm2`
3. If not found, the document might not exist (onboarding didn't save at all)

### Issue: Still showing onboarding after fix

**Solution:**
1. Check console logs - verify the User ID matches
2. Clear app data (Settings → Apps → CampusBound → Clear Data)
3. Make sure you saved the changes in Firebase Console

---

## 📱 Alternative: Use Firebase Console Mobile App

If you're on mobile:
1. Download **Firebase Console** app
2. Login to your Firebase account
3. Select CampusBound project
4. Go to Firestore
5. Edit the document

---

## 💻 Alternative: Use the Script

If you prefer automation:

```bash
cd c:\CampusBound\frontend
npm install firebase-admin
# Download serviceAccountKey.json from Firebase Console
node fix_onboarding_status.js
```

---

## ✅ Done!

Once you update those 4 fields, your onboarding issue is **fixed**! 🎉

The app will now recognize you as an existing user and skip onboarding.
