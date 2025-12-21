# Google Play Products Configuration

## 📦 All Products

### 1. Premium Monthly Subscription
- **Product ID**: `premium_monthly`
- **Base Plan ID**: `monthly-basic`
- **Type**: Subscription
- **Price**: ₹99
- **Duration**: 30 days
- **Features**:
  - 50 weekly swipes (auto-reset)
  - Unlimited likes
  - See who liked you
  - Advanced filters
  - Better swipe packages (10 vs 6)
  - No verification prompts
  - Ad-free experience

### 2. Spotlight Booking
- **Product ID**: `spotlight_299`
- **Base Plan ID**: `spotlight-299`
- **Type**: Non-consumable / One-time purchase
- **Price**: ₹299
- **Features**:
  - Profile featured for 24 hours
  - Increased visibility
  - More matches

### 3. Swipe Pack
- **Product ID**: `swipe_20`
- **Base Plan ID**: `swipes-20`
- **Type**: Consumable
- **Price**: ₹20
- **Features**:
  - Non-premium: 6 swipes
  - Premium users: 10 swipes (bonus!)

---

## 🔧 Implementation Status

### ✅ Fully Implemented
1. **GooglePlayBillingService** - Supports all 3 products
2. **Premium Subscription** - Complete flow
3. **Spotlight Bookings** - Complete flow
4. **Swipe Packs** - Complete flow

### 📱 UI Integration
1. **PaymentScreen** - Premium subscription
2. **SpotlightBookingScreen** - Spotlight purchases
3. **PurchaseSwipesDialog** - Swipe pack purchases
4. **PremiumOptionsDialog** - Premium + Swipe packs

---

## 📋 Google Play Console Setup

### Step 1: Create Products

#### Premium Monthly
```
Product ID: premium_monthly
Product type: Subscription
Base plan ID: monthly-basic
Billing period: 1 month
Price: ₹99.00 INR
```

#### Spotlight Booking
```
Product ID: spotlight_299
Product type: Non-consumable (or One-time purchase)
Base plan ID: spotlight-299
Price: ₹299.00 INR
```

#### Swipe Pack
```
Product ID: swipe_20
Product type: Consumable
Base plan ID: swipes-20
Price: ₹20.00 INR
```

### Step 2: Activate Products
- Go to each product
- Review all details
- Click **Activate**

### Step 3: Add License Testers
- Go to: **Setup** → **License testing**
- Add test Gmail accounts
- These accounts can make test purchases without being charged

---

## 💰 Pricing Breakdown

| Product | Price | Commission (15%) | You Receive |
|---------|-------|------------------|-------------|
| Premium | ₹99 | ₹14.85 | ₹84.15 |
| Spotlight | ₹299 | ₹44.85 | ₹254.15 |
| Swipes | ₹20 | ₹3.00 | ₹17.00 |

*Note: Google Play takes 15% commission for first $1M in revenue, then 30%*

---

## 🔄 Purchase Flow

### Premium Subscription
```
User clicks "Subscribe Now"
  ↓
GooglePlayBillingService.purchasePremium()
  ↓
Google Play Billing UI opens
  ↓
User completes payment
  ↓
_handlePremiumPurchase()
  ↓
- Update user.isPremium = true
- Set premiumExpiryDate = now + 30 days
- Grant 50 bonus swipes
- Log to payment_orders
  ↓
Success callback → Show success dialog
```

### Spotlight Booking
```
User selects date and clicks "Book Spotlight"
  ↓
GooglePlayBillingService.purchaseSpotlight()
  ↓
Google Play Billing UI opens
  ↓
User completes payment
  ↓
_handleSpotlightPurchase()
  ↓
- Log purchase to payment_orders
- Create spotlight_bookings entry
- Update calendar
  ↓
Success callback → Show success dialog
```

### Swipe Pack
```
User clicks "Buy Swipes"
  ↓
GooglePlayBillingService.purchaseSwipes()
  ↓
Google Play Billing UI opens
  ↓
User completes payment
  ↓
_handleSwipePurchase()
  ↓
- Check if user is premium (10 vs 6 swipes)
- Add swipes to user account
- Log to payment_orders
  ↓
Success callback → Show success dialog
```

---

## 📊 Firestore Schema

### payment_orders Collection
```javascript
{
  userId: string,
  purchaseId: string,
  productId: string, // premium_monthly, spotlight_299, or swipe_20
  amount: number, // in paise (9900, 29900, or 2000)
  currency: 'INR',
  status: 'success',
  platform: 'google_play',
  type: string, // 'premium', 'spotlight', or 'swipes'
  description: string,
  completedAt: timestamp,
  verificationData: string,
  
  // Premium only
  premiumExpiryDate?: timestamp,
  
  // Spotlight only
  spotlightDate?: timestamp,
  spotlightBookingId?: string,
  
  // Swipes only
  swipesCount?: number
}
```

### spotlight_bookings Collection
```javascript
{
  userId: string,
  date: timestamp,
  status: 'pending' | 'active' | 'completed' | 'cancelled',
  paymentId: string,
  amount: 29900,
  createdAt: timestamp,
  appearanceCount: number
}
```

### swipe_stats Collection
```javascript
{
  userId: string,
  totalSwipes: number,
  freeSwipesUsed: number,
  purchasedSwipesRemaining: number,
  lastResetDate: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

---

## 🧪 Testing Guide

### Test Premium Subscription
1. Navigate to Payment/Premium screen
2. Click "Subscribe Now"
3. Complete test purchase
4. Verify:
   - `users/{userId}.isPremium = true`
   - `users/{userId}.premiumExpiryDate` set
   - `payment_orders` has new entry
   - 50 swipes granted

### Test Spotlight Booking
1. Navigate to Spotlight Booking screen
2. Select a future date
3. Click "Book Spotlight"
4. Complete test purchase
5. Verify:
   - `spotlight_bookings` has new entry
   - `payment_orders` has new entry
   - Calendar shows booking

### Test Swipe Pack
1. Use all free swipes
2. Click "Buy Swipes" when prompted
3. Complete test purchase
4. Verify:
   - Swipes added (6 or 10 based on premium status)
   - `payment_orders` has new entry
   - Can swipe again

---

## 🐛 Troubleshooting

### Products Not Loading
- **Issue**: Products show as unavailable
- **Solution**: 
  - Wait 2-4 hours after creating products
  - Verify product IDs match exactly
  - Check app is installed from Play Store (Internal Testing)

### Purchase Not Completing
- **Issue**: Purchase starts but doesn't complete
- **Solution**:
  - Check license tester account is added
  - Verify billing permission in AndroidManifest.xml
  - Check Firestore security rules

### Wrong Swipe Count
- **Issue**: User gets 6 swipes instead of 10 (or vice versa)
- **Solution**:
  - Verify `users/{userId}.isPremium` is correct
  - Check `_handleSwipePurchase` logic

---

## 🔐 Security Notes

1. **Server-side Verification**: Google Play handles verification
2. **No API Keys**: No sensitive keys in client code
3. **Purchase Validation**: Automatic by Google Play
4. **Fraud Prevention**: Built-in by Google Play

---

## 📞 Support

### Common Issues

**"In-app purchases unavailable"**
- App must be installed from Play Store
- Won't work with `flutter run` or debug builds

**"Product not found"**
- Product ID must match exactly (case-sensitive)
- Product must be activated in Play Console
- Wait a few hours after creating product

**"Payment failed"**
- Check license tester account
- Verify billing permission
- Check internet connection

---

## ✅ Pre-Launch Checklist

- [ ] All 3 products created in Google Play Console
- [ ] All products activated
- [ ] License testers added
- [ ] App uploaded to Internal Testing
- [ ] Test premium subscription
- [ ] Test spotlight booking
- [ ] Test swipe pack purchase
- [ ] Verify Firestore updates correctly
- [ ] Test restore purchases
- [ ] Check all error messages display properly

---

**Last Updated**: December 21, 2024
**Status**: ✅ Ready for Testing
**Products**: 3 (Premium, Spotlight, Swipes)
