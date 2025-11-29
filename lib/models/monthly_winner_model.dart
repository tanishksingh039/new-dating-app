import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyWinnerModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int points;
  final int rank;
  final String month; // e.g., "November 2025"
  final String year; // e.g., "2025"
  final String? achievement; // e.g., "Top Performer"
  final String? message; // Congratulatory message
  final DateTime announcedAt;
  final String? adminId;
  final Map<String, dynamic>? metadata;

  MonthlyWinnerModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.points,
    required this.rank,
    required this.month,
    required this.year,
    this.achievement,
    this.message,
    required this.announcedAt,
    this.adminId,
    this.metadata,
  });

  factory MonthlyWinnerModel.fromMap(Map<String, dynamic> map, String id) {
    return MonthlyWinnerModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'],
      points: map['points'] ?? 0,
      rank: map['rank'] ?? 1,
      month: map['month'] ?? '',
      year: map['year'] ?? '',
      achievement: map['achievement'],
      message: map['message'],
      announcedAt: (map['announcedAt'] as Timestamp).toDate(),
      adminId: map['adminId'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'points': points,
      'rank': rank,
      'month': month,
      'year': year,
      'achievement': achievement,
      'message': message,
      'announcedAt': Timestamp.fromDate(announcedAt),
      'adminId': adminId,
      'metadata': metadata,
    };
  }

  String get displayMonth => '$month $year';
}
