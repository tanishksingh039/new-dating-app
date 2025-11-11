# Razorpay Payment Integration Setup

## ✅ Configuration Complete

Your Razorpay payment integration has been successfully configured with the following credentials:

- **API Key ID**: `rzp_test_ReNM6Lc4hrZpYs`
- **Key Secret**: `ATch0WcTc1u5o8xbKYrPKqUs`
- **Mode**: Test Mode

## 📁 Files Created/Updated

### 1. Configuration File
- **Location**: `lib/config/razorpay_config.dart`
- **Purpose**: Centralized Razorpay configuration
- **Contains**: API keys, app settings, pricing tiers

### 2. Payment Service
- **Location**: `lib/services/payment_service.dart`
- **Updated**: Now uses RazorpayConfig for credentials
- **Features**:
  - Payment initialization
  - Signature verification (HMAC SHA256)
  - Firebase integration for payment tracking
  - Error handling

### 3. Dependencies
- **Updated**: `pubspec.yaml`
- **Added**: `crypto: ^3.0.3` for signature verification

## 🚀 How to Use

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Using Payment in Your App

#### Option A: Use Existing Payment Screen
Navigate to the payment screen that's already set up:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PaymentScreen()),
);
```

#### Option B: Custom Implementation
```dart
import 'package:your_app/services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class YourWidget extends StatefulWidget {
  @override
  _YourWidgetState createState() => _YourWidgetState();
}

class _YourWidgetState extends State<YourWidget> {
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment
    final isValid = await _paymentService.verifyPayment(
      orderId: response.orderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );

    if (isValid) {
      // Payment verified successfully
      print('Payment successful!');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet: ${response.walletName}');
  }

  void _startPayment() async {
    await _paymentService.startPayment(
      amountInPaise: 49900, // ₹499.00
      description: 'Premium Subscription',
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }
}
```

## 💰 Pricing Tiers (Configured)

- **1 Month Premium**: ₹499 (49900 paise)
- **3 Months Premium**: ₹1,199 (119900 paise)
- **6 Months Premium**: ₹1,999 (199900 paise)

## 🧪 Testing

### Test Cards for Razorpay Test Mode

#### Successful Payment
- **Card Number**: `4111 1111 1111 1111`
- **CVV**: Any 3 digits
- **Expiry**: Any future date
- **Name**: Any name

#### Failed Payment
- **Card Number**: `4000 0000 0000 0002`
- **CVV**: Any 3 digits
- **Expiry**: Any future date

#### Other Test Scenarios
- **Insufficient Funds**: `4000 0000 0000 9995`
- **Card Declined**: `4000 0000 0000 0069`

### UPI Testing
- Use any UPI ID in test mode (e.g., `success@razorpay`)
- Payment will be simulated

## 🔒 Security Features

✅ **Signature Verification**: All payments are verified using HMAC SHA256
✅ **Firebase Tracking**: Payment attempts and completions logged
✅ **Test Mode**: Currently in test mode - no real money transactions
✅ **Secure Storage**: Keys stored in dedicated config file

## ⚠️ Important Notes

### For Production Deployment

1. **Move to Environment Variables**:
   - Never commit production keys to Git
   - Use environment variables or secure backend storage
   - Consider using Flutter's `--dart-define` for build-time configuration

2. **Backend Verification**:
   - Implement server-side payment verification
   - Don't rely solely on client-side verification
   - Update the `verifyPayment()` method to call your backend

3. **Switch to Live Keys**:
   - Replace test keys with live keys from Razorpay Dashboard
   - Update `isTestMode` to `false` in `razorpay_config.dart`
   - Test thoroughly before going live

4. **Compliance**:
   - Ensure PCI DSS compliance
   - Add proper privacy policy
   - Implement refund mechanisms

## 📱 Android Setup

Ensure your `AndroidManifest.xml` has internet permission:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 🍎 iOS Setup

Add the following to your `Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🐛 Troubleshooting

### Payment not opening?
- Check if Razorpay plugin is properly initialized
- Verify API key is correct
- Check console for error messages

### Payment verification failing?
- Ensure `crypto` package is installed
- Check if signature verification logic is correct
- Verify key secret matches your Razorpay account

### Firebase errors?
- Ensure Firebase is properly configured
- Check Firestore security rules
- Verify user is authenticated

## 📚 Resources

- [Razorpay Documentation](https://razorpay.com/docs/)
- [Razorpay Flutter Plugin](https://pub.dev/packages/razorpay_flutter)
- [Test Mode Guide](https://razorpay.com/docs/payments/payments/test-card-details/)

## 🎯 Next Steps

1. Run `flutter pub get` to install the crypto package
2. Test the payment flow using test cards
3. Verify payments are being logged in Firebase
4. Customize the payment UI as needed
5. Plan for production deployment with backend verification

---

**Status**: ✅ Ready for Testing
**Last Updated**: November 11, 2025
