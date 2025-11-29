import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardType {
  coupon,
  badge,
  premium,
  spotlight,
  other,
}

enum RewardStatus {
  pending,
  claimed,
  expired,
  used,
}

class RewardModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final RewardType type;
  final String title;
  final String description;
  final String? couponCode;
  final String? couponValue; // e.g., "50% OFF", "$10 OFF"
  final DateTime? expiryDate;
  final RewardStatus status;
  final DateTime createdAt;
  final DateTime? claimedAt;
  final DateTime? usedAt;
  final String? adminId;
  final String? adminNotes;
  final Map<String, dynamic>? metadata; // Additional data

  RewardModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.type,
    required this.title,
    required this.description,
    this.couponCode,
    this.couponValue,
    this.expiryDate,
    required this.status,
    required this.createdAt,
    this.claimedAt,
    this.usedAt,
    this.adminId,
    this.adminNotes,
    this.metadata,
  });

  factory RewardModel.fromMap(Map<String, dynamic> map, String id) {
    return RewardModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'],
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.other,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      couponCode: map['couponCode'],
      couponValue: map['couponValue'],
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
      status: RewardStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RewardStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      claimedAt: map['claimedAt'] != null
          ? (map['claimedAt'] as Timestamp).toDate()
          : null,
      usedAt: map['usedAt'] != null
          ? (map['usedAt'] as Timestamp).toDate()
          : null,
      adminId: map['adminId'],
      adminNotes: map['adminNotes'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'type': type.name,
      'title': title,
      'description': description,
      'couponCode': couponCode,
      'couponValue': couponValue,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'adminId': adminId,
      'adminNotes': adminNotes,
      'metadata': metadata,
    };
  }

  RewardModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    RewardType? type,
    String? title,
    String? description,
    String? couponCode,
    String? couponValue,
    DateTime? expiryDate,
    RewardStatus? status,
    DateTime? createdAt,
    DateTime? claimedAt,
    DateTime? usedAt,
    String? adminId,
    String? adminNotes,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      couponCode: couponCode ?? this.couponCode,
      couponValue: couponValue ?? this.couponValue,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      claimedAt: claimedAt ?? this.claimedAt,
      usedAt: usedAt ?? this.usedAt,
      adminId: adminId ?? this.adminId,
      adminNotes: adminNotes ?? this.adminNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isClaimed => status == RewardStatus.claimed || status == RewardStatus.used;

  bool get isUsed => status == RewardStatus.used;

  String get statusDisplayName {
    switch (status) {
      case RewardStatus.pending:
        return 'Available';
      case RewardStatus.claimed:
        return 'Claimed';
      case RewardStatus.expired:
        return 'Expired';
      case RewardStatus.used:
        return 'Used';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case RewardType.coupon:
        return 'Coupon Code';
      case RewardType.badge:
        return 'Badge';
      case RewardType.premium:
        return 'Premium Access';
      case RewardType.spotlight:
        return 'Spotlight Boost';
      case RewardType.other:
        return 'Reward';
    }
  }
}
