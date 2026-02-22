import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a comment/reply within a thread
class Comment {
  final String id;
  final String threadId;
  final String authorId;
  final String anonymousId; // SHA-256 hash for display
  final String content;
  final String? parentCommentId; // For nested replies
  final List<String> mentionedUserIds; // For @ mentions
  final int likeCount;
  final int dislikeCount;
  final bool isEdited;
  final bool isDeleted;
  final bool isModerated;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? moderatorAction; // 'approved', 'edited', 'removed'
  final String? moderatorNote;

  Comment({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.anonymousId,
    required this.content,
    this.parentCommentId,
    this.mentionedUserIds = const [],
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.isEdited = false,
    this.isDeleted = false,
    this.isModerated = false,
    required this.createdAt,
    required this.updatedAt,
    this.moderatorAction,
    this.moderatorNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'threadId': threadId,
      'authorId': authorId,
      'anonymousId': anonymousId,
      'content': content,
      'parentCommentId': parentCommentId,
      'mentionedUserIds': mentionedUserIds,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isModerated': isModerated,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'moderatorAction': moderatorAction,
      'moderatorNote': moderatorNote,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      threadId: map['threadId'] ?? '',
      authorId: map['authorId'] ?? '',
      anonymousId: map['anonymousId'] ?? '',
      content: map['content'] ?? '',
      parentCommentId: map['parentCommentId'],
      mentionedUserIds: List<String>.from(map['mentionedUserIds'] ?? []),
      likeCount: map['likeCount']?.toInt() ?? 0,
      dislikeCount: map['dislikeCount']?.toInt() ?? 0,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      isModerated: map['isModerated'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      moderatorAction: map['moderatorAction'],
      moderatorNote: map['moderatorNote'],
    );
  }

  Comment copyWith({
    String? id,
    String? threadId,
    String? authorId,
    String? anonymousId,
    String? content,
    String? parentCommentId,
    List<String>? mentionedUserIds,
    int? likeCount,
    int? dislikeCount,
    bool? isEdited,
    bool? isDeleted,
    bool? isModerated,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? moderatorAction,
    String? moderatorNote,
  }) {
    return Comment(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      authorId: authorId ?? this.authorId,
      anonymousId: anonymousId ?? this.anonymousId,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isModerated: isModerated ?? this.isModerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderatorAction: moderatorAction ?? this.moderatorAction,
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

  // Check if this is a top-level comment (not a reply)
  bool get isTopLevel => parentCommentId == null;

  // Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;

  // Get the net score (likes - dislikes)
  int get netScore => likeCount - dislikeCount;

  // Check if comment is visible to regular users
  bool get isVisible {
    if (isDeleted) return false;
    if (isModerated && moderatorAction == 'removed') return false;
    return true;
  }

  // Get display content (show moderation message if needed)
  String get displayContent {
    if (isDeleted) {
      return '[Comment deleted]';
    }
    if (isModerated && moderatorAction == 'removed') {
      return '[Comment removed by moderator]';
    }
    return content;
  }

  // Check if comment contains mentions
  bool get hasMentions => mentionedUserIds.isNotEmpty;

  // Get moderation status for display
  String get moderationStatus {
    if (isDeleted) return 'deleted';
    if (isModerated) {
      return moderatorAction ?? 'moderated';
    }
    return 'active';
  }

  @override
  String toString() {
    return 'Comment(id: $id, threadId: $threadId, author: $anonymousId, likes: $likeCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
