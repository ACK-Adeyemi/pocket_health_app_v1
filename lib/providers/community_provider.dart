import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/group.dart';
import '../models/thread.dart';
import '../models/comment.dart';
import '../models/report.dart';
import '../models/user_profile.dart';
import '../widgets/search_filter_bar.dart';

/// Community provider for managing forum state and operations
class CommunityProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  List<Group> _groups = [];
  List<Thread> _threads = [];
  List<Comment> _comments = [];
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _currentUser;

  // Getters
  List<Group> get groups => _groups;
  List<Thread> get threads => _threads;
  List<Comment> get comments => _comments;
  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get currentUser => _currentUser;

  // Salt for anonymous ID generation (should be from secure config)
  static const String _anonymousSalt = 'pocket_health_anonymous_salt_2025';

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Set current user for role-based operations
  void setCurrentUser(UserProfile user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Generate anonymous ID for user
  String generateAnonymousId(String userId) {
    final key = utf8.encode(_anonymousSalt);
    final bytes = utf8.encode(userId);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString().substring(0, 16); // First 16 chars for display
  }

  /// Initialize community data
  Future<void> initializeCommunity() async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.wait([
        _loadGroups(),
        _loadReportsIfModerator(),
      ]);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to initialize community: ${e.toString()}');
    }
  }

  /// Load all available groups
  Future<void> _loadGroups() async {
    try {
      final snapshot = await _firestore.collection('groups').get();
      _groups = snapshot.docs.map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load groups: ${e.toString()}');
    }
  }

  /// Load groups accessible to current user based on their health conditions
  Future<void> loadUserGroups() async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);

      // Get user's health condition categories
      final userCategories = _currentUser!.healthConditions
          .map((condition) => condition.category ?? 'general')
          .toSet();

      // Query groups that match user's conditions or are general
      final snapshot = await _firestore
          .collection('groups')
          .where('isActive', isEqualTo: true)
          .get();

      _groups = snapshot.docs
          .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>))
          .where((group) =>
              userCategories.contains(group.category) ||
              group.category == 'general' ||
              _currentUser!.role != UserRole.user) // Admins/mods see all
          .toList();

      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load user groups: ${e.toString()}');
    }
  }

  /// Load threads for a specific group
  Future<void> loadThreadsForGroup(String groupId) async {
    try {
      _setLoading(true);

      // Try the optimized query first
      final snapshot = await _firestore
          .collection('threads')
          .where('groupId', isEqualTo: groupId)
          .where('isArchived', isEqualTo: false)
          .orderBy('lastActivityAt', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.isEmpty) {
        // Fallback for cases where index isn't ready or fields are missing
        final simpleSnapshot = await _firestore
            .collection('threads')
            .where('groupId', isEqualTo: groupId)
            .get();
        
        _threads = simpleSnapshot.docs
            .map((doc) => Thread.fromMap(doc.data()))
            .where((t) => !t.isArchived)
            .toList();
      } else {
        _threads = snapshot.docs
            .map((doc) => Thread.fromMap(doc.data()))
            .toList();
      }

      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load threads: ${e.toString()}');
    }
  }

  /// Load comments for a specific thread
  Future<void> loadCommentsForThread(String threadId) async {
    try {
      _setLoading(true);

      final snapshot = await _firestore
          .collection('comments')
          .where('threadId', isEqualTo: threadId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .get();

      _comments = snapshot.docs
          .map((doc) => Comment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load comments: ${e.toString()}');
    }
  }

  /// Create a new thread
  Future<bool> createThread({
    required String groupId,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    if (_currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final threadId = _firestore.collection('threads').doc().id;
      final anonymousId = generateAnonymousId(_currentUser!.uid);
      final now = DateTime.now();

      final thread = Thread(
        id: threadId,
        groupId: groupId,
        authorId: _currentUser!.uid,
        anonymousId: anonymousId,
        title: title,
        content: content,
        tags: tags,
        createdAt: now,
        updatedAt: now,
        lastActivityAt: now,
      );

      await _firestore.collection('threads').doc(threadId).set(thread.toMap());

      // Update group thread count
      await _updateGroupThreadCount(groupId, 1);

      // Add to local list and ensure state is updated
      _threads = [thread, ..._threads];
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to create thread: ${e.toString()}');
      return false;
    }
  }

  /// Create a new comment
  Future<bool> createComment({
    required String threadId,
    required String content,
    String? parentCommentId,
  }) async {
    if (_currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final commentId = _firestore.collection('comments').doc().id;
      final anonymousId = generateAnonymousId(_currentUser!.uid);
      final now = DateTime.now();

      final comment = Comment(
        id: commentId,
        threadId: threadId,
        authorId: _currentUser!.uid,
        anonymousId: anonymousId,
        content: content,
        parentCommentId: parentCommentId,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('comments').doc(commentId).set(comment.toMap());

      // Update thread comment count and activity
      await _updateThreadCommentCount(threadId, 1);

      _comments.add(comment);
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to create comment: ${e.toString()}');
      return false;
    }
  }

  /// Toggle like/dislike on content
  Future<bool> toggleVote({
    required String contentId,
    required String contentType, // 'thread' or 'comment'
    required bool isLike,
  }) async {
    if (_currentUser == null) return false;

    try {
      final collection = contentType == 'thread' ? 'threads' : 'comments';
      final userVoteRef = _firestore
          .collection(collection)
          .doc(contentId)
          .collection('votes')
          .doc(_currentUser!.uid);

      final existingVote = await userVoteRef.get();

      if (existingVote.exists) {
        final currentVote = existingVote.data()?['isLike'] as bool?;
        if (currentVote == isLike) {
          // Remove vote
          await userVoteRef.delete();
          await _updateVoteCount(contentId, collection, isLike, -1);
        } else {
          // Change vote
          await userVoteRef.update({'isLike': isLike});
          await _updateVoteCount(contentId, collection, currentVote!, -1);
          await _updateVoteCount(contentId, collection, isLike, 1);
        }
      } else {
        // Add new vote
        await userVoteRef.set({
          'userId': _currentUser!.uid,
          'isLike': isLike,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _updateVoteCount(contentId, collection, isLike, 1);
      }

      return true;
    } catch (e) {
      _setError('Failed to update vote: ${e.toString()}');
      return false;
    }
  }

  /// Report inappropriate content
  Future<bool> reportContent({
    required String contentId,
    required String contentType,
    required String groupId,
    required ReportCategory category,
    required String description,
    bool isAnonymous = true,
  }) async {
    if (_currentUser == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      final reportId = _firestore.collection('reports').doc().id;
      final now = DateTime.now();

      final report = Report(
        id: reportId,
        reporterId: _currentUser!.uid,
        reportedUserId: '', // Will be filled when content is retrieved
        contentId: contentId,
        contentType: contentType,
        groupId: groupId,
        category: category,
        description: description,
        createdAt: now,
        updatedAt: now,
        isAnonymous: isAnonymous,
      );

      await _firestore.collection('reports').doc(reportId).set(report.toMap());

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to submit report: ${e.toString()}');
      return false;
    }
  }

  /// Load reports for moderators
  Future<void> _loadReportsIfModerator() async {
    if (_currentUser == null ||
        (_currentUser!.role != UserRole.moderator && _currentUser!.role != UserRole.admin)) {
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: ReportStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      _reports = snapshot.docs
          .map((doc) => Report.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load reports: ${e.toString()}');
    }
  }

  /// Helper method to update group thread count
  Future<void> _updateGroupThreadCount(String groupId, int increment) async {
    await _firestore.collection('groups').doc(groupId).update({
      'threadCount': FieldValue.increment(increment),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Helper method to update thread comment count and activity
  Future<void> _updateThreadCommentCount(String threadId, int increment) async {
    await _firestore.collection('threads').doc(threadId).update({
      'commentCount': FieldValue.increment(increment),
      'lastActivityAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Helper method to update vote counts
  Future<void> _updateVoteCount(String contentId, String collection, bool isLike, int increment) async {
    final field = isLike ? 'likeCount' : 'dislikeCount';
    await _firestore.collection(collection).doc(contentId).update({
      field: FieldValue.increment(increment),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Archive a thread
  Future<bool> archiveThread(String threadId) async {
    try {
      await _firestore.collection('threads').doc(threadId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _threads.removeWhere((t) => t.id == threadId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to archive thread: ${e.toString()}');
      return false;
    }
  }

  /// Delete a comment (soft delete)
  Future<bool> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete comment: ${e.toString()}');
      return false;
    }
  }

  /// Update a thread
  Future<bool> updateThread(String threadId, String title, String content, List<String> tags) async {
    try {
      await _firestore.collection('threads').doc(threadId).update({
        'title': title,
        'content': content,
        'tags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final index = _threads.indexWhere((t) => t.id == threadId);
      if (index != -1) {
        _threads[index] = _threads[index].copyWith(
          title: title,
          content: content,
          tags: tags,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update thread: ${e.toString()}');
      return false;
    }
  }

  /// Update a comment
  Future<bool> updateComment(String commentId, String content) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'content': content,
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = _comments[index].copyWith(
          content: content,
          isEdited: true,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update comment: ${e.toString()}');
      return false;
    }
  }

  /// Search threads across all groups or within a specific group
  Future<void> searchThreads({
    String query = '',
    String? groupId,
    SortOption sortBy = SortOption.newest,
    FilterOption filterBy = FilterOption.all,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      _setError(null);

      Query queryRef = _firestore.collection('threads');

      // Apply group filter if specified
      if (groupId != null) {
        queryRef = queryRef.where('groupId', isEqualTo: groupId);
      }

      // Apply user-based filtering for access control
      if (_currentUser!.role == UserRole.user) {
        final userCategories = _currentUser!.healthConditions
            .map((condition) => condition.category ?? 'general')
            .toSet();

        // Get groups user can access
        final groupsSnapshot = await _firestore
            .collection('groups')
            .where('isActive', isEqualTo: true)
            .get();

        final accessibleGroupIds = groupsSnapshot.docs
            .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>))
            .where((group) =>
                userCategories.contains(group.category) ||
                group.category == 'general')
            .map((group) => group.id)
            .toList();

        queryRef = queryRef.where('groupId', whereIn: accessibleGroupIds);
      }

      // Apply archive filter
      queryRef = queryRef.where('isArchived', isEqualTo: false);

      // Apply user-specific filters
      if (filterBy == FilterOption.myPosts && _currentUser != null) {
        queryRef = queryRef.where('authorId', isEqualTo: _currentUser!.uid);
      }

      // Apply sorting
      switch (sortBy) {
        case SortOption.newest:
          queryRef = queryRef.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldest:
          queryRef = queryRef.orderBy('createdAt', descending: false);
          break;
        case SortOption.popular:
          queryRef = queryRef.orderBy('likeCount', descending: true);
          break;
        case SortOption.mostCommented:
          queryRef = queryRef.orderBy('commentCount', descending: true);
          break;
        case SortOption.recentlyActive:
          queryRef = queryRef.orderBy('lastActivityAt', descending: true);
          break;
      }

      // Execute query
      final snapshot = await queryRef.limit(100).get();

      List<Thread> results = snapshot.docs
          .map((doc) => Thread.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply text search if query is provided
      if (query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        results = results.where((thread) {
          return thread.title.toLowerCase().contains(searchTerm) ||
                 thread.content.toLowerCase().contains(searchTerm) ||
                 thread.tags.any((tag) => tag.toLowerCase().contains(searchTerm));
        }).toList();
      }

      // Apply additional filters
      if (filterBy == FilterOption.unanswered) {
        results = results.where((thread) => thread.commentCount == 0).toList();
      }

      _threads = results;
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to search threads: ${e.toString()}');
    }
  }

  /// Search groups by name or description
  Future<void> searchGroups(String query) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);

      Query queryRef = _firestore.collection('groups').where('isActive', isEqualTo: true);

      // Apply user access control
      if (_currentUser!.role == UserRole.user) {
        final userCategories = _currentUser!.healthConditions
            .map((condition) => condition.category ?? 'general')
            .toSet();

        // For search, we'll load all and filter client-side for better search experience
        final snapshot = await queryRef.get();
        List<Group> allGroups = snapshot.docs
            .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        // Filter by user access
        allGroups = allGroups.where((group) =>
            userCategories.contains(group.category) ||
            group.category == 'general').toList();

        // Apply search query
        if (query.isNotEmpty) {
          final searchTerm = query.toLowerCase();
          allGroups = allGroups.where((group) {
            return group.name.toLowerCase().contains(searchTerm) ||
                   group.description.toLowerCase().contains(searchTerm) ||
                   group.category.toLowerCase().contains(searchTerm);
          }).toList();
        }

        _groups = allGroups;
      } else {
        // Admins/mods can search all groups
        if (query.isNotEmpty) {
          // Note: Firestore doesn't support text search natively
          // For production, consider using Algolia or ElasticSearch
          final snapshot = await queryRef.get();
          final searchTerm = query.toLowerCase();
          _groups = snapshot.docs
              .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>))
              .where((group) {
                return group.name.toLowerCase().contains(searchTerm) ||
                       group.description.toLowerCase().contains(searchTerm) ||
                       group.category.toLowerCase().contains(searchTerm);
              })
              .toList();
        } else {
          await _loadGroups();
        }
      }

      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to search groups: ${e.toString()}');
    }
  }

  /// Get popular tags across all threads
  Future<List<String>> getPopularTags({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('threads')
          .where('isArchived', isEqualTo: false)
          .get();

      final tagCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final thread = Thread.fromMap(doc.data() as Map<String, dynamic>);
        for (final tag in thread.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Sort by frequency and return top tags
      final sortedTags = tagCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      _setError('Failed to load popular tags: ${e.toString()}');
      return [];
    }
  }

  /// Get threads by tag
  Future<void> getThreadsByTag(String tag, {String? groupId}) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);

      Query queryRef = _firestore
          .collection('threads')
          .where('tags', arrayContains: tag)
          .where('isArchived', isEqualTo: false)
          .orderBy('lastActivityAt', descending: true);

      if (groupId != null) {
        queryRef = queryRef.where('groupId', isEqualTo: groupId);
      }

      final snapshot = await queryRef.limit(50).get();

      _threads = snapshot.docs
          .map((doc) => Thread.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load threads by tag: ${e.toString()}');
    }
  }

  /// Advanced search with multiple filters
  Future<void> advancedSearch({
    String? query,
    String? groupId,
    String? tag,
    SortOption sortBy = SortOption.newest,
    FilterOption filterBy = FilterOption.all,
    DateTime? startDate,
    DateTime? endDate,
    int? minLikes,
    int? minComments,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      _setError(null);

      // Start with base query
      Query queryRef = _firestore.collection('threads');

      // Apply group filter
      if (groupId != null) {
        queryRef = queryRef.where('groupId', isEqualTo: groupId);
      }

      // Apply tag filter
      if (tag != null) {
        queryRef = queryRef.where('tags', arrayContains: tag);
      }

      // Apply archive filter
      queryRef = queryRef.where('isArchived', isEqualTo: false);

      // Apply user-specific filters
      if (filterBy == FilterOption.myPosts && _currentUser != null) {
        queryRef = queryRef.where('authorId', isEqualTo: _currentUser!.uid);
      }

      // Apply sorting
      switch (sortBy) {
        case SortOption.newest:
          queryRef = queryRef.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldest:
          queryRef = queryRef.orderBy('createdAt', descending: false);
          break;
        case SortOption.popular:
          queryRef = queryRef.orderBy('likeCount', descending: true);
          break;
        case SortOption.mostCommented:
          queryRef = queryRef.orderBy('commentCount', descending: true);
          break;
        case SortOption.recentlyActive:
          queryRef = queryRef.orderBy('lastActivityAt', descending: true);
          break;
      }

      // Execute query
      final snapshot = await queryRef.limit(100).get();

      List<Thread> results = snapshot.docs
          .map((doc) => Thread.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply client-side filters
      if (query != null && query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        results = results.where((thread) {
          return thread.title.toLowerCase().contains(searchTerm) ||
                 thread.content.toLowerCase().contains(searchTerm) ||
                 thread.tags.any((tag) => tag.toLowerCase().contains(searchTerm));
        }).toList();
      }

      // Apply date filters
      if (startDate != null) {
        results = results.where((thread) => thread.createdAt.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        results = results.where((thread) => thread.createdAt.isBefore(endDate)).toList();
      }

      // Apply engagement filters
      if (minLikes != null) {
        results = results.where((thread) => thread.likeCount >= minLikes).toList();
      }
      if (minComments != null) {
        results = results.where((thread) => thread.commentCount >= minComments).toList();
      }

      // Apply additional filters
      if (filterBy == FilterOption.unanswered) {
        results = results.where((thread) => thread.commentCount == 0).toList();
      }

      _threads = results;
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to perform advanced search: ${e.toString()}');
    }
  }

  /// Clear all data
  void clearData() {
    _groups = [];
    _threads = [];
    _comments = [];
    _reports = [];
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
