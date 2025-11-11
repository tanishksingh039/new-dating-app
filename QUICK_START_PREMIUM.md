# Quick Start - Premium & Swipe Limits 🚀

## What Changed

### 1. **Premium Dialog** ✅
**Before**: "Boost is a premium feature"  
**After**: "Do you want to avail Premium?"

### 2. **Premium Plans** ✅
**Before**: 3 plans (₹499, ₹1,199, ₹1,999)  
**After**: **Single plan - ₹99/month**

### 3. **Swipe Limits** ✅
- **Non-Premium**: 8 free → ₹20 for 6 more
- **Premium**: 20 free → ₹20 for 10 more

### 4. **Verification** ✅
- **Non-Premium**: Popup after right swipe
- **Premium**: No popup

---

## Run It

```bash
# 1. Clean
flutter clean

# 2. Get packages
flutter pub get

# 3. Run
flutter run
```

---

## Test It

### Test 1: Premium Dialog
1. Click lightning button (boost)
2. See: "Do you want to avail Premium?"
3. Click "Upgrade Now"
4. See: Single plan ₹99/month

### Test 2: Swipe Limits (Non-Premium)
1. Swipe 8 times
2. 9th swipe → Purchase dialog
3. See: "Buy 6 swipes for ₹20"

### Test 3: Verification (Non-Premium)
1. Swipe right (like)
2. See verification dialog
3. Premium users: No dialog

---

## Features

### Premium (₹99/month)
```
✅ 20 free swipes daily
✅ Unlimited likes
✅ See who liked you
✅ Advanced filters
✅ No verification required
✅ Better swipe deals (10 vs 6)
✅ Priority support
✅ Ad-free
```

### Non-Premium (Free)
```
✅ 8 free swipes daily
✅ Can purchase more (₹20 for 6)
✅ Basic features
⚠️ Verification required after likes
```

---

## UI Changes

### AppBar
- **New**: Swipe counter indicator
- **Shows**: Remaining swipes
- **Color**: Green → Yellow → Orange → Red

### Dialogs
1. **Premium Dialog**: "Avail Premium?"
2. **Purchase Dialog**: Buy swipes
3. **Verification Dialog**: For non-premium

---

## Quick Reference

| Feature | Non-Premium | Premium |
|---------|-------------|---------|
| Free Swipes | 8/day | 20/day |
| Swipe Package | 6 for ₹20 | 10 for ₹20 |
| Verification | Required | Not Required |
| Price | Free | ₹99/month |

---

**Status**: ✅ Ready!  
**Next**: Test the flows above
