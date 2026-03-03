import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/report.dart';
import '../../utils/app_colors.dart';

class ModerationDashboardScreen extends StatefulWidget {
  const ModerationDashboardScreen({super.key});

  @override
  State<ModerationDashboardScreen> createState() => _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends State<ModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync UserProfile with CommunityProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      if (userProvider.userProfile != null && communityProvider.currentUser == null) {
        communityProvider.setCurrentUser(userProvider.userProfile);
        communityProvider.refreshReports();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Moderation Dashboard',
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
                await communityProvider.refreshReports(source: Source.server);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Analytics'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildAnalyticsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.reports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return _buildErrorState(provider);
        }

        final pendingReports = provider.reports
            .where((report) => report.status == ReportStatus.pending)
            .toList();

        if (pendingReports.isEmpty) {
          return _buildEmptyReportsState();
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
              await communityProvider.refreshReports(source: Source.server);
            }
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: pendingReports.length,
            itemBuilder: (context, index) {
              final report = pendingReports[index];
              return _buildReportCard(report);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyReportsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64.sp,
            color: AppColors.success,
          ),
          SizedBox(height: 16.h),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'No pending reports to review',
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

  Widget _buildReportCard(Report report) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPriorityIndicator(report.priority),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.category.displayName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Group: ${report.groupId}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (report.isOverdue)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'Overdue',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              report.description,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Text(
                  'Reported ${report.age.inHours}h ago',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showReportDetails(report),
                  child: Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    Color color;

    switch (priority) {
      case 5:
        color = AppColors.error;
        break;
      case 4:
        color = AppColors.warning;
        break;
      case 3:
        color = Colors.orange;
        break;
      case 2:
        color = Colors.blue;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          priority.toString(),
          style: TextStyle(
            fontSize: 8.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Analytics',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Reports',
                  '24',
                  Icons.report,
                  AppColors.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Resolved',
                  '18',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avg Response',
                  '2.3h',
                  Icons.timer,
                  AppColors.info,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Active Groups',
                  '8',
                  Icons.group,
                  AppColors.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 32.h),

          // Report Categories Chart
          Text(
            'Reports by Category',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildCategoryChart(),

          SizedBox(height: 32.h),

          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: color,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    final categories = [
      {'name': 'Medical Misinformation', 'count': 8, 'percentage': 33.3},
      {'name': 'Inappropriate Content', 'count': 6, 'percentage': 25.0},
      {'name': 'Spam', 'count': 5, 'percentage': 20.8},
      {'name': 'Privacy Violation', 'count': 3, 'percentage': 12.5},
      {'name': 'Other', 'count': 2, 'percentage': 8.3},
    ];

    return Column(
      children: categories.map((category) {
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  category['name'] as String,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${category['count']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: LinearProgressIndicator(
                  value: (category['percentage'] as double) / 100,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${category['percentage']}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'action': 'Resolved report', 'details': 'Medical misinformation in Diabetes group', 'time': '2h ago'},
      {'action': 'Approved thread', 'details': 'New discussion in Mental Health', 'time': '4h ago'},
      {'action': 'Removed comment', 'details': 'Inappropriate content flagged', 'time': '6h ago'},
      {'action': 'Assigned moderator', 'details': 'New moderator for Respiratory group', 'time': '1d ago'},
    ];

    return Column(
      children: activities.map((activity) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['action']!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      activity['details']!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                activity['time']!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation Settings',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),

          // Auto-moderation settings
          _buildSettingSection(
            'Auto-Moderation',
            [
              _buildSettingItem(
                'Enable content scanning',
                'Automatically flag suspicious content',
                true,
              ),
              _buildSettingItem(
                'Block spam patterns',
                'Prevent repetitive or promotional content',
                true,
              ),
              _buildSettingItem(
                'Medical term validation',
                'Flag potentially inaccurate medical information',
                false,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Notification settings
          _buildSettingSection(
            'Notifications',
            [
              _buildSettingItem(
                'High priority reports',
                'Immediate alerts for critical content',
                true,
              ),
              _buildSettingItem(
                'Daily summary',
                'Summary of moderation activity',
                true,
              ),
              _buildSettingItem(
                'Escalation alerts',
                'Notifications for overdue reports',
                false,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Response time settings
          _buildSettingSection(
            'Response Times',
            [
              _buildSettingItem(
                'Critical reports',
                'Respond within 2 hours',
                true,
              ),
              _buildSettingItem(
                'High priority',
                'Respond within 12 hours',
                true,
              ),
              _buildSettingItem(
                'Standard reports',
                'Respond within 48 hours',
                true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem(String title, String subtitle, bool isEnabled) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              // TODO: Update setting
            },
            activeColor: AppColors.primary,
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
            'Error loading reports',
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
                await provider.refreshReports(source: Source.server);
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

  void _showReportDetails(Report report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16.w),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  'Report Details',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Category: ${report.category.displayName}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  report.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Dismiss report
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.textSecondary),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Take action on content
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: const Text('Review Content'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
