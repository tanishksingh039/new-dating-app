/// Swipe Limit Configuration
class SwipeConfig {
  // Free swipes for non-premium users
  static const int freeSwipesNonPremium = 8;
  
  // Free swipes for premium users
  static const int freeSwipesPremium = 20;
  
  // Additional swipes for non-premium users (per purchase)
  static const int additionalSwipesNonPremium = 6;
  
  // Additional swipes for premium users (per purchase)
  static const int additionalSwipesPremium = 10;
  
  // Price for additional swipes (in paise)
  static const int additionalSwipesPriceInPaise = 2000; // ₹20
  
  // Price display
  static const String additionalSwipesPriceDisplay = '₹20';
  
  // Get free swipes based on premium status
  static int getFreeSwipes(bool isPremium) {
    return isPremium ? freeSwipesPremium : freeSwipesNonPremium;
  }
  
  // Get additional swipes count based on premium status
  static int getAdditionalSwipesCount(bool isPremium) {
    return isPremium ? additionalSwipesPremium : additionalSwipesNonPremium;
  }
  
  // Get swipe package description
  static String getSwipePackageDescription(bool isPremium) {
    final count = getAdditionalSwipesCount(isPremium);
    return '$count swipes for $additionalSwipesPriceDisplay';
  }
}
