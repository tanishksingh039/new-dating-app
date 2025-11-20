/// Razorpay Configuration
/// 
/// IMPORTANT SECURITY NOTE:
/// - These are TEST credentials and should ONLY be used in development
/// - For production, move these to environment variables or secure backend
/// - NEVER commit production keys to version control
class RazorpayConfig {
  // Test Mode Credentials
  static const String keyId = 'rzp_test_ReNM6Lc4hrZpYs';
  static const String keySecret = 'ATch0WcTc1u5o8xbKYrPKqUs';
  
  // App Configuration
  static const String companyName = 'ShooLuv';
  static const String currency = 'INR';
  static const String themeColor = '#FF6B9D';
  
  // Premium Subscription Pricing (in paise)
  static const int premiumMonthly = 49900;  // ₹499.00
  static const int premium3Months = 119900; // ₹1,199.00
  static const int premium6Months = 199900; // ₹1,999.00
  
  // Test Mode Flag
  static const bool isTestMode = true;
  
  /// Get display price from paise amount
  static String getDisplayPrice(int amountInPaise) {
    final amount = amountInPaise / 100;
    return '₹${amount.toStringAsFixed(0)}';
  }
}
