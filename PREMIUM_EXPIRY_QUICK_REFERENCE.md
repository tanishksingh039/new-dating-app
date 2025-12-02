# Premium Expiry - Quick Reference Card

## 🎯 Where to Make Changes

### To Switch Between TEST and PRODUCTION:

**File:** `lib/services/payment_service.dart`  
**Line:** 24

```dart
// TEST MODE (30 seconds expiry)
static const bool USE_TEST_EXPIRY = true;

// PRODUCTION MODE (30 days expiry)
static const bool USE_TEST_EXPIRY = false;
```

---

## 📍 All Modified Files

| File | Lines | What Changed |
|------|-------|--------------|
| `lib/models/user_model.dart` | 21, 50, 98, 141, 173, 198 | Added `premiumExpiryDate` field |
| `lib/services/payment_service.dart` | 21-24, 170-182, 184-190, 201 | Added expiry calculation & storage |
| `lib/providers/premium_provider.dart` | 14, 19-33, 60, 65-76, 93-103, 135-150 | Added expiry checking & auto-expiry |

---

## 🧪 Quick Test Steps

1. **Enable TEST mode** (line 24 in `payment_service.dart` = `true`)
2. **Make a test purchase** on Premium screen
3. **Wait 30 seconds**
4. **Refresh app** or wait for real-time update
5. **Premium should expire** automatically

---

## 📊 New Getters Available

```dart
// In any widget with Consumer<PremiumProvider>:

premiumProvider.isPremium              // bool - is user premium?
premiumProvider.remainingDays          // int? - days left (null if not premium)
premiumProvider.isPremiumExpired       // bool - has it expired?
premiumProvider.premiumExpiryDate      // DateTime? - when does it expire?
```

---

## 🔄 How Expiry Works

```
User Purchases Premium
    ↓
premiumExpiryDate = now + 30 days (or 30 seconds in test mode)
    ↓
Saved to Firestore
    ↓
PremiumProvider listens for changes
    ↓
When expiry date passes:
  - PremiumProvider detects it
  - Sets isPremium = false
  - Auto-updates Firestore
  - UI updates automatically
```

---

## 🚀 Production Checklist

- [ ] Change `USE_TEST_EXPIRY = false` in `payment_service.dart` line 24
- [ ] Test with real payment (or test card)
- [ ] Verify `premiumExpiryDate` is saved to Firestore
- [ ] Wait 30 days OR manually test with Firestore edit
- [ ] Deploy to production

---

## 🆘 Debug Commands

Check console logs for:
```
[PremiumProvider] ⏳ Premium active - X days remaining
[PremiumProvider] ⏰ Premium has expired!
[PremiumProvider] 🔄 Auto-expiring premium in Firestore...
```

---

## 📝 Manual Testing via Firestore

1. Go to Firebase Console → Firestore
2. Find your user in `users` collection
3. Edit `premiumExpiryDate` to a past date
4. Reload app
5. Premium should auto-expire

---

## ✅ What's Automatic

- ✅ Expiry date calculation
- ✅ Firestore storage
- ✅ Real-time expiry checking
- ✅ Auto-expiration when date passes
- ✅ UI updates on expiry
- ✅ Repurchase resets the 30-day timer

---

## ⚠️ Important Notes

- Premium expires **after 30 days** (not on day 30)
- Repurchasing **resets the timer** to 30 days from now
- Expiry is **automatic** - no manual action needed
- System uses **device time** - ensure device time is correct
- Firestore **auto-updates** when expiry is detected

---

**Need more details?** See `PREMIUM_EXPIRY_GUIDE.md`
