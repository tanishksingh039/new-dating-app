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

enum AdminAction {
  none,
  warning,
  tempBan7Days,
  permanentBan,
  accountDeleted,
}

class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reportedUserName; // Name of the reported user
  final String? reportedUserPhoto; // Photo of the reported user
  final ReportReason reason;
  final String description;
  final List<String> evidenceImages; // Screenshots/evidence uploaded by reporter
  final ReportStatus status;
  final AdminAction adminAction; // Action taken by admin
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final String? adminId;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportedUserName,
    this.reportedUserPhoto,
    required this.reason,
    required this.description,
    this.evidenceImages = const [],
    this.status = ReportStatus.pending,
    this.adminAction = AdminAction.none,
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
      'reportedUserName': reportedUserName,
      'reportedUserPhoto': reportedUserPhoto,
      'reason': reason.name,
      'description': description,
      'evidenceImages': evidenceImages,
      'status': status.name,
      'adminAction': adminAction.name,
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
      reportedUserName: map['reportedUserName'] ?? 'Unknown User',
      reportedUserPhoto: map['reportedUserPhoto'],
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      description: map['description'] ?? '',
      evidenceImages: List<String>.from(map['evidenceImages'] ?? []),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      adminAction: AdminAction.values.firstWhere(
        (e) => e.name == map['adminAction'],
        orElse: () => AdminAction.none,
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
    String? reportedUserName,
    String? reportedUserPhoto,
    ReportReason? reason,
    String? description,
    List<String>? evidenceImages,
    ReportStatus? status,
    AdminAction? adminAction,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminNotes,
    String? adminId,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      reportedUserPhoto: reportedUserPhoto ?? this.reportedUserPhoto,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      evidenceImages: evidenceImages ?? this.evidenceImages,
      status: status ?? this.status,
      adminAction: adminAction ?? this.adminAction,
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

extension AdminActionExtension on AdminAction {
  String get displayName {
    switch (this) {
      case AdminAction.none:
        return 'No Action';
      case AdminAction.warning:
        return 'Warning Issued';
      case AdminAction.tempBan7Days:
        return 'Banned for 7 Days';
      case AdminAction.permanentBan:
        return 'Permanently Banned';
      case AdminAction.accountDeleted:
        return 'Account Deleted';
    }
  }
}
