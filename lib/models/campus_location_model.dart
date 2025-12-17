import 'package:cloud_firestore/cloud_firestore.dart';

class CampusLocation {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double radiusInKm;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.radiusInKm,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory CampusLocation.fromMap(Map<String, dynamic> map, String id) {
    return CampusLocation(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radiusInKm: (map['radiusInKm'] ?? 2.0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInKm': radiusInKm,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CampusLocation copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    double? radiusInKm,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampusLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusInKm: radiusInKm ?? this.radiusInKm,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
