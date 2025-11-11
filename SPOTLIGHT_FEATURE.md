# Spotlight Feature Documentation

## Overview
The Spotlight feature allows users to boost their profile visibility by appearing multiple times throughout the day in the discovery tab. Users can book specific dates through a calendar interface and pay ₹299 per day.

## Features

### 1. Calendar-Based Booking
- Visual calendar showing available and booked dates
- Color-coded legend:
  - **Pink**: Selected date
  - **Green**: User's own bookings
  - **Gray**: Already booked by others
- Maximum 30 days advance booking
- Cannot book past dates

### 2. Payment Integration
- Razorpay payment gateway
- Price: ₹299 per day
- Secure payment with signature verification
- Automatic booking confirmation

### 3. Profile Rotation Algorithm
- Spotlight profiles appear 10 times per day
- Minimum 60-minute interval between appearances
- Fair rotation system (profiles with fewer appearances shown first)
- Automatic activation on booking date
- Automatic completion after 24 hours

## File Structure

```
lib/
├── config/
│   └── spotlight_config.dart          # Configuration constants
├── models/
│   └── spotlight_booking.dart         # Data models
├── services/
│   ├── spotlight_service.dart         # Booking and payment service
│   └── spotlight_discovery_service.dart # Discovery rotation logic
└── screens/
    └── spotlight/
        └── spotlight_booking_screen.dart # Calendar UI
```

## Usage

### 1. Navigate to Spotlight Booking

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SpotlightBookingScreen(),
  ),
);
```

### 2. Integrate with Discovery Screen

Add this to your discovery screen to show spotlight profiles:

```dart
import 'package:your_app/services/spotlight_discovery_service.dart';

class DiscoveryScreen extends StatefulWidget {
  // ... existing code
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final SpotlightDiscoveryService _spotlightService = SpotlightDiscoveryService();
  int _profilesShownCount = 0;
  List<String> _shownUserIds = [];

  @override
  void initState() {
    super.initState();
    // Activate today's spotlights on app start
    _spotlightService.activateTodaySpotlights();
    _spotlightService.completeExpiredSpotlights();
  }

  Future<DocumentSnapshot?> _getNextProfile() async {
    // Check if it's time to show spotlight
    final shouldShow = await _spotlightService.shouldShowSpotlight(
      profilesShownCount: _profilesShownCount,
    );

    if (shouldShow) {
      // Try to get spotlight profile
      final spotlightProfile = await _spotlightService.getSpotlightProfile(
        excludeUserIds: _shownUserIds,
      );

      if (spotlightProfile != null) {
        _shownUserIds.add(spotlightProfile.id);
        _profilesShownCount++;
        return spotlightProfile;
      }
    }

    // Get regular profile
    final regularProfile = await _getRegularProfile();
    if (regularProfile != null) {
      _shownUserIds.add(regularProfile.id);
      _profilesShownCount++;
    }
    return regularProfile;
  }

  // ... rest of your discovery logic
}
```

### 3. Add Spotlight Badge to Profile Cards

```dart
Widget buildProfileCard(DocumentSnapshot userDoc) {
  final isSpotlight = /* check if this is a spotlight profile */;
  
  return Stack(
    children: [
      // Your existing profile card
      YourProfileCard(userDoc: userDoc),
      
      // Spotlight badge
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
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'SPOTLIGHT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
```

## Configuration

Edit `lib/config/spotlight_config.dart` to customize:

```dart
class SpotlightConfig {
  static const int spotlightPriceInPaise = 29900;  // ₹299
  static const int appearancesPerDay = 10;          // How many times shown
  static const int appearanceIntervalMinutes = 60;  // Min interval
  static const int maxAdvanceBookingDays = 30;     // Max booking ahead
}
```

## Firestore Structure

### spotlight_bookings Collection

```javascript
{
  "userId": "user123",
  "date": Timestamp,
  "status": "pending|active|completed|cancelled",
  "paymentId": "pay_xxx",
  "amount": 29900,
  "createdAt": Timestamp,
  "activatedAt": Timestamp,
  "completedAt": Timestamp,
  "appearanceCount": 5,
  "lastShownAt": Timestamp
}
```

### payment_orders Collection (Spotlight)

```javascript
{
  "userId": "user123",
  "amount": 29900,
  "type": "spotlight",
  "spotlightDate": Timestamp,
  "spotlightBookingId": "booking123",
  "paymentId": "pay_xxx",
  "status": "success",
  "completedAt": Timestamp
}
```

## Firestore Rules

Copy the rules from `firestore_rules_with_spotlight.rules` to your Firebase Console:

```bash
# Deploy rules
firebase deploy --only firestore:rules
```

Or manually copy to Firebase Console → Firestore Database → Rules

## Installation

1. **Add dependency** to `pubspec.yaml`:
```yaml
dependencies:
  table_calendar: ^3.1.2
```

2. **Install packages**:
```bash
flutter pub get
```

3. **Deploy Firestore rules**:
- Copy contents of `firestore_rules_with_spotlight.rules`
- Paste in Firebase Console → Firestore Database → Rules
- Click Publish

4. **Add navigation** to your app:
```dart
// In your profile or premium features menu
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpotlightBookingScreen(),
      ),
    );
  },
  child: const Text('Book Spotlight'),
)
```

## Testing

### Test Payment Flow
1. Open Spotlight Booking screen
2. Select a future date (not grayed out)
3. Click "Book Spotlight"
4. Use Razorpay test cards:
   - **Success**: 4111 1111 1111 1111
   - **Failure**: 4000 0000 0000 0002
   - CVV: Any 3 digits
   - Expiry: Any future date

### Test Discovery Rotation
1. Create multiple spotlight bookings for today
2. Open discovery screen
3. Swipe through profiles
4. Spotlight profiles should appear every 5 regular profiles
5. Check Firestore to see `appearanceCount` incrementing

## Background Jobs (Recommended)

For production, set up Cloud Functions to:

### 1. Activate Today's Spotlights (Daily at 00:00)
```javascript
exports.activateDailySpotlights = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    // Activate pending bookings for today
  });
```

### 2. Complete Yesterday's Spotlights (Daily at 00:05)
```javascript
exports.completeExpiredSpotlights = functions.pubsub
  .schedule('5 0 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    // Complete active bookings from yesterday
  });
```

## API Reference

### SpotlightService

```dart
// Initialize payment handlers
void init({
  required Function(PaymentSuccessResponse) onSuccess,
  required Function(PaymentFailureResponse) onError,
  required Function(ExternalWalletResponse) onExternalWallet,
});

// Check if date is booked
Future<bool> isDateBooked(DateTime date);

// Get date statuses for calendar
Future<List<SpotlightDateStatus>> getDateStatuses(
  DateTime startDate,
  DateTime endDate,
);

// Start payment for date
Future<void> startSpotlightPayment(DateTime selectedDate);

// Handle successful payment
Future<void> handleSpotlightPaymentSuccess({
  required String paymentId,
  required DateTime spotlightDate,
  String? orderId,
  String? signature,
});

// Cancel booking
Future<void> cancelBooking(String bookingId);
```

### SpotlightDiscoveryService

```dart
// Check if spotlight should be shown
Future<bool> shouldShowSpotlight({
  required int profilesShownCount,
});

// Get spotlight profile
Future<DocumentSnapshot?> getSpotlightProfile({
  required List<String> excludeUserIds,
});

// Activate today's spotlights
Future<void> activateTodaySpotlights();

// Complete expired spotlights
Future<void> completeExpiredSpotlights();

// Get user statistics
Future<Map<String, dynamic>> getUserSpotlightStats(String userId);
```

## Troubleshooting

### Payment fails with permission-denied
- Ensure Firestore rules are deployed
- Check that `payment_orders` collection has proper rules
- Verify user is authenticated

### Spotlight profiles not appearing
- Call `activateTodaySpotlights()` on app start
- Check booking status in Firestore (should be 'active')
- Verify date matches today's date

### Calendar not loading
- Check internet connection
- Verify Firestore rules allow reading `spotlight_bookings`
- Check console for error messages

## Support

For issues or questions:
1. Check console logs for error messages
2. Verify Firestore rules are correctly deployed
3. Ensure all dependencies are installed
4. Check that Razorpay credentials are configured

## Future Enhancements

- [ ] Analytics dashboard for spotlight performance
- [ ] Bulk booking discounts
- [ ] Priority spotlight tiers (premium, gold, platinum)
- [ ] Refund system for cancelled bookings
- [ ] Push notifications when spotlight goes live
- [ ] A/B testing for optimal appearance frequency
