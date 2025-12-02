# Premium Expiry - Exact Line Numbers Reference

## 📍 All Changes by File and Line Number

### 1️⃣ UserModel (`lib/models/user_model.dart`)

| Line(s) | Change | What |
|---------|--------|------|
| **21** | Added field | `final DateTime? premiumExpiryDate;` |
| **50** | Added parameter | `this.premiumExpiryDate,` in constructor |
| **98** | Updated toMap() | `'premiumExpiryDate': premiumExpiryDate != null ? Timestamp.fromDate(premiumExpiryDate!) : null,` |
| **141** | Updated fromMap() | `premiumExpiryDate: (map['premiumExpiryDate'] as Timestamp?)?.toDate(),` |
| **173** | Added copyWith parameter | `DateTime? premiumExpiryDate,` |
| **198** | Updated copyWith return | `premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,` |

**Total Changes:** 6 locations

---

### 2️⃣ PaymentService (`lib/services/payment_service.dart`)

| Line(s) | Change | What |
|---------|--------|------|
| **21-24** | Added toggle | `static const bool USE_TEST_EXPIRY = true;` |
| **170-175** | Expiry calculation | Calculate `premiumExpiryDate` based on `USE_TEST_EXPIRY` |
| **177-182** | Debug logs | Print expiry configuration to console |
| **188** | Firestore update | `'premiumExpiryDate': Timestamp.fromDate(premiumExpiryDate),` |
| **201** | Payment log | `'premiumExpiryDate': Timestamp.fromDate(premiumExpiryDate),` |

**Total Changes:** 5 locations

**🔴 IMPORTANT:** Line 24 is where you change TEST to PRODUCTION

---

### 3️⃣ PremiumProvider (`lib/providers/premium_provider.dart`)

| Line(s) | Change | What |
|---------|--------|------|
| **14** | Added property | `DateTime? _premiumExpiryDate;` |
| **19** | Added getter | `DateTime? get premiumExpiryDate => _premiumExpiryDate;` |
| **21-27** | Added getter | `int? get remainingDays { ... }` |
| **29-33** | Added getter | `bool get isPremiumExpired { ... }` |
| **60** | Listener update | `final newExpiryDate = (data?['premiumExpiryDate'] as Timestamp?)?.toDate();` |
| **65-76** | Expiry check | Check if premium has expired |
| **79-82** | Update condition | Added expiry date checks to condition |
| **91** | Update status | `_isPremium = shouldExpirePremium ? false : newPremiumStatus;` |
| **93** | Update expiry | `_premiumExpiryDate = newExpiryDate;` |
| **96-103** | Auto-expiry | Auto-expire in Firestore if needed |
| **114** | Reset on logout | `_premiumExpiryDate = null;` |
| **135** | Refresh method | `final newExpiryDate = (data?['premiumExpiryDate'] as Timestamp?)?.toDate();` |
| **138** | Refresh method | `_premiumExpiryDate = newExpiryDate;` |
| **141-150** | Refresh method | Check expiry during refresh |
| **153** | Debug log | Print expiry date in logs |

**Total Changes:** 14 locations

---

## 🎯 Quick Navigation

### To Switch TEST ↔ PRODUCTION

**Go to:** `lib/services/payment_service.dart`  
**Line:** 24  
**Change:**
```dart
// TEST MODE (30 seconds)
static const bool USE_TEST_EXPIRY = true;

// PRODUCTION MODE (30 days)
static const bool USE_TEST_EXPIRY = false;
```

---

### To See Expiry Calculation

**File:** `lib/services/payment_service.dart`  
**Lines:** 170-175

```dart
final now = DateTime.now();
final premiumExpiryDate = USE_TEST_EXPIRY
    ? now.add(const Duration(seconds: 30)) // TEST: 30 seconds
    : now.add(const Duration(days: 30));   // PRODUCTION: 30 days
```

---

### To See Expiry Check Logic

**File:** `lib/providers/premium_provider.dart`  
**Lines:** 65-76

```dart
bool shouldExpirePremium = false;
if (newPremiumStatus && newExpiryDate != null) {
  final now = DateTime.now();
  if (now.isAfter(newExpiryDate)) {
    shouldExpirePremium = true;
  }
}
```

---

### To See Auto-Expiry Logic

**File:** `lib/providers/premium_provider.dart`  
**Lines:** 96-103

```dart
if (shouldExpirePremium) {
  _firestore.collection('users').doc(user.uid).update({
    'isPremium': false,
  }).catchError((e) {
    debugPrint('[PremiumProvider] ❌ Error auto-expiring premium: $e');
  });
}
```

---

### To See Remaining Days Getter

**File:** `lib/providers/premium_provider.dart`  
**Lines:** 21-27

```dart
int? get remainingDays {
  if (!_isPremium || _premiumExpiryDate == null) return null;
  final now = DateTime.now();
  if (now.isAfter(_premiumExpiryDate!)) return 0;
  return _premiumExpiryDate!.difference(now).inDays;
}
```

---

## 📊 Summary Table

| File | Total Lines Changed | Key Lines |
|------|-------------------|-----------|
| `user_model.dart` | 6 | 21, 50, 98, 141, 173, 198 |
| `payment_service.dart` | 5 | **24**, 170-175, 188, 201 |
| `premium_provider.dart` | 14 | 14, 19, 21-27, 29-33, 60, 65-76, 91, 93, 96-103, 114, 135-153 |
| **TOTAL** | **25** | **See above** |

---

## 🔍 Finding Changes in Your IDE

### In VS Code / Android Studio

1. **Open file:** `lib/services/payment_service.dart`
2. **Press:** `Ctrl+G` (Go to Line)
3. **Type:** `24`
4. **Press:** Enter
5. **See:** `static const bool USE_TEST_EXPIRY = true;`

---

## ✅ Verification Checklist

- [ ] Line 24 in `payment_service.dart` has `USE_TEST_EXPIRY` toggle
- [ ] Line 21 in `user_model.dart` has `premiumExpiryDate` field
- [ ] Line 14 in `premium_provider.dart` has `_premiumExpiryDate` property
- [ ] Lines 21-27 in `premium_provider.dart` have `remainingDays` getter
- [ ] Lines 65-76 in `premium_provider.dart` have expiry check logic
- [ ] Lines 96-103 in `premium_provider.dart` have auto-expiry logic

---

## 🚀 Production Deployment Checklist

Before deploying to production:

- [ ] Change line 24: `USE_TEST_EXPIRY = false`
- [ ] Test with real payment
- [ ] Verify `premiumExpiryDate` saves to Firestore
- [ ] Wait 30 days OR manually test with Firestore edit
- [ ] Deploy to production

---

## 📝 Notes

- All line numbers are **1-indexed** (as shown in IDE)
- Line numbers may shift if you add/remove code elsewhere
- Use IDE's "Go to Line" feature (`Ctrl+G`) for quick navigation
- Search for `USE_TEST_EXPIRY` to find the toggle quickly
- Search for `premiumExpiryDate` to find all expiry-related code

---

**Need help?** Use these line numbers to quickly navigate to the code!
