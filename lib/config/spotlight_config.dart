/// Spotlight Feature Configuration
class SpotlightConfig {
  // Spotlight price in paise (₹299.00)
  static const int spotlightPriceInPaise = 29900;
  
  // Spotlight price display
  static const String spotlightPriceDisplay = '₹299';
  
  // How many times a spotlight profile appears in discovery per day
  static const int appearancesPerDay = 10;
  
  // Interval between spotlight appearances (in minutes)
  static const int appearanceIntervalMinutes = 60;
  
  // Maximum advance booking days (3 months = ~90 days)
  static const int maxAdvanceBookingDays = 90;
  
  // Spotlight duration (1 day)
  static const int spotlightDurationDays = 1;
  
  // App name for payment
  static const String appName = 'shooLuv';
  
  // Theme color for payment UI
  static const String themeColor = '#FF6B9D';
}
