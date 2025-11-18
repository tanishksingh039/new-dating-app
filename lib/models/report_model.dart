import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  inappropriateContent,
  harassment,
  spam,
  fakeProfile,
  underage,
  violence,
  hateSpeech,
  other,
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final String? adminId;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.adminNotes,
    this.adminId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminNotes': adminNotes,
      'adminId': adminId,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      description: map['description'] ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: map['adminNotes'],
      adminId: map['adminId'],
    );
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    ReportReason? reason,
    String? description,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminNotes,
    String? adminId,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      adminId: adminId ?? this.adminId,
    );
  }
}

// Helper extension for display names
extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.fakeProfile:
        return 'Fake Profile';
      case ReportReason.underage:
        return 'Underage User';
      case ReportReason.violence:
        return 'Violence or Threats';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.inappropriateContent:
        return 'Sexually explicit or inappropriate photos/content';
      case ReportReason.harassment:
        return 'Bullying, harassment, or unwanted contact';
      case ReportReason.spam:
        return 'Spam messages or promotional content';
      case ReportReason.fakeProfile:
        return 'Using fake photos or false information';
      case ReportReason.underage:
        return 'User appears to be under 18';
      case ReportReason.violence:
        return 'Threats of violence or harmful behavior';
      case ReportReason.hateSpeech:
        return 'Discriminatory or hateful language';
      case ReportReason.other:
        return 'Other violation of community guidelines';
    }
  }
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}
