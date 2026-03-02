import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/thread.dart';
import '../../models/comment.dart';
import '../../models/report.dart';
import '../../models/user_profile.dart';
import '../../utils/app_colors.dart';
import 'report_dialog.dart';

class ThreadDetailScreen extends StatefulWidget {
  final Thread thread;

  const ThreadDetailScreen({super.key, required this.thread});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({Source source = Source.serverAndCache}) async {
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    await communityProvider.loadCommentsForThread(widget.thread.id, source: source);
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);

    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    final success = await communityProvider.createComment(
      threadId: widget.thread.id,
      content: _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      await _loadComments(); // Refresh comments
    }

    setState(() => _isSubmittingComment = false);
  }

  @override
  Widget build(BuildContext context) {
    // Sync UserProfile with CommunityProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      if (userProvider.userProfile != null && communityProvider.currentUser == null) {
        communityProvider.setCurrentUser(userProvider.userProfile);
        _loadComments();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discussion',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
              
              if (userProvider.userProfile == null) {
                await userProvider.loadUserProfile();
              }
              
              if (userProvider.userProfile != null) {
                communityProvider.setCurrentUser(userProvider.userProfile);
                await _loadComments(source: Source.server);
              }
            },
          ),
          Consumer<CommunityProvider>(
            builder: (context, provider, child) {
              final user = provider.currentUser;
              final isAuthor = user?.uid == widget.thread.authorId;
              final isModerator = user?.role == UserRole.moderator || user?.role == UserRole.admin;

              if (isAuthor || isModerator) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editThread();
                    } else if (value == 'archive') {
                      _archiveThread();
                    }
                  },
                  itemBuilder: (context) => [
                    if (isAuthor)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Thread'),
                      ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive Thread'),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.flag_outlined, color: AppColors.textPrimary),
                onPressed: () => _reportThread(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.comments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return _buildErrorState(provider);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
                    
                    if (userProvider.userProfile == null) {
                      await userProvider.loadUserProfile();
                    }
                    
                    if (userProvider.userProfile != null) {
                      communityProvider.setCurrentUser(userProvider.userProfile);
                      await _loadComments(source: Source.server);
                    }
                  },
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _buildThreadContent(),
                      SizedBox(height: 24.h),
                      _buildCommentsSection(provider.comments),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildThreadContent() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Text(
                    widget.thread.anonymousId.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.thread.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          'by ${widget.thread.anonymousId}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        _buildModeratorBadge(widget.thread.authorId),
                        Text(
                          ' • ${_formatTimeAgo(widget.thread.createdAt)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.thread.isPinned)
                Icon(
                  Icons.push_pin,
                  size: 16.sp,
                  color: AppColors.primary,
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            widget.thread.content,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (widget.thread.tags.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: widget.thread.tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ],
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildInteractionButton(
                Icons.thumb_up_outlined,
                widget.thread.likeCount.toString(),
                () => _toggleVote(true),
              ),
              SizedBox(width: 16.w),
              _buildInteractionButton(
                Icons.thumb_down_outlined,
                widget.thread.dislikeCount.toString(),
                () => _toggleVote(false),
              ),
              const Spacer(),
              Text(
                '${widget.thread.commentCount} comments',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(List<Comment> comments) {
    if (comments.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Be the first to share your thoughts!',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${comments.length})',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        ...comments.map((comment) => _buildCommentCard(comment)).toList(),
      ],
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    comment.anonymousId.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.anonymousId,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (comment.isEdited) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      comment.displayContent,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildCommentInteraction(
                Icons.thumb_up_outlined,
                comment.likeCount.toString(),
                () => _toggleCommentVote(comment.id, true),
              ),
              SizedBox(width: 12.w),
              _buildCommentInteraction(
                Icons.thumb_down_outlined,
                comment.dislikeCount.toString(),
                () => _toggleCommentVote(comment.id, false),
              ),
              const Spacer(),
              Consumer<CommunityProvider>(
                builder: (context, provider, child) {
                  final user = provider.currentUser;
                  final isAuthor = user?.uid == comment.authorId;
                  final isModerator = user?.role == UserRole.moderator || user?.role == UserRole.admin;

                  if (isAuthor || isModerator) {
                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editComment(comment);
                        } else if (value == 'delete') {
                          _deleteComment(comment.id);
                        } else if (value == 'report') {
                          _reportComment(comment);
                        }
                      },
                      itemBuilder: (context) => [
                        if (isAuthor)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                        if (!isAuthor)
                          const PopupMenuItem(
                            value: 'report',
                            child: Text('Report'),
                          ),
                      ],
                    );
                  }
                  return IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    onPressed: () => _reportComment(comment),
                    color: AppColors.textSecondary,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CommunityProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading discussion details',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              provider.clearError();
              
              if (userProvider.userProfile == null) {
                await userProvider.loadUserProfile();
              }
              
              if (userProvider.userProfile != null) {
                provider.setCurrentUser(userProvider.userProfile);
                await _loadComments(source: Source.server);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.currentUser == null) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.grey200, width: 1),
              ),
            ),
            child: Center(
              child: Text(
                'Sign in to join the conversation',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.grey200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: _isSubmittingComment ? null : _submitComment,
                icon: _isSubmittingComment
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                color: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractionButton(IconData icon, String count, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 4.w),
            Text(
              count,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInteraction(IconData icon, String count, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 2.w),
            Text(
              count,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _toggleVote(bool isLike) async {
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    await communityProvider.toggleVote(
      contentId: widget.thread.id,
      contentType: 'thread',
      isLike: isLike,
    );
  }

  Future<void> _toggleCommentVote(String commentId, bool isLike) async {
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    await communityProvider.toggleVote(
      contentId: commentId,
      contentType: 'comment',
      isLike: isLike,
    );
  }

  Future<void> _reportComment(Comment comment) async {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        contentId: comment.id,
        contentType: 'comment',
        groupId: widget.thread.groupId,
      ),
    );
  }

  Future<void> _reportThread() async {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        contentId: widget.thread.id,
        contentType: 'thread',
        groupId: widget.thread.groupId,
      ),
    );
  }

  Future<void> _archiveThread() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Thread'),
        content: const Text('Are you sure you want to archive this thread? It will no longer be visible in the group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      final success = await communityProvider.archiveThread(widget.thread.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thread archived')));
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      final success = await communityProvider.deleteComment(commentId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment deleted')));
        _loadComments();
      }
    }
  }

  Future<void> _editThread() async {
    final titleController = TextEditingController(text: widget.thread.title);
    final contentController = TextEditingController(text: widget.thread.content);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Thread'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      await communityProvider.updateThread(
        widget.thread.id,
        titleController.text,
        contentController.text,
        widget.thread.tags,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thread updated')));
        // In a real app, we'd refresh the thread data or use a stream
      }
    }
  }

  Future<void> _editComment(Comment comment) async {
    final contentController = TextEditingController(text: comment.content);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: contentController,
          decoration: const InputDecoration(labelText: 'Comment'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      await communityProvider.updateComment(comment.id, contentController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment updated')));
        _loadComments();
      }
    }
  }

  Widget _buildModeratorBadge(String userId) {
    // In a real app, we'd check the user's role from a cached list or provider
    // For now, we'll use a placeholder logic or assume the provider has this info
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        // This is a simplified check. In production, you'd want to fetch the author's role.
        // For this demo, we'll show the badge if the author is the current user and is a mod/admin
        final currentUser = provider.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          if (currentUser.role == UserRole.admin) {
            return _badge('ADMIN', Colors.red);
          } else if (currentUser.role == UserRole.moderator) {
            return _badge('MOD', Colors.green);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
