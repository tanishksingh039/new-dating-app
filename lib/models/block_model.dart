import 'package:cloud_firestore/cloud_firestore.dart';

class BlockModel {
  final String id;
  final String blockerId;
  final String blockedUserId;
  final DateTime createdAt;
  final String? reason;

  BlockModel({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'reason': reason,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'] ?? '',
      blockerId: map['blockerId'] ?? '',
      blockedUserId: map['blockedUserId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: map['reason'],
    );
  }

  BlockModel copyWith({
    String? id,
    String? blockerId,
    String? blockedUserId,
    DateTime? createdAt,
    String? reason,
  }) {
    return BlockModel(
      id: id ?? this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      createdAt: createdAt ?? this.createdAt,
      reason: reason ?? this.reason,
    );
  }
}
