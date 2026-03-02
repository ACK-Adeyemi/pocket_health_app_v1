import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/group.dart';
import '../../models/user_profile.dart';
import '../../utils/app_colors.dart';
import 'group_detail_screen.dart';
import 'moderation_dashboard_screen.dart';
import 'create_thread_dialog.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    _initializeCommunity();
  }

  Future<void> _initializeCommunity() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);

    if (userProvider.userProfile != null) {
      communityProvider.setCurrentUser(userProvider.userProfile!);
      await communityProvider.loadUserGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync UserProfile with CommunityProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      if (userProvider.userProfile != null && communityProvider.currentUser == null) {
        communityProvider.setCurrentUser(userProvider.userProfile);
        communityProvider.loadUserGroups();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
              
              // Ensure we have the latest profile before refreshing
              if (userProvider.userProfile == null) {
                await userProvider.loadUserProfile();
              }
              
              if (userProvider.userProfile != null) {
                communityProvider.setCurrentUser(userProvider.userProfile);
                await communityProvider.loadUserGroups(source: Source.server);
              }
            },
          ),
          Consumer<CommunityProvider>(
            builder: (context, provider, child) {
              final user = provider.currentUser;
              if (user != null && (user.role == UserRole.moderator || user.role == UserRole.admin)) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModerationDashboardScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<UserProvider, CommunityProvider>(
        builder: (context, userProvider, communityProvider, child) {
          if (userProvider.isLoading || communityProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (communityProvider.errorMessage != null) {
            return _buildErrorState(communityProvider);
          }

          if (userProvider.userProfile == null) {
            return _buildNotAuthenticated();
          }

          if (communityProvider.groups.isEmpty) {
            return _buildEmptyState();
          }

          return _buildGroupList(communityProvider.groups);
        },
      ),
      floatingActionButton: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.currentUser == null || provider.groups.isEmpty) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            onPressed: () {
              if (provider.groups.length == 1) {
                showDialog(
                  context: context,
                  builder: (context) => CreateThreadDialog(group: provider.groups.first),
                );
              } else {
                _showGroupSelectionDialog(context, provider.groups);
              }
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildNotAuthenticated() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Sign in to join the community',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Connect with others who share similar health experiences',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to login
            },
            child: const Text('Sign In'),
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
            Icons.groups_outlined,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No groups available',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Groups will be available based on your health conditions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(List<Group> groups) {
    return RefreshIndicator(
      onRefresh: () async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
        
        if (userProvider.userProfile == null) {
          await userProvider.loadUserProfile();
        }
        
        if (userProvider.userProfile != null) {
          communityProvider.setCurrentUser(userProvider.userProfile);
          await communityProvider.loadUserGroups(source: Source.server);
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(group: group),
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
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.group,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          group.category.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                group.description,
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
                    '${group.memberCount} members',
                  ),
                  SizedBox(width: 16.w),
                  _buildStatItem(
                    Icons.forum_outlined,
                    '${group.threadCount} discussions',
                  ),
                ],
              ),
            ],
          ),
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
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
            'Error loading communities',
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
                await provider.loadUserGroups(source: Source.server);
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

  void _showGroupSelectionDialog(BuildContext context, List<Group> groups) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Group'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: const Icon(Icons.group),
                title: Text(group.name),
                subtitle: Text(group.category),
                onTap: () {
                  Navigator.pop(context); // Close selection dialog
                  showDialog(
                    context: context,
                    builder: (context) => CreateThreadDialog(group: group),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
