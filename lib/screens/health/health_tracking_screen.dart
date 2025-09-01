import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/health_tracking_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/health_condition.dart';
import '../../models/health_metric.dart';
import '../../utils/app_colors.dart';
// import 'add_health_entry_screen.dart';
// import 'condition_detail_screen.dart';

class HealthTrackingScreen extends StatefulWidget {
  const HealthTrackingScreen({super.key});

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHealthData();
    });
  }

  void _loadHealthData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthTrackingProvider>(context, listen: false);
    
    if (userProvider.userProfile != null) {
      // Set user conditions from profile
      healthProvider.setUserConditions(userProvider.userProfile!.healthConditions);
      
      // Load health entries
      healthProvider.loadHealthEntries(userProvider.userProfile!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Health Tracking',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadHealthData,
            icon: Icon(
              Icons.refresh,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
        ],
      ),
      body: Consumer<HealthTrackingProvider>(
        builder: (context, healthProvider, child) {
          if (healthProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (healthProvider.error != null) {
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
                    'Error loading health data',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    healthProvider.error!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () {
                      healthProvider.clearError();
                      _loadHealthData();
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

          if (healthProvider.userConditions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadHealthData(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(healthProvider),
                  SizedBox(height: 24.h),
                  _buildRecentEntries(healthProvider),
                  SizedBox(height: 24.h),
                  _buildConditionsList(healthProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 24.h),
            Text(
              'No Health Conditions',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Add health conditions in your profile to start tracking your health metrics.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                // Navigate to profile or onboarding
                Navigator.of(context).pushNamed('/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(HealthTrackingProvider healthProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: healthProvider.userConditions.length,
            itemBuilder: (context, index) {
              final condition = healthProvider.userConditions[index];
              return _buildQuickActionCard(condition, healthProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(HealthCondition condition, HealthTrackingProvider healthProvider) {
    final metrics = healthProvider.getMetricsForCondition(condition.id);
    final primaryMetric = metrics.isNotEmpty ? metrics.first : null;
    
    return Container(
      width: 140.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Card(
        elevation: 2,
        color: AppColors.surface,
        child: InkWell(
          onTap: () => _navigateToAddEntry(condition, primaryMetric),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getConditionIcon(condition.id),
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  condition.name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  'Add Entry',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEntries(HealthTrackingProvider healthProvider) {
    final recentEntries = healthProvider.recentEntries.take(5).toList();
    
    if (recentEntries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Entries',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timeline_outlined,
                  size: 32.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 12.h),
                Text(
                  'No entries yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Start tracking your health metrics',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Entries',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full history
              },
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...recentEntries.map((entry) => _buildRecentEntryCard(entry, healthProvider)),
      ],
    );
  }

  Widget _buildRecentEntryCard(dynamic entry, HealthTrackingProvider healthProvider) {
    final condition = healthProvider.getConditionById(entry.conditionId);
    final metrics = healthProvider.getMetricsForCondition(entry.conditionId);
    final metric = metrics.where((m) => m.id == entry.metricId).firstOrNull;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Card(
        elevation: 1,
        color: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getConditionIcon(entry.conditionId),
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
                      condition?.name ?? 'Unknown Condition',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      metric?.name ?? 'Unknown Metric',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.getDisplayValue(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatDateTime(entry.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionsList(HealthTrackingProvider healthProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Conditions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        ...healthProvider.userConditions.map((condition) => 
          _buildConditionCard(condition, healthProvider)),
      ],
    );
  }

  Widget _buildConditionCard(HealthCondition condition, HealthTrackingProvider healthProvider) {
    final entries = healthProvider.getEntriesForCondition(condition.id);
    final metrics = healthProvider.getMetricsForCondition(condition.id);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        elevation: 2,
        color: AppColors.surface,
        child: InkWell(
          onTap: () => _navigateToConditionDetail(condition),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
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
                        _getConditionIcon(condition.id),
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            condition.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${entries.length} entries • ${metrics.length} metrics',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
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
                if (entries.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text(
                    'Latest Entry: ${_formatDateTime(entries.first.timestamp)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getConditionIcon(String conditionId) {
    switch (conditionId) {
      case 'diabetes_type1':
      case 'diabetes_type2':
        return Icons.water_drop_outlined;
      case 'hypertension':
        return Icons.favorite_outline;
      case 'arthritis':
        return Icons.accessibility_new_outlined;
      case 'asthma':
        return Icons.air_outlined;
      case 'depression':
        return Icons.psychology_outlined;
      case 'anxiety':
        return Icons.sentiment_very_dissatisfied_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _navigateToAddEntry(HealthCondition condition, HealthMetric? metric) {
    // TODO: Navigate to add health entry screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add entry for ${condition.name} - Coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToConditionDetail(HealthCondition condition) {
    // TODO: Navigate to condition detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${condition.name} details - Coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
