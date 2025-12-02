# Premium 30-Day Expiry Implementation Guide

## ✅ What Was Implemented

Your CampusBound app now has a complete **30-day premium expiry system** with testing support.

### Key Features:
- ✅ Premium automatically expires after 30 days of purchase
- ✅ Users can repurchase and get another 30 days
- ✅ Real-time expiry checking with auto-expiration
- ✅ Remaining days counter available in UI
- ✅ **TEST MODE**: 30 seconds expiry for quick testing
- ✅ **PRODUCTION MODE**: 30 days expiry for real users

---

## 📍 Where Changes Were Made

### 1. **UserModel** (`lib/models/user_model.dart`)
**Lines: 21, 50, 98, 141, 173, 198**

Added new field:
```dart
final DateTime? premiumExpiryDate; // When premium expires
```

This field is now:
- Serialized to Firestore as a Timestamp
- Deserialized from Firestore
- Included in `copyWith()` method

---

### 2. **PaymentService** (`lib/services/payment_service.dart`)
**Lines: 21-24 (TEST/PROD TOGGLE) | Lines: 170-182 (Expiry Calculation) | Lines: 184-190 (Firestore Update) | Lines: 201 (Payment Log)**

#### TEST/PROD Toggle (Line 24):
```dart
// ⚠️ IMPORTANT: TEST/PROD TOGGLE FOR PREMIUM EXPIRY
// Set to true for TESTING (30 seconds expiry)
// Set to false for PRODUCTION (30 days expiry)
static const bool USE_TEST_EXPIRY = true; // 🔴 CHANGE THIS TO FALSE FOR PRODUCTION
```

**To switch from TEST to PRODUCTION:**
1. Open `lib/services/payment_service.dart`
2. Go to **line 24**
3. Change `true` to `false`
4. Save the file

#### Expiry Date Calculation (Lines 170-182):
```dart
// Calculate premium expiry date
final now = DateTime.now();
final premiumExpiryDate = USE_TEST_EXPIRY
    ? now.add(const Duration(seconds: 30)) // TEST: 30 seconds
    : now.add(const Duration(days: 30));   // PRODUCTION: 30 days
```

#### Firestore Update (Lines 184-190):
```dart
await _firestore.collection('users').doc(user.uid).update({
  'isPremium': true,
  'premiumActivatedAt': FieldValue.serverTimestamp(),
  'premiumExpiryDate': Timestamp.fromDate(premiumExpiryDate), // ← NEW
  'lastPaymentId': paymentId,
});
```

---

### 3. **PremiumProvider** (`lib/providers/premium_provider.dart`)
**Lines: 14, 19-33 (New Getters) | Lines: 60, 65-76 (Expiry Check) | Lines: 93-103 (Auto-Expire) | Lines: 135-150 (Refresh Logic)**

#### New Properties (Lines 14, 19-33):
```dart
DateTime? _premiumExpiryDate;

// Getters for UI
DateTime? get premiumExpiryDate => _premiumExpiryDate;

int? get remainingDays {
  if (!_isPremium || _premiumExpiryDate == null) return null;
  final now = DateTime.now();
  if (now.isAfter(_premiumExpiryDate!)) return 0;
  return _premiumExpiryDate!.difference(now).inDays;
}

bool get isPremiumExpired {
  if (!_isPremium || _premiumExpiryDate == null) return false;
  return DateTime.now().isAfter(_premiumExpiryDate!);
}
```

#### Expiry Check Logic (Lines 65-76):
When Firestore updates are received, the provider checks if premium has expired:
```dart
bool shouldExpirePremium = false;
if (newPremiumStatus && newExpiryDate != null) {
  final now = DateTime.now();
  if (now.isAfter(newExpiryDate)) {
    shouldExpirePremium = true; // Mark for auto-expiry
  }
}
```

#### Auto-Expiry (Lines 95-103):
If premium has expired, it's automatically set to `false` in Firestore:
```dart
if (shouldExpirePremium) {
  _firestore.collection('users').doc(user.uid).update({
    'isPremium': false,
  });
}
```

---

## 🧪 Testing Without Waiting 30 Days

### **Option 1: Use TEST MODE (Recommended)**

1. **Verify TEST mode is enabled:**
   - Open `lib/services/payment_service.dart`
   - Line 24 should show: `static const bool USE_TEST_EXPIRY = true;`

2. **Make a test purchase:**
   - Go to Premium Subscription screen
   - Complete a test payment (use Razorpay test card)
   - Premium will be set to expire in **30 seconds**

3. **Watch it expire:**
   - Open the app console to see debug logs
   - Wait 30 seconds
   - Refresh the app or wait for real-time listener to trigger
   - Premium badge should disappear
   - Debug logs will show: `⏰ Premium has expired!`

### **Option 2: Manually Edit Firestore (For Immediate Testing)**

1. **Go to Firebase Console:**
   - Open your Firebase project
   - Go to Firestore Database
   - Navigate to `users` collection

2. **Find your test user:**
   - Click on your user document
   - Look for `premiumExpiryDate` field

3. **Set expiry to past date:**
   - Edit `premiumExpiryDate`
   - Set it to any time in the past (e.g., yesterday)
   - Save

4. **Reload the app:**
   - Close and reopen the app
   - Premium should be automatically expired
   - `isPremium` field should change to `false`

### **Option 3: Create Multiple Test Users**

1. **Create 3 test accounts:**
   - User A: Premium expires today
   - User B: Premium expires in 5 days
   - User C: Premium expires in 25 days

2. **Manually set their expiry dates in Firestore**

3. **Test each user's behavior:**
   - Check if remaining days counter works
   - Check if UI updates correctly
   - Check if expired users lose premium features

---

## 📊 Available Getters in PremiumProvider

You can use these in your UI:

```dart
// Check if user is premium
bool isPremium = Provider.of<PremiumProvider>(context).isPremium;

// Get remaining days (null if not premium)
int? remainingDays = Provider.of<PremiumProvider>(context).remainingDays;

// Check if premium has expired
bool isExpired = Provider.of<PremiumProvider>(context).isPremiumExpired;

// Get expiry date
DateTime? expiryDate = Provider.of<PremiumProvider>(context).premiumExpiryDate;
```

---

## 🎯 How to Display Remaining Days in UI

Example in a widget:

```dart
Consumer<PremiumProvider>(
  builder: (context, premiumProvider, _) {
    if (!premiumProvider.isPremium) {
      return Text('Not Premium');
    }
    
    final remainingDays = premiumProvider.remainingDays;
    if (remainingDays == null) {
      return Text('Premium (No expiry)');
    }
    
    if (remainingDays == 0) {
      return Text('Premium Expired');
    }
    
    return Text('Premium - $remainingDays days remaining');
  },
)
```

---

## 🔄 Repurchase Flow

When a user repurchases premium:

1. User clicks "Buy Premium" again
2. Payment is processed
3. `handlePaymentSuccess()` is called
4. New `premiumExpiryDate` is calculated (30 days from now)
5. Firestore is updated with new expiry date
6. `PremiumProvider` detects the change
7. UI updates automatically
8. User gets another 30 days

**No special code needed** - the system handles it automatically!

---

## 🚀 Switching to Production

When you're ready to go live:

1. **Open** `lib/services/payment_service.dart`
2. **Go to line 24**
3. **Change:**
   ```dart
   static const bool USE_TEST_EXPIRY = true;
   ```
   **To:**
   ```dart
   static const bool USE_TEST_EXPIRY = false;
   ```
4. **Save the file**
5. **Rebuild and deploy**

Now premium will expire after **30 days** instead of 30 seconds.

---

## 📝 Debug Logs

When testing, watch the console for these logs:

```
[PremiumProvider] 📊 Premium status update received
[PremiumProvider] ⏳ Premium active - 25 days remaining
[PremiumProvider] 🎉 Premium status changed!
[PremiumProvider] Expires at: 2025-01-01 10:30:00.000
```

Or when expired:

```
[PremiumProvider] ⏰ Premium has expired! Expiry was: 2024-12-01 10:30:00.000
[PremiumProvider] 🔄 Auto-expiring premium in Firestore...
```

---

## ✅ Verification Checklist

- [ ] Premium expiry date is saved to Firestore after purchase
- [ ] Premium expires after 30 days (or 30 seconds in test mode)
- [ ] Expired premium is automatically set to `false`
- [ ] User can repurchase and get another 30 days
- [ ] Remaining days counter works correctly
- [ ] Debug logs show expiry information
- [ ] UI updates when premium expires
- [ ] TEST mode works (30 seconds)
- [ ] PRODUCTION mode ready (30 days)

---

## 🆘 Troubleshooting

### Premium not expiring?
- Check if `USE_TEST_EXPIRY` is `true` (for testing)
- Check Firestore for `premiumExpiryDate` field
- Check console logs for errors
- Restart the app

### Remaining days showing wrong number?
- Check system time on device
- Verify `premiumExpiryDate` in Firestore
- Check `remainingDays` getter logic

### Premium not auto-expiring?
- Check if `PremiumProvider` is listening to Firestore
- Check if `premiumExpiryDate` is being saved
- Check console for listener errors

---

## 📚 Related Files

- `lib/models/user_model.dart` - User data model
- `lib/services/payment_service.dart` - Payment handling
- `lib/providers/premium_provider.dart` - Premium state management
- `lib/screens/premium/premium_subscription_screen.dart` - Premium purchase UI
- `lib/widgets/premium_lock_overlay.dart` - Premium feature locks

---

## 🎉 You're All Set!

Your premium expiry system is now fully implemented and ready to test. Start with TEST mode (30 seconds) to verify everything works, then switch to PRODUCTION mode (30 days) when ready to deploy.
