import 'package:flutter_test/flutter_test.dart';
import '../lib/models/group.dart';
import '../lib/models/thread.dart';
import '../lib/models/comment.dart';
import '../lib/models/report.dart';
import '../lib/models/user_profile.dart';

void main() {
  group('Community Models Tests', () {
    group('Group Model', () {
      test('should create Group from map correctly', () {
        final map = {
          'id': 'test-group',
          'name': 'Test Group',
          'description': 'A test group',
          'category': 'chronic',
          'memberCount': 10,
          'threadCount': 5,
          'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2025, 1, 2).toIso8601String(),
          'isActive': true,
          'moderatorId': 'mod-123',
        };

        final group = Group.fromMap(map);

        expect(group.id, 'test-group');
        expect(group.name, 'Test Group');
        expect(group.description, 'A test group');
        expect(group.category, 'chronic');
        expect(group.memberCount, 10);
        expect(group.threadCount, 5);
        expect(group.isActive, true);
        expect(group.moderatorId, 'mod-123');
      });

      test('should convert Group to map correctly', () {
        final group = Group(
          id: 'test-group',
          name: 'Test Group',
          description: 'A test group',
          category: 'chronic',
          memberCount: 10,
          threadCount: 5,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          isActive: true,
          moderatorId: 'mod-123',
        );

        final map = group.toMap();

        expect(map['id'], 'test-group');
        expect(map['name'], 'Test Group');
        expect(map['description'], 'A test group');
        expect(map['category'], 'chronic');
        expect(map['memberCount'], 10);
        expect(map['threadCount'], 5);
        expect(map['isActive'], true);
        expect(map['moderatorId'], 'mod-123');
      });
    });

    group('Thread Model', () {
      test('should create Thread from map correctly', () {
        final map = {
          'id': 'test-thread',
          'groupId': 'test-group',
          'authorId': 'user-123',
          'anonymousId': 'abc123',
          'title': 'Test Thread',
          'content': 'Thread content',
          'tags': ['tag1', 'tag2'],
          'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2025, 1, 2).toIso8601String(),
          'lastActivityAt': DateTime(2025, 1, 3).toIso8601String(),
          'likeCount': 5,
          'dislikeCount': 1,
          'commentCount': 3,
          'isArchived': false,
          'isPinned': false,
        };

        final thread = Thread.fromMap(map);

        expect(thread.id, 'test-thread');
        expect(thread.groupId, 'test-group');
        expect(thread.authorId, 'user-123');
        expect(thread.anonymousId, 'abc123');
        expect(thread.title, 'Test Thread');
        expect(thread.content, 'Thread content');
        expect(thread.tags, ['tag1', 'tag2']);
        expect(thread.likeCount, 5);
        expect(thread.dislikeCount, 1);
        expect(thread.commentCount, 3);
        expect(thread.isArchived, false);
        expect(thread.isPinned, false);
      });

      test('should convert Thread to map correctly', () {
        final thread = Thread(
          id: 'test-thread',
          groupId: 'test-group',
          authorId: 'user-123',
          anonymousId: 'abc123',
          title: 'Test Thread',
          content: 'Thread content',
          tags: ['tag1', 'tag2'],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          lastActivityAt: DateTime(2025, 1, 3),
          likeCount: 5,
          dislikeCount: 1,
          commentCount: 3,
          isArchived: false,
          isPinned: false,
        );

        final map = thread.toMap();

        expect(map['id'], 'test-thread');
        expect(map['groupId'], 'test-group');
        expect(map['authorId'], 'user-123');
        expect(map['anonymousId'], 'abc123');
        expect(map['title'], 'Test Thread');
        expect(map['content'], 'Thread content');
        expect(map['tags'], ['tag1', 'tag2']);
        expect(map['likeCount'], 5);
        expect(map['dislikeCount'], 1);
        expect(map['commentCount'], 3);
        expect(map['isArchived'], false);
        expect(map['isPinned'], false);
      });
    });

    group('Comment Model', () {
      test('should create Comment from map correctly', () {
        final map = {
          'id': 'test-comment',
          'threadId': 'test-thread',
          'authorId': 'user-123',
          'anonymousId': 'abc123',
          'content': 'Comment content',
          'parentCommentId': 'parent-123',
          'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2025, 1, 2).toIso8601String(),
          'likeCount': 2,
          'dislikeCount': 0,
          'isDeleted': false,
          'isModerated': false,
        };

        final comment = Comment.fromMap(map);

        expect(comment.id, 'test-comment');
        expect(comment.threadId, 'test-thread');
        expect(comment.authorId, 'user-123');
        expect(comment.anonymousId, 'abc123');
        expect(comment.content, 'Comment content');
        expect(comment.parentCommentId, 'parent-123');
        expect(comment.likeCount, 2);
        expect(comment.dislikeCount, 0);
        expect(comment.isDeleted, false);
        expect(comment.isModerated, false);
      });

      test('should convert Comment to map correctly', () {
        final comment = Comment(
          id: 'test-comment',
          threadId: 'test-thread',
          authorId: 'user-123',
          anonymousId: 'abc123',
          content: 'Comment content',
          parentCommentId: 'parent-123',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          likeCount: 2,
          dislikeCount: 0,
          isDeleted: false,
          isModerated: false,
        );

        final map = comment.toMap();

        expect(map['id'], 'test-comment');
        expect(map['threadId'], 'test-thread');
        expect(map['authorId'], 'user-123');
        expect(map['anonymousId'], 'abc123');
        expect(map['content'], 'Comment content');
        expect(map['parentCommentId'], 'parent-123');
        expect(map['likeCount'], 2);
        expect(map['dislikeCount'], 0);
        expect(map['isDeleted'], false);
        expect(map['isModerated'], false);
      });
    });

    group('Report Model', () {
      test('should create Report from map correctly', () {
        final map = {
          'id': 'test-report',
          'reporterId': 'user-123',
          'reportedUserId': 'user-456',
          'contentId': 'content-123',
          'contentType': 'thread',
          'groupId': 'group-123',
          'category': 'unprofessionalConduct',
          'description': 'Report description',
          'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2025, 1, 2).toIso8601String(),
          'status': 'pending',
          'moderatorId': 'mod-123',
          'moderatorAction': 'dismissed',
          'moderatorNote': 'Note from moderator',
          'resolvedAt': DateTime(2025, 1, 3).toIso8601String(),
          'isAnonymous': true,
        };

        final report = Report.fromMap(map);

        expect(report.id, 'test-report');
        expect(report.reporterId, 'user-123');
        expect(report.reportedUserId, 'user-456');
        expect(report.contentId, 'content-123');
        expect(report.contentType, 'thread');
        expect(report.groupId, 'group-123');
        expect(report.category, ReportCategory.unprofessionalConduct);
        expect(report.description, 'Report description');
        expect(report.status, ReportStatus.pending);
        expect(report.moderatorId, 'mod-123');
        expect(report.moderatorAction, 'dismissed');
        expect(report.moderatorNote, 'Note from moderator');
        expect(report.isAnonymous, true);
      });

      test('should convert Report to map correctly', () {
        final report = Report(
          id: 'test-report',
          reporterId: 'user-123',
          reportedUserId: 'user-456',
          contentId: 'content-123',
          contentType: 'thread',
          groupId: 'group-123',
          category: ReportCategory.unprofessionalConduct,
          description: 'Report description',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          status: ReportStatus.pending,
          moderatorId: 'mod-123',
          moderatorAction: 'dismissed',
          moderatorNote: 'Note from moderator',
          resolvedAt: DateTime(2025, 1, 3),
          isAnonymous: true,
        );

        final map = report.toMap();

        expect(map['id'], 'test-report');
        expect(map['reporterId'], 'user-123');
        expect(map['reportedUserId'], 'user-456');
        expect(map['contentId'], 'content-123');
        expect(map['contentType'], 'thread');
        expect(map['groupId'], 'group-123');
        expect(map['category'], 'unprofessionalConduct');
        expect(map['description'], 'Report description');
        expect(map['status'], 'pending');
        expect(map['moderatorId'], 'mod-123');
        expect(map['moderatorAction'], 'dismissed');
        expect(map['moderatorNote'], 'Note from moderator');
        expect(map['isAnonymous'], true);
      });

      test('should handle ReportCategory enum conversion', () {
        expect(ReportCategory.medicalMisinformation.name, 'medicalMisinformation');
        expect(ReportCategory.unprofessionalConduct.name, 'unprofessionalConduct');
        expect(ReportCategory.spamCommercial.name, 'spamCommercial');
        expect(ReportCategory.privacyViolation.name, 'privacyViolation');
        expect(ReportCategory.selfHarm.name, 'selfHarm');
        expect(ReportCategory.other.name, 'other');
      });

      test('should handle ReportStatus enum conversion', () {
        expect(ReportStatus.pending.name, 'pending');
        expect(ReportStatus.resolved.name, 'resolved');
        expect(ReportStatus.dismissed.name, 'dismissed');
      });
    });

    group('UserProfile Model', () {
      test('should create UserProfile from map correctly', () {
        final map = {
          'uid': 'user-123',
          'email': 'user@example.com',
          'name': 'John Doe',
          'role': 'user',
          'anonymousId': 'abc123',
          'isHealthcareProfessional': false,
          'healthConditions': [
            {'id': 'cond1', 'name': 'Diabetes', 'category': 'chronic'},
            {'id': 'cond2', 'name': 'Hypertension', 'category': 'chronic'},
          ],
          'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2025, 1, 2).toIso8601String(),
          'age': 30,
          'height': 175.0,
          'weight': 70.0,
          'heightUnit': 'cm',
          'weightUnit': 'kg',
        };

        final user = UserProfile.fromMap(map);

        expect(user.uid, 'user-123');
        expect(user.email, 'user@example.com');
        expect(user.name, 'John Doe');
        expect(user.role, UserRole.user);
        expect(user.anonymousId, 'abc123');
        expect(user.isHealthcareProfessional, false);
        expect(user.healthConditions.length, 2);
        expect(user.healthConditions[0].name, 'Diabetes');
        expect(user.healthConditions[1].name, 'Hypertension');
        expect(user.age, 30);
        expect(user.height, 175.0);
        expect(user.weight, 70.0);
        expect(user.heightUnit, 'cm');
        expect(user.weightUnit, 'kg');
      });

      test('should convert UserProfile to map correctly', () {
        final user = UserProfile(
          uid: 'user-123',
          email: 'user@example.com',
          name: 'John Doe',
          role: UserRole.user,
          anonymousId: 'abc123',
          isHealthcareProfessional: false,
          healthConditions: [],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          age: 30,
          height: 175.0,
          weight: 70.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
        );

        final map = user.toMap();

        expect(map['uid'], 'user-123');
        expect(map['email'], 'user@example.com');
        expect(map['name'], 'John Doe');
        expect(map['role'], 'user');
        expect(map['anonymousId'], 'abc123');
        expect(map['isHealthcareProfessional'], false);
        expect(map['healthConditions'], isA<List>());
        expect(map['age'], 30);
        expect(map['height'], 175.0);
        expect(map['weight'], 70.0);
        expect(map['heightUnit'], 'cm');
        expect(map['weightUnit'], 'kg');
      });

      test('should handle UserRole enum conversion', () {
        expect(UserRole.user.name, 'user');
        expect(UserRole.moderator.name, 'moderator');
        expect(UserRole.admin.name, 'admin');
      });
    });
  });
}
