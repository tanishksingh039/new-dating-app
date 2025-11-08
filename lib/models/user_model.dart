import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final String name;
  final DateTime? dateOfBirth;
  final String gender;
  final List<String> photos;
  final List<String> interests;
  final String bio;
  final Map<String, dynamic> preferences;
  final bool isOnboardingComplete;
  final DateTime createdAt;
  final DateTime? lastActive;
  
  // Phase 1 fields
  final bool isVerified;
  final bool isPremium;
  final List<String> matches;
  final int matchCount;
  final Map<String, int> dailySwipes;
  
  // Phase 2 fields - Privacy & Notification Settings
  final Map<String, dynamic> privacySettings;
  final Map<String, dynamic> notificationSettings;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.name = '',
    this.dateOfBirth,
    this.gender = '',
    this.photos = const [],
    this.interests = const [],
    this.bio = '',
    this.preferences = const {},
    this.isOnboardingComplete = false,
    required this.createdAt,
    this.lastActive,
    this.isVerified = false,
    this.isPremium = false,
    this.matches = const [],
    this.matchCount = 0,
    this.dailySwipes = const {},
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? notificationSettings,
  })  : privacySettings = privacySettings ??
            {
              'showOnlineStatus': true,
              'showDistance': true,
              'showAge': true,
              'showLastActive': false,
              'allowMessagesFromMatches': true,
              'incognitoMode': false,
            },
        notificationSettings = notificationSettings ??
            {
              'pushEnabled': true,
              'newMatchNotif': true,
              'messageNotif': true,
              'likeNotif': true,
              'superLikeNotif': true,
              'emailEnabled': false,
              'emailMatches': false,
              'emailMessages': false,
              'emailPromotions': false,
            };

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'photos': photos,
      'interests': interests,
      'bio': bio,
      'preferences': preferences,
      'isOnboardingComplete': isOnboardingComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'matches': matches,
      'matchCount': matchCount,
      'dailySwipes': dailySwipes,
      'privacySettings': privacySettings,
      'notificationSettings': notificationSettings,
    };
  }

  // Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Helper to parse dateOfBirth from either String or Timestamp
    DateTime? parseDateOfBirth(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'] ?? '',
      dateOfBirth: parseDateOfBirth(map['dateOfBirth']),
      gender: map['gender'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      bio: map['bio'] ?? '',
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      isOnboardingComplete: map['isOnboardingComplete'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate(),
      isVerified: map['isVerified'] ?? false,
      isPremium: map['isPremium'] ?? false,
      matches: List<String>.from(map['matches'] ?? []),
      matchCount: map['matchCount'] ?? 0,
      dailySwipes: Map<String, int>.from(map['dailySwipes'] ?? {}),
      privacySettings: map['privacySettings'] != null
          ? Map<String, dynamic>.from(map['privacySettings'])
          : null,
      notificationSettings: map['notificationSettings'] != null
          ? Map<String, dynamic>.from(map['notificationSettings'])
          : null,
    );
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? photos,
    List<String>? interests,
    String? bio,
    Map<String, dynamic>? preferences,
    bool? isOnboardingComplete,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isVerified,
    bool? isPremium,
    List<String>? matches,
    int? matchCount,
    Map<String, int>? dailySwipes,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? notificationSettings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      preferences: preferences ?? this.preferences,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      matches: matches ?? this.matches,
      matchCount: matchCount ?? this.matchCount,
      dailySwipes: dailySwipes ?? this.dailySwipes,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }
}