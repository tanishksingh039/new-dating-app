# Swipe Limit System 🎯

## Overview

A monetization feature that limits daily swipes and allows users to purchase additional swipes.

---

## Swipe Limits

### Non-Premium Users
- **Free swipes**: 8 per day
- **Purchase option**: ₹20 for 6 additional swipes

### Premium Users
- **Free swipes**: 20 per day
- **Purchase option**: ₹20 for 10 additional swipes (4 extra bonus!)

---

## Features

### ✅ Daily Reset
- Free swipes reset every day at midnight
- Purchased swipes carry over (don't expire)

### ✅ Smart Usage
- Uses free swipes first
- Then uses purchased swipes
- Clear indicator of remaining swipes

### ✅ Real-time Updates
- Live swipe count display
- Instant updates after purchase
- Visual indicators for low swipes

### ✅ Payment Integration
- Razorpay integration for purchases
- Secure payment processing
- Instant swipe credit after payment

---

## File Structure

```
lib/
├── config/
│   └── swipe_config.dart              # Configuration constants
├── models/
│   └── swipe_stats.dart               # Swipe statistics model
├── services/
│   └── swipe_limit_service.dart       # Core swipe limit logic
└── widgets/
    ├── swipe_limit_indicator.dart     # Swipe count display
    └── purchase_swipes_dialog.dart    # Purchase UI
```

---

## Implementation

### 1. Configuration (`swipe_config.dart`)

```dart
class SwipeConfig {
  static const int freeSwipesNonPremium = 8;
  static const int freeSwipesPremium = 20;
  static const int additionalSwipesNonPremium = 6;
  static const int additionalSwipesPremium = 10;
  static const int additionalSwipesPriceInPaise = 2000; // ₹20
}
```

### 2. Swipe Stats Model (`swipe_stats.dart`)

Tracks:
- Total swipes used
- Free swipes used today
- Purchased swipes remaining
- Last reset date

### 3. Service (`swipe_limit_service.dart`)

**Key Methods**:
- `getSwipeStats()` - Get current stats
- `canSwipe()` - Check if swipe available
- `useSwipe()` - Consume a swipe
- `purchaseSwipes()` - Buy more swipes
- `getSwipeSummary()` - Get detailed summary

### 4. UI Components

**SwipeLimitIndicator**:
- Shows remaining swipes
- Color-coded (green → yellow → orange → red)
- Displays purchased swipes separately

**PurchaseSwipesDialog**:
- Beautiful purchase UI
- Shows package details
- Premium bonus highlight
- Razorpay payment integration

---

## Integration Guide

### Step 1: Add to Discovery Screen

```dart
import 'package:campusbound/widgets/swipe_limit_indicator.dart';
import 'package:campusbound/widgets/purchase_swipes_dialog.dart';
import 'package:campusbound/services/swipe_limit_service.dart';

class SwipeableDiscoveryScreen extends StatefulWidget {
  // ... existing code
  
  final SwipeLimitService _swipeLimitService = SwipeLimitService();
}
```

### Step 2: Add Indicator to AppBar

```dart
AppBar(
  title: const Text('Discover'),
  actions: [
    SwipeLimitIndicator(), // Add this
    // ... other actions
  ],
)
```

### Step 3: Check Before Swipe

```dart
Future<void> _handleSwipe(String targetUserId, SwipeType type) async {
  // Check if user can swipe
  final canSwipe = await _swipeLimitService.canSwipe();
  
  if (!canSwipe) {
    // Show purchase dialog
    _showPurchaseDialog();
    return;
  }
  
  // Use a swipe
  final success = await _swipeLimitService.useSwipe();
  if (!success) {
    _showPurchaseDialog();
    return;
  }
  
  // Proceed with swipe logic
  // ... existing swipe code
}
```

### Step 4: Show Purchase Dialog

```dart
void _showPurchaseDialog() async {
  // Get user's premium status
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();
  final isPremium = userDoc.data()?['isPremium'] ?? false;
  
  if (!mounted) return;
  
  showDialog(
    context: context,
    builder: (context) => PurchaseSwipesDialog(isPremium: isPremium),
  );
}
```

---

## Firestore Structure

### Collection: `swipe_stats`

```javascript
swipe_stats/{userId} {
  totalSwipes: 45,                    // Total lifetime swipes
  freeSwipesUsed: 5,                  // Free swipes used today
  purchasedSwipesRemaining: 12,       // Purchased swipes left
  lastResetDate: Timestamp,           // Last daily reset
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## Firestore Rules

```javascript
match /swipe_stats/{userId} {
  allow read: if isOwner(userId);
  allow create: if isOwner(userId);
  allow update: if isOwner(userId);
  allow delete: if false;
}
```

---

## User Flow

### Scenario 1: Normal Swipe (Free Available)

```
User swipes
    ↓
Check canSwipe() → TRUE
    ↓
useSwipe() → Uses free swipe (5/8)
    ↓
Proceed with swipe
    ↓
Indicator updates: "3 swipes"
```

### Scenario 2: Out of Free Swipes (Has Purchased)

```
User swipes
    ↓
Check canSwipe() → TRUE
    ↓
useSwipe() → Uses purchased swipe (11 remaining)
    ↓
Proceed with swipe
    ↓
Indicator updates: "11 swipes" (orange)
```

### Scenario 3: No Swipes Left

```
User swipes
    ↓
Check canSwipe() → FALSE
    ↓
Show PurchaseSwipesDialog
    ↓
User clicks "Buy Now"
    ↓
Razorpay payment
    ↓
Payment success → Add swipes
    ↓
Indicator updates: "6 swipes" (green)
```

### Scenario 4: Daily Reset

```
New day starts (midnight)
    ↓
User opens app
    ↓
getSwipeStats() detects new day
    ↓
Auto-reset freeSwipesUsed = 0
    ↓
Indicator shows: "8 swipes" (or 20 for premium)
```

---

## Visual Indicators

### Color Coding

| Swipes Remaining | Color | Meaning |
|-----------------|-------|---------|
| 4+ free swipes | 🟢 Green | Plenty available |
| 1-3 free swipes | 🟡 Yellow | Running low |
| 0 free, has purchased | 🟠 Orange | Using purchased |
| 0 total | 🔴 Red | Need to buy |

### Display Format

```
Normal: "8 swipes"
With purchased: "3 swipes +12"
No swipes: "No swipes left"
```

---

## Payment Flow

### Purchase Process

1. User clicks "Buy Now"
2. Service calls `purchaseSwipes()`
3. Razorpay payment initiated
4. User completes payment
5. `onSuccess` callback triggered
6. Service adds swipes to account
7. Firestore updated
8. UI refreshes automatically
9. Success dialog shown

### Error Handling

- Payment failure → Show error dialog
- Network error → Retry mechanism
- Invalid state → Graceful fallback

---

## Testing Checklist

### Basic Functionality
- [ ] Free swipes count correctly
- [ ] Daily reset works at midnight
- [ ] Purchased swipes don't expire
- [ ] Indicator updates in real-time

### Premium vs Non-Premium
- [ ] Non-premium: 8 free, buy 6 for ₹20
- [ ] Premium: 20 free, buy 10 for ₹20
- [ ] Premium badge shows in dialog

### Payment
- [ ] Razorpay opens correctly
- [ ] Payment success adds swipes
- [ ] Payment failure shows error
- [ ] Swipes credited immediately

### Edge Cases
- [ ] No swipes → Dialog shows
- [ ] Mid-swipe limit reached → Stops gracefully
- [ ] Multiple rapid swipes → Counts correctly
- [ ] Offline → Handles gracefully

---

## Deployment Steps

### 1. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### 2. Test Payment Integration

- Use Razorpay test mode
- Test card: 4111 1111 1111 1111
- Any future expiry, any CVV

### 3. Monitor Initial Users

- Check swipe_stats collection
- Verify daily resets
- Monitor payment success rate

### 4. Production Checklist

- [ ] Firestore rules deployed
- [ ] Razorpay in production mode
- [ ] Payment webhook configured (if needed)
- [ ] Analytics tracking added
- [ ] Error monitoring enabled

---

## Revenue Projections

### Assumptions
- 1000 active users
- 50% hit swipe limit
- 30% purchase additional swipes

### Monthly Revenue

**Non-Premium Users** (70%):
- 1000 × 0.7 = 700 non-premium users
- 700 × 0.5 = 350 hit limit
- 350 × 0.3 = 105 purchases
- 105 × ₹20 = **₹2,100/month**

**Premium Users** (30%):
- 1000 × 0.3 = 300 premium users
- 300 × 0.5 = 150 hit limit
- 150 × 0.3 = 45 purchases
- 45 × ₹20 = **₹900/month**

**Total**: ₹3,000/month from swipe purchases

---

## Analytics to Track

### Key Metrics
- Daily active swipers
- Average swipes per user
- % hitting swipe limit
- Purchase conversion rate
- Revenue per user

### Events to Log
- `swipe_limit_reached`
- `purchase_dialog_shown`
- `purchase_initiated`
- `purchase_completed`
- `purchase_failed`

---

## Future Enhancements

### Potential Features
1. **Swipe Bundles**: Larger packages at discount
2. **Weekly Pass**: Unlimited swipes for 7 days
3. **Referral Bonus**: Free swipes for referrals
4. **Streak Rewards**: Bonus swipes for daily usage
5. **Premium Upgrade**: Highlight premium benefits

### A/B Testing Ideas
- Different price points
- Different swipe counts
- Free swipe limits
- Dialog design variations

---

## Troubleshooting

### Issue: Swipes not updating
**Solution**: Check Firestore rules, verify user authentication

### Issue: Payment success but no swipes
**Solution**: Check `_addPurchasedSwipes()` method, verify Firestore write

### Issue: Daily reset not working
**Solution**: Check `needsDailyReset()` logic, verify timezone handling

### Issue: Indicator not showing
**Solution**: Verify StreamBuilder, check swipe_stats document exists

---

## Summary

### ✅ What's Included
- Complete swipe limit system
- Payment integration
- Beautiful UI components
- Real-time updates
- Daily reset mechanism
- Premium differentiation

### 📦 Ready to Deploy
- All code files created
- Firestore rules updated
- Documentation complete
- Integration guide provided

### 🚀 Next Steps
1. Integrate into discovery screen
2. Deploy Firestore rules
3. Test payment flow
4. Monitor user behavior
5. Iterate based on data

---

**Status**: ✅ Complete and ready for integration!
