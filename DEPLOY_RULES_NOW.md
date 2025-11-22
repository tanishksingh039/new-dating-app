# 🚀 DEPLOY FIRESTORE RULES - QUICK GUIDE

## ⚠️ IMPORTANT: Deploy These Rules Immediately

The account deletion feature will NOT work until you deploy these updated Firestore rules.

## 🎯 Quick Deploy (Recommended)

### Windows Users:
```bash
# Double-click this file or run in terminal:
deploy_firestore_rules.bat
```

### Mac/Linux Users:
```bash
cd /path/to/CampusBound/frontend
firebase deploy --only firestore:rules
```

## 📋 What Changed?

The updated rules now allow users to delete their own data from all collections during account deletion:
- ✅ User profiles and subcollections
- ✅ Swipes, matches, and messages
- ✅ Reports and blocks
- ✅ Payment and subscription data
- ✅ Verification requests
- ✅ Rewards and stats

## ✅ Verify Deployment

After deploying, check:
1. Firebase Console → Firestore Database → Rules
2. Look for "Last deployed" timestamp
3. Test account deletion in the app

## 🔧 Troubleshooting

### Error: "Firebase CLI not found"
```bash
npm install -g firebase-tools
firebase login
```

### Error: "No project selected"
```bash
firebase use --add
# Select your project from the list
```

### Error: "Permission denied"
- Make sure you're logged in: `firebase login`
- Verify you have owner/editor access to the Firebase project

## 📞 Need Help?

If deployment fails:
1. Check your internet connection
2. Verify Firebase CLI is installed: `firebase --version`
3. Ensure you're in the correct directory: `cd c:\CampusBound\frontend`
4. Try manual deployment via Firebase Console (see main documentation)

---

**Status**: ⏳ Rules updated locally, waiting for deployment
**Action Required**: Deploy now to enable account deletion feature
