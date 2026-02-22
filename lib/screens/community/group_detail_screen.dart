import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../models/group.dart';
import '../../models/thread.dart';
import '../../utils/app_colors.dart';
import 'thread_detail_screen.dart';
import 'create_thread_dialog.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    await communityProvider.loadThreadsForGroup(widget.group.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group.name,
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
      ),
      body: Column(
        children: [
          _buildGroupHeader(),
          Expanded(
            child: Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.threads.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildThreadList(provider.threads);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.currentUser == null) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => CreateThreadDialog(group: widget.group),
              );
              // Refresh threads after dialog closes
              _loadThreads();
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.grey200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.group,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      widget.group.category.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            widget.group.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildStatItem(
                Icons.people_outline,
                '${widget.group.memberCount} members',
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                Icons.forum_outlined,
                '${widget.group.threadCount} discussions',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No discussions yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Be the first to start a conversation!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          Consumer<CommunityProvider>(
            builder: (context, provider, child) {
              if (provider.currentUser == null) return const SizedBox.shrink();

              return ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => CreateThreadDialog(group: widget.group),
                  );
                  // Refresh threads after dialog closes
                  _loadThreads();
                },
                icon: const Icon(Icons.add),
                label: const Text('Start Discussion'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThreadList(List<Thread> threads) {
    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _buildThreadCard(thread);
        },
      ),
    );
  }

  Widget _buildThreadCard(Thread thread) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThreadDetailScreen(thread: thread),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
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
                        thread.anonymousId.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12.sp,
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
                          thread.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'by ${thread.anonymousId}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (thread.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                thread.content,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _buildThreadStat(
                    Icons.thumb_up_outlined,
                    thread.likeCount.toString(),
                  ),
                  SizedBox(width: 16.w),
                  _buildThreadStat(
                    Icons.comment_outlined,
                    thread.commentCount.toString(),
                  ),
                  SizedBox(width: 16.w),
                  _buildThreadStat(
                    Icons.visibility_outlined,
                    thread.viewCount.toString(),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(thread.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (thread.tags.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: thread.tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreadStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
