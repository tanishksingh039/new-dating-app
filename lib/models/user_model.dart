import 'package:cloud_firestore/cloud_firestore.dart';

/// User Model - Complete user profile data for dating app
class UserModel {
  // Basic Info
  final String uid;
  final String email;
  final String? phoneNumber;
  final String name;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender; // male, female, other
  
  // Photos
  final List<String> photos;
  final String? profilePhoto;
  
  // Profile Details
  final String? bio;
  final List<String> interests;
  final String? location;
  final String? city;
  final String? state;
  final String? country;
  
  // Additional Details
  final int? height; // in cm
  final String? education;
  final String? occupation;
  
  // Preferences
  final String? lookingFor; // relationship, casual, friendship
  final int? ageRangeMin;
  final int? ageRangeMax;
  final int? distance; // in km
  final String? interestedIn; // male, female, everyone
  final Map<String, dynamic> preferences; // Additional custom preferences
  
  // Status & Verification
  final bool onboardingCompleted;
  final int profileComplete; // percentage
  final bool isVerified;
  final bool isPremium;
  
  // Matching & Activity
  final List<String> matches;
  final int matchCount;
  final Map<String, int> dailySwipes; // date -> swipe count
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? lastActive;

  UserModel({
    required this.uid,
    required this.email,
    this.phoneNumber,
    this.name = '',
    this.dateOfBirth,
    this.age,
    this.gender,
    this.photos = const [],
    this.profilePhoto,
    this.bio,
    this.interests = const [],
    this.location,
    this.city,
    this.state,
    this.country,
    this.height,
    this.education,
    this.occupation,
    this.lookingFor,
    this.ageRangeMin,
    this.ageRangeMax,
    this.distance,
    this.interestedIn,
    this.preferences = const {},
    this.onboardingCompleted = false,
    this.profileComplete = 0,
    this.isVerified = false,
    this.isPremium = false,
    this.matches = const [],
    this.matchCount = 0,
    this.dailySwipes = const {},
    required this.createdAt,
    this.lastLogin,
    this.lastActive,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'],
      name: data['name'] ?? '',
      dateOfBirth: data['dateOfBirth'] != null 
          ? _parseDateTime(data['dateOfBirth']) 
          : null,
      age: data['age'],
      gender: data['gender'],
      photos: data['photos'] != null 
          ? List<String>.from(data['photos']) 
          : [],
      profilePhoto: data['profilePhoto'],
      bio: data['bio'],
      interests: data['interests'] != null 
          ? List<String>.from(data['interests']) 
          : [],
      location: data['location'],
      city: data['city'],
      state: data['state'],
      country: data['country'],
      height: data['height'],
      education: data['education'],
      occupation: data['occupation'],
      lookingFor: data['lookingFor'],
      ageRangeMin: data['ageRangeMin'],
      ageRangeMax: data['ageRangeMax'],
      distance: data['distance'],
      interestedIn: data['interestedIn'],
      preferences: data['preferences'] != null
          ? Map<String, dynamic>.from(data['preferences'])
          : {},
      onboardingCompleted: data['onboardingCompleted'] ?? 
                          data['isOnboardingComplete'] ?? 
                          false,
      profileComplete: data['profileComplete'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      isPremium: data['isPremium'] ?? false,
      matches: data['matches'] != null
          ? List<String>.from(data['matches'])
          : [],
      matchCount: data['matchCount'] ?? 0,
      dailySwipes: data['dailySwipes'] != null
          ? Map<String, int>.from(data['dailySwipes'])
          : {},
      createdAt: data['createdAt'] != null 
          ? _parseDateTime(data['createdAt']) 
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null 
          ? _parseDateTime(data['lastLogin']) 
          : null,
      lastActive: data['lastActive'] != null 
          ? _parseDateTime(data['lastActive']) 
          : null,
    );
  }

  /// Create UserModel from Map (for backwards compatibility)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone'],
      name: map['name'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null
          ? _parseDateTime(map['dateOfBirth'])
          : null,
      age: map['age'],
      gender: map['gender'],
      photos: map['photos'] != null 
          ? List<String>.from(map['photos']) 
          : [],
      profilePhoto: map['profilePhoto'],
      bio: map['bio'],
      interests: map['interests'] != null 
          ? List<String>.from(map['interests']) 
          : [],
      location: map['location'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      height: map['height'],
      education: map['education'],
      occupation: map['occupation'],
      lookingFor: map['lookingFor'],
      ageRangeMin: map['ageRangeMin'],
      ageRangeMax: map['ageRangeMax'],
      distance: map['distance'],
      interestedIn: map['interestedIn'],
      preferences: map['preferences'] != null
          ? Map<String, dynamic>.from(map['preferences'])
          : {},
      onboardingCompleted: map['onboardingCompleted'] ?? 
                          map['isOnboardingComplete'] ?? 
                          false,
      profileComplete: map['profileComplete'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isPremium: map['isPremium'] ?? false,
      matches: map['matches'] != null
          ? List<String>.from(map['matches'])
          : [],
      matchCount: map['matchCount'] ?? 0,
      dailySwipes: map['dailySwipes'] != null
          ? Map<String, int>.from(map['dailySwipes'])
          : {},
      createdAt: map['createdAt'] != null 
          ? _parseDateTime(map['createdAt']) 
          : DateTime.now(),
      lastLogin: map['lastLogin'] != null 
          ? _parseDateTime(map['lastLogin']) 
          : null,
      lastActive: map['lastActive'] != null 
          ? _parseDateTime(map['lastActive']) 
          : null,
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'name': name,
      if (dateOfBirth != null) 
        'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      'photos': photos,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      if (bio != null) 'bio': bio,
      'interests': interests,
      if (location != null) 'location': location,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (height != null) 'height': height,
      if (education != null) 'education': education,
      if (occupation != null) 'occupation': occupation,
      if (lookingFor != null) 'lookingFor': lookingFor,
      if (ageRangeMin != null) 'ageRangeMin': ageRangeMin,
      if (ageRangeMax != null) 'ageRangeMax': ageRangeMax,
      if (distance != null) 'distance': distance,
      if (interestedIn != null) 'interestedIn': interestedIn,
      'preferences': preferences,
      'onboardingCompleted': onboardingCompleted,
      'profileComplete': profileComplete,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'matches': matches,
      'matchCount': matchCount,
      'dailySwipes': dailySwipes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLogin != null) 
        'lastLogin': Timestamp.fromDate(lastLogin!),
      if (lastActive != null) 
        'lastActive': Timestamp.fromDate(lastActive!),
    };
  }

  /// Convert to Map (for backwards compatibility)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'name': name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      'photos': photos,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      if (bio != null) 'bio': bio,
      'interests': interests,
      if (location != null) 'location': location,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (height != null) 'height': height,
      if (education != null) 'education': education,
      if (occupation != null) 'occupation': occupation,
      if (lookingFor != null) 'lookingFor': lookingFor,
      if (ageRangeMin != null) 'ageRangeMin': ageRangeMin,
      if (ageRangeMax != null) 'ageRangeMax': ageRangeMax,
      if (distance != null) 'distance': distance,
      if (interestedIn != null) 'interestedIn': interestedIn,
      'preferences': preferences,
      'onboardingCompleted': onboardingCompleted,
      'profileComplete': profileComplete,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'matches': matches,
      'matchCount': matchCount,
      'dailySwipes': dailySwipes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLogin != null) 
        'lastLogin': Timestamp.fromDate(lastLogin!),
      if (lastActive != null) 
        'lastActive': Timestamp.fromDate(lastActive!),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? name,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    List<String>? photos,
    String? profilePhoto,
    String? bio,
    List<String>? interests,
    String? location,
    String? city,
    String? state,
    String? country,
    int? height,
    String? education,
    String? occupation,
    String? lookingFor,
    int? ageRangeMin,
    int? ageRangeMax,
    int? distance,
    String? interestedIn,
    Map<String, dynamic>? preferences,
    bool? onboardingCompleted,
    int? profileComplete,
    bool? isVerified,
    bool? isPremium,
    List<String>? matches,
    int? matchCount,
    Map<String, int>? dailySwipes,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photos: photos ?? this.photos,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      height: height ?? this.height,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      lookingFor: lookingFor ?? this.lookingFor,
      ageRangeMin: ageRangeMin ?? this.ageRangeMin,
      ageRangeMax: ageRangeMax ?? this.ageRangeMax,
      distance: distance ?? this.distance,
      interestedIn: interestedIn ?? this.interestedIn,
      preferences: preferences ?? this.preferences,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileComplete: profileComplete ?? this.profileComplete,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      matches: matches ?? this.matches,
      matchCount: matchCount ?? this.matchCount,
      dailySwipes: dailySwipes ?? this.dailySwipes,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  /// Calculate profile completion percentage
  int calculateProfileComplete() {
    int progress = 0;
    
    // Basic info (20%)
    if (name.isNotEmpty && dateOfBirth != null && gender != null) {
      progress += 20;
    }
    
    // Photos (20%)
    if (photos.length >= 2) {
      progress += 20;
    }
    
    // Interests (20%)
    if (interests.length >= 3) {
      progress += 20;
    }
    
    // Bio (20%)
    if (bio != null && bio!.length >= 50) {
      progress += 20;
    }
    
    // Preferences (20%)
    if (lookingFor != null && interestedIn != null) {
      progress += 20;
    }
    
    return progress;
  }

  /// Get user age from date of birth
  static int getAgeFromDOB(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || 
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Get current age (computed from dateOfBirth if age is null)
  int? get currentAge {
    if (age != null) return age;
    if (dateOfBirth != null) return getAgeFromDOB(dateOfBirth!);
    return null;
  }

  /// Check if user can swipe today (daily limit check)
  bool canSwipeToday({int dailyLimit = 100}) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todaySwipes = dailySwipes[today] ?? 0;
    return isPremium || todaySwipes < dailyLimit;
  }

  /// Get today's swipe count
  int getTodaySwipeCount() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return dailySwipes[today] ?? 0;
  }

  /// Check if profile is complete enough to start swiping
  bool get canStartSwiping {
    return onboardingCompleted && 
           photos.isNotEmpty && 
           interests.isNotEmpty &&
           bio != null &&
           bio!.isNotEmpty;
  }
}