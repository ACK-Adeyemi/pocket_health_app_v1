import 'package:cloud_firestore/cloud_firestore.dart';

/// Report categories for content moderation
enum ReportCategory {
  medicalMisinformation('Medical Misinformation', 'Inaccurate or harmful health advice'),
  privacyViolation('Privacy / HIPAA Violation', 'Sharing personal health information (PHI)'),
  unprofessionalConduct('Unprofessional Conduct', 'Harassment, bullying, or offensive language'),
  professionalImpersonation('Professional Impersonation', 'False claims of medical credentials'),
  spamCommercial('Spam or Commercial Content', 'Selling medical products or irrelevant promotion'),
  selfHarm('Self-Harm Content', 'Content promoting harmful behaviors'),
  other('Other', 'Other violation not covered above');

  const ReportCategory(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Report status for moderation workflow
enum ReportStatus {
  pending('Pending', 'Report awaiting review'),
  underReview('Under Review', 'Report being investigated'),
  resolved('Resolved', 'Report has been addressed'),
  dismissed('Dismissed', 'Report found to be invalid');

  const ReportStatus(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Represents a user report of inappropriate content
class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String contentId; // Thread or Comment ID
  final String contentType; // 'thread' or 'comment'
  final String groupId;
  final ReportCategory category;
  final String description;
  final ReportStatus status;
  final String? moderatorId;
  final String? moderatorAction; // 'approved', 'edited', 'removed', 'warned'
  final String? moderatorNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final bool isAnonymous; // Whether reporter wants to remain anonymous

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.contentId,
    required this.contentType,
    required this.groupId,
    required this.category,
    required this.description,
    this.status = ReportStatus.pending,
    this.moderatorId,
    this.moderatorAction,
    this.moderatorNote,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.isAnonymous = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'contentId': contentId,
      'contentType': contentType,
      'groupId': groupId,
      'category': category.name,
      'description': description,
      'status': status.name,
      'moderatorId': moderatorId,
      'moderatorAction': moderatorAction,
      'moderatorNote': moderatorNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'isAnonymous': isAnonymous,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      contentId: map['contentId'] ?? '',
      contentType: map['contentType'] ?? '',
      groupId: map['groupId'] ?? '',
      category: ReportCategory.values.firstWhere(
        (cat) => cat.name == map['category'],
        orElse: () => ReportCategory.other,
      ),
      description: map['description'] ?? '',
      status: ReportStatus.values.firstWhere(
        (stat) => stat.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      moderatorId: map['moderatorId'],
      moderatorAction: map['moderatorAction'],
      moderatorNote: map['moderatorNote'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      resolvedAt: map['resolvedAt'] != null ? _parseDateTime(map['resolvedAt']) : null,
      isAnonymous: map['isAnonymous'] ?? true,
    );
  }

  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? contentId,
    String? contentType,
    String? groupId,
    ReportCategory? category,
    String? description,
    ReportStatus? status,
    String? moderatorId,
    String? moderatorAction,
    String? moderatorNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    bool? isAnonymous,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      groupId: groupId ?? this.groupId,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorAction: moderatorAction ?? this.moderatorAction,
      moderatorNote: moderatorNote ?? this.moderatorNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  // Helper method to parse DateTime from Firestore
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Check if report is pending review
  bool get isPending => status == ReportStatus.pending;

  // Check if report is under review
  bool get isUnderReview => status == ReportStatus.underReview;

  // Check if report is resolved
  bool get isResolved => status == ReportStatus.resolved || status == ReportStatus.dismissed;

  // Get priority level based on category and other factors
  int get priority {
    switch (category) {
      case ReportCategory.selfHarm:
      case ReportCategory.professionalImpersonation:
        return 5; // Critical
      case ReportCategory.medicalMisinformation:
        return 4; // High
      case ReportCategory.unprofessionalConduct:
      case ReportCategory.privacyViolation:
        return 3; // Medium
      case ReportCategory.spamCommercial:
        return 2; // Low
      case ReportCategory.other:
        return 1; // Lowest
    }
  }

  // Get time since report was created
  Duration get age => DateTime.now().difference(createdAt);

  // Check if report is overdue for review (24 hours for high priority, 72 hours for others)
  bool get isOverdue {
    final hoursSinceCreation = age.inHours;
    if (priority >= 4) {
      return hoursSinceCreation > 24;
    } else {
      return hoursSinceCreation > 72;
    }
  }

  @override
  String toString() {
    return 'Report(id: $id, category: ${category.displayName}, status: ${status.displayName}, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Report && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
