import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a discussion thread within a community group
class Thread {
  final String id;
  final String groupId;
  final String authorId;
  final String anonymousId; // SHA-256 hash for display
  final String title;
  final String content;
  final List<String> tags;
  final int viewCount;
  final int commentCount;
  final int likeCount;
  final int dislikeCount;
  final bool isArchived;
  final bool isPinned;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;
  final String? moderatorNote;

  Thread({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.anonymousId,
    required this.title,
    required this.content,
    this.tags = const [],
    this.viewCount = 0,
    this.commentCount = 0,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.isArchived = false,
    this.isPinned = false,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
    this.moderatorNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'authorId': authorId,
      'anonymousId': anonymousId,
      'title': title,
      'content': content,
      'tags': tags,
      'viewCount': viewCount,
      'commentCount': commentCount,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'isLocked': isLocked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActivityAt': lastActivityAt != null ? Timestamp.fromDate(lastActivityAt!) : null,
      'moderatorNote': moderatorNote,
    };
  }

  factory Thread.fromMap(Map<String, dynamic> map) {
    return Thread(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      authorId: map['authorId'] ?? '',
      anonymousId: map['anonymousId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      viewCount: map['viewCount']?.toInt() ?? 0,
      commentCount: map['commentCount']?.toInt() ?? 0,
      likeCount: map['likeCount']?.toInt() ?? 0,
      dislikeCount: map['dislikeCount']?.toInt() ?? 0,
      isArchived: map['isArchived'] ?? false,
      isPinned: map['isPinned'] ?? false,
      isLocked: map['isLocked'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      lastActivityAt: map['lastActivityAt'] != null ? _parseDateTime(map['lastActivityAt']) : null,
      moderatorNote: map['moderatorNote'],
    );
  }

  Thread copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? anonymousId,
    String? title,
    String? content,
    List<String>? tags,
    int? viewCount,
    int? commentCount,
    int? likeCount,
    int? dislikeCount,
    bool? isArchived,
    bool? isPinned,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
    String? moderatorNote,
  }) {
    return Thread(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      authorId: authorId ?? this.authorId,
      anonymousId: anonymousId ?? this.anonymousId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      moderatorNote: moderatorNote ?? this.moderatorNote,
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

  // Calculate engagement score for sorting
  double get engagementScore {
    final ageInHours = DateTime.now().difference(createdAt).inHours;
    final engagement = (likeCount * 2) + (commentCount * 3) + (viewCount * 0.1);
    // Boost recent threads, decay older ones
    return engagement / (ageInHours + 2.0);
  }

  // Check if thread is active (has recent activity)
  bool get isActive {
    if (lastActivityAt == null) return false;
    final daysSinceActivity = DateTime.now().difference(lastActivityAt!).inDays;
    return daysSinceActivity <= 30; // Consider active if activity within 30 days
  }

  // Get thread status for display
  String get status {
    if (isPinned) return 'pinned';
    if (isLocked) return 'locked';
    if (isArchived) return 'archived';
    return 'active';
  }

  @override
  String toString() {
    return 'Thread(id: $id, title: $title, groupId: $groupId, comments: $commentCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Thread && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
