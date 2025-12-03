import 'package:flutter/material.dart';

/// App Constants - Colors, Styles, and Data
class AppConstants {
  // ==================== COLORS ====================
  
  // Primary Colors
  static const Color primaryPurple = Color(0xFF667eea);
  static const Color primaryPink = Color(0xFFFF6B9D);
  static const Color primaryDark = Color(0xFF764ba2);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
      Color(0xFFf093fb),
    ],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
  );
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  
  // Text Colors
  static const Color textDark = Color(0xFF2D3142);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // ==================== TEXT STYLES ====================
  
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textDark,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
    letterSpacing: 0.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textDark,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textGrey,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textLight,
    height: 1.3,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  // ==================== SPACING ====================
  
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  // ==================== INTERESTS LIST ====================
  
  static const List<Map<String, dynamic>> interests = [
    {'name': 'Travel', 'icon': '✈️'},
    {'name': 'Music', 'icon': '🎵'},
    {'name': 'Movies', 'icon': '🎬'},
    {'name': 'Food', 'icon': '🍕'},
    {'name': 'Fitness', 'icon': '💪'},
    {'name': 'Sports', 'icon': '⚽'},
    {'name': 'Reading', 'icon': '📚'},
    {'name': 'Photography', 'icon': '📷'},
    {'name': 'Art', 'icon': '🎨'},
    {'name': 'Dancing', 'icon': '💃'},
    {'name': 'Cooking', 'icon': '👨‍🍳'},
    {'name': 'Gaming', 'icon': '🎮'},
    {'name': 'Fashion', 'icon': '👗'},
    {'name': 'Technology', 'icon': '💻'},
    {'name': 'Nature', 'icon': '🌿'},
    {'name': 'Pets', 'icon': '🐶'},
    {'name': 'Coffee', 'icon': '☕'},
    {'name': 'Wine', 'icon': '🍷'},
    {'name': 'Yoga', 'icon': '🧘'},
    {'name': 'Beach', 'icon': '🏖️'},
    {'name': 'Mountains', 'icon': '⛰️'},
    {'name': 'Shopping', 'icon': '🛍️'},
    {'name': 'Comedy', 'icon': '😂'},
    {'name': 'Adventure', 'icon': '🏕️'},
    {'name': 'Cars', 'icon': '🚗'},
    {'name': 'Bikes', 'icon': '🏍️'},
    {'name': 'Writing', 'icon': '✍️'},
    {'name': 'Volunteering', 'icon': '🤝'},
    {'name': 'Meditation', 'icon': '🧘‍♀️'},
    {'name': 'DIY', 'icon': '🔨'},
  ];
  
  // ==================== GENDER OPTIONS ====================
  
  static const List<Map<String, dynamic>> genderOptions = [
    {'value': 'male', 'label': 'Male', 'icon': '👨'},
    {'value': 'female', 'label': 'Female', 'icon': '👩'},
  ];
  
  // ==================== LOOKING FOR OPTIONS ====================
  
  static const List<Map<String, dynamic>> lookingForOptions = [
    {
      'value': 'relationship',
      'label': 'Relationship',
      'icon': '❤️',
      'description': 'Long-term commitment'
    },
    {
      'value': 'casual',
      'label': 'Casual',
      'icon': '😊',
      'description': 'Keep it fun and light'
    },
    {
      'value': 'friendship',
      'label': 'Friendship',
      'icon': '👋',
      'description': 'Just looking for friends'
    },
  ];
  
  // ==================== EDUCATION OPTIONS ====================
  
  static const List<String> educationOptions = [
    'High School',
    'Some College',
    'Associate Degree',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Trade School',
    'Prefer not to say',
  ];

  // ==================== COURSE/STREAM OPTIONS ====================
  
  static const List<String> courseStreamOptions = [
    // Bachelor Degrees
    'B.Tech (Bachelor of Technology)',
    'B.Sc. (Bachelor of Science)',
    'B.Sc. (Hons) (Bachelor of Science Honours)',
    'B.Com (Hons) (Bachelor of Commerce Honours)',
    'BBA (Bachelor of Business Administration)',
    'BCA (Bachelor of Computer Applications)',
    'B.Pharmacy',
    'BA (Bachelor of Arts)',
    'BA (Hons) (Bachelor of Arts Honours)',
    'B.Design',
    'B.Sc. Hospitality and Hotel Administration',
    'BA LLB (Integrated Law Program)',
    'BBA LLB (Integrated Law Program)',
    'LLB (Bachelor of Laws)',
    
    // Master Degrees
    'MBA (Master of Business Administration)',
    'M.Tech (Master of Technology)',
    'M.Sc. (Master of Science)',
    'M.Pharm (Master of Pharmacy)',
    'MA (Master of Arts)',
    'MCA (Master of Computer Applications)',
    'LLM (Master of Laws)',
    
    // Doctorate
    'PhD',
    'Others',
  ];
  
  // ==================== VALIDATION ====================
  
  static const int minAge = 18;
  static const int maxAge = 100;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minBioLength = 50;
  static const int maxBioLength = 500;
  static const int minInterests = 3;
  static const int maxInterests = 10;
  static const int minPhotos = 2;
  static const int maxPhotos = 6;
  static const int maxPhotoSizeMB = 5;
  
  // ==================== HELPER METHODS ====================
  
  /// Get interest icon by name
  static String getInterestIcon(String interestName) {
    final interest = interests.firstWhere(
      (i) => i['name'] == interestName,
      orElse: () => {'icon': '⭐'},
    );
    return interest['icon'];
  }
  
  /// Get gender label by value
  static String getGenderLabel(String value) {
    final gender = genderOptions.firstWhere(
      (g) => g['value'] == value,
      orElse: () => {'label': value},
    );
    return gender['label'];
  }
  
  /// Get looking for label by value
  static String getLookingForLabel(String value) {
    final option = lookingForOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    );
    return option['label'];
  }
  
  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < minNameLength) {
      return 'Name must be at least $minNameLength characters';
    }
    if (value.trim().length > maxNameLength) {
      return 'Name must be less than $maxNameLength characters';
    }
    return null;
  }
  
  /// Validate bio
  static String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Bio is optional
    }
    if (value.trim().length < minBioLength) {
      return 'Bio must be at least $minBioLength characters';
    }
    if (value.trim().length > maxBioLength) {
      return 'Bio must be less than $maxBioLength characters';
    }
    return null;
  }
  
  /// Validate age
  static String? validateAge(int? age) {
    if (age == null) {
      return 'Age is required';
    }
    if (age < minAge) {
      return 'You must be at least $minAge years old';
    }
    if (age > maxAge) {
      return 'Please enter a valid age';
    }
    return null;
  }
  
  /// Get age display text
  static String getAgeDisplay(int age) {
    if (age < minAge) return 'Too young';
    if (age > maxAge) return 'Invalid';
    return '$age years old';
  }
  
  /// Format distance
  static String formatDistance(int distanceKm) {
    if (distanceKm < 1) return 'Less than 1 km';
    if (distanceKm >= 100) return '100+ km away';
    return '$distanceKm km away';
  }
}

/// Box Decoration Helpers
class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppConstants.cardColor,
    borderRadius: BorderRadius.circular(AppConstants.radiusL),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration gradientDecoration = BoxDecoration(
    gradient: AppConstants.primaryGradient,
    borderRadius: BorderRadius.circular(AppConstants.radiusL),
  );
  
  static BoxDecoration inputDecoration = BoxDecoration(
    color: AppConstants.backgroundColor,
    borderRadius: BorderRadius.circular(AppConstants.radiusM),
  );
}