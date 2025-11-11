# Spotlight Feature - Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Deploy Firestore Rules
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Go to **Firestore Database** → **Rules**
3. Copy contents from `firestore_rules_with_spotlight.rules`
4. Paste and click **Publish**

### Step 3: Add Navigation Button
Add this anywhere in your app (e.g., profile screen, premium features):

```dart
import 'package:your_app/screens/spotlight/spotlight_booking_screen.dart';

// In your widget
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpotlightBookingScreen(),
      ),
    );
  },
  icon: const Icon(Icons.star),
  label: const Text('Book Spotlight'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFF6B9D),
  ),
)
```

### Step 4: Test the Feature
1. Run the app
2. Click "Book Spotlight"
3. Select a date
4. Complete test payment
5. Check Firestore for booking record

## 📱 How It Works

### For Users:
1. **Open Calendar** - See available dates
2. **Select Date** - Pick when to be featured
3. **Pay ₹299** - Secure Razorpay payment
4. **Get Featured** - Profile appears 10x that day

### For Developers:
1. **Booking** - User selects date → Payment → Firestore record
2. **Activation** - Status changes from 'pending' to 'active' on booking date
3. **Discovery** - Spotlight profiles injected every 5 regular profiles
4. **Completion** - Status changes to 'completed' after 24 hours

## 🎨 Integrate with Discovery Screen

Find your discovery screen and add:

```dart
import 'package:your_app/services/spotlight_discovery_service.dart';

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final SpotlightDiscoveryService _spotlightService = SpotlightDiscoveryService();
  int _profilesShown = 0;
  List<String> _shownIds = [];

  @override
  void initState() {
    super.initState();
    // Activate spotlights on app start
    _spotlightService.activateTodaySpotlights();
    _spotlightService.completeExpiredSpotlights();
  }

  Future<DocumentSnapshot?> _getNextProfile() async {
    // Every 5 profiles, try to show spotlight
    if (_profilesShown > 0 && _profilesShown % 5 == 0) {
      final spotlight = await _spotlightService.getSpotlightProfile(
        excludeUserIds: _shownIds,
      );
      
      if (spotlight != null) {
        _shownIds.add(spotlight.id);
        _profilesShown++;
        return spotlight;
      }
    }

    // Get regular profile
    final regular = await _getRegularProfile();
    if (regular != null) {
      _shownIds.add(regular.id);
      _profilesShown++;
    }
    return regular;
  }
}
```

## 🏷️ Add Spotlight Badge

Show a badge on spotlight profiles:

```dart
// Check if profile is spotlight
final isSpotlight = /* your logic to check */;

// Add badge to profile card
if (isSpotlight)
  Positioned(
    top: 16,
    right: 16,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text('SPOTLIGHT', style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    ),
  )
```

## 🧪 Test Payment

Use these Razorpay test cards:

| Card Number | Result |
|-------------|--------|
| 4111 1111 1111 1111 | Success |
| 4000 0000 0000 0002 | Failure |

- **CVV**: Any 3 digits
- **Expiry**: Any future date
- **OTP**: 123456

## 📊 Check Bookings in Firestore

After payment, verify in Firebase Console:

```
spotlight_bookings/
  └── {bookingId}
      ├── userId: "user123"
      ├── date: Timestamp
      ├── status: "pending" → "active" → "completed"
      ├── paymentId: "pay_xxx"
      ├── amount: 29900
      └── appearanceCount: 0 → 10
```

## ⚙️ Configuration

Edit `lib/config/spotlight_config.dart`:

```dart
static const int spotlightPriceInPaise = 29900;  // Change price
static const int appearancesPerDay = 10;          // Change frequency
static const int appearanceIntervalMinutes = 60;  // Change interval
```

## 🐛 Common Issues

### "Permission Denied" Error
**Fix**: Deploy Firestore rules from `firestore_rules_with_spotlight.rules`

### Spotlight Not Showing in Discovery
**Fix**: Call `_spotlightService.activateTodaySpotlights()` in initState

### Calendar Not Loading
**Fix**: Check internet connection and Firestore rules

### Payment Fails
**Fix**: Verify Razorpay credentials in `razorpay_config.dart`

## 📈 Monitor Performance

Check spotlight statistics:

```dart
final stats = await SpotlightDiscoveryService()
  .getUserSpotlightStats(userId);

print('Total bookings: ${stats['totalBookings']}');
print('Total appearances: ${stats['totalAppearances']}');
```

## 🎯 Next Steps

1. ✅ Deploy Firestore rules
2. ✅ Add navigation button
3. ✅ Integrate with discovery
4. ✅ Add spotlight badge
5. ✅ Test payment flow
6. 📱 Launch to users!

## 📚 Full Documentation

See `SPOTLIGHT_FEATURE.md` for complete documentation including:
- Advanced configuration
- Cloud Functions setup
- Analytics integration
- Troubleshooting guide

## 💡 Tips

- **Booking Window**: Users can book up to 30 days in advance
- **Fair Rotation**: Profiles with fewer appearances shown first
- **Automatic Management**: Bookings auto-activate and complete
- **Revenue Tracking**: All payments logged in Firestore

---

**Need Help?** Check the full documentation in `SPOTLIGHT_FEATURE.md`
