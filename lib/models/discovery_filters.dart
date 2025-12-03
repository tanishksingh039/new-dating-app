class DiscoveryFilters {
  final int minAge;
  final int maxAge;
  final double? maxDistance; // in kilometers, null means no limit
  final List<String> interests; // Filter by specific interests
  final bool showVerifiedOnly;
  final String? education; // Filter by education level
  final String? courseStream; // Filter by course/stream

  DiscoveryFilters({
    this.minAge = 18,
    this.maxAge = 100,
    this.maxDistance,
    this.interests = const [],
    this.showVerifiedOnly = false,
    this.education,
    this.courseStream,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistance': maxDistance,
      'interests': interests,
      'showVerifiedOnly': showVerifiedOnly,
      'education': education,
      'courseStream': courseStream,
    };
  }

  // Create from Map
  factory DiscoveryFilters.fromMap(Map<String, dynamic> map) {
    return DiscoveryFilters(
      minAge: map['minAge'] ?? 18,
      maxAge: map['maxAge'] ?? 100,
      maxDistance: map['maxDistance']?.toDouble(),
      interests: List<String>.from(map['interests'] ?? []),
      showVerifiedOnly: map['showVerifiedOnly'] ?? false,
      education: map['education'],
      courseStream: map['courseStream'],
    );
  }

  // Create a copy with updated fields
  DiscoveryFilters copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interests,
    bool? showVerifiedOnly,
    String? education,
    String? courseStream,
  }) {
    return DiscoveryFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      interests: interests ?? this.interests,
      showVerifiedOnly: showVerifiedOnly ?? this.showVerifiedOnly,
      education: education ?? this.education,
      courseStream: courseStream ?? this.courseStream,
    );
  }

  // Check if any filters are active (non-default)
  bool get hasActiveFilters {
    return minAge != 18 ||
        maxAge != 100 ||
        maxDistance != null ||
        interests.isNotEmpty ||
        showVerifiedOnly ||
        education != null ||
        courseStream != null;
  }

  // Reset to default values
  DiscoveryFilters reset() {
    return DiscoveryFilters(
      minAge: 18,
      maxAge: 100,
      maxDistance: null,
      interests: const [],
      showVerifiedOnly: false,
      education: null,
    );
  }
}
