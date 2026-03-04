import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/health_tracking_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/health_condition.dart';
import '../../models/health_metric.dart';
import '../../models/health_entry.dart';
import '../../utils/app_colors.dart';
import 'add_health_entry_screen.dart';

class ConditionDetailScreen extends StatefulWidget {
  final HealthCondition condition;

  const ConditionDetailScreen({
    super.key,
    required this.condition,
  });

  @override
  State<ConditionDetailScreen> createState() => _ConditionDetailScreenState();
}

class _ConditionDetailScreenState extends State<ConditionDetailScreen> {
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
      healthProvider.loadHealthEntries(userProvider.userProfile!.uid);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.condition.name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
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

          final entries = healthProvider.getEntriesForCondition(widget.condition.id);
          final metrics = healthProvider.getMetricsForCondition(widget.condition.id);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Condition Overview Card
                _buildConditionOverview(entries, metrics),
                SizedBox(height: 16.h),

                // Quick Add Entry Section
                _buildQuickAddSection(metrics),
                SizedBox(height: 16.h),

                // Metrics Overview
                if (metrics.isNotEmpty) ...[
                  _buildMetricsOverview(metrics, entries, healthProvider),
                  SizedBox(height: 16.h),
                ],

                // Recent Entries
                _buildRecentEntries(entries, metrics, healthProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddHealthEntryScreen(
                condition: widget.condition,
              ),
            ),
          );
          if (result == true) {
            _loadHealthData(); // Refresh data after adding entry
          }
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildConditionOverview(List<HealthEntry> entries, List<HealthMetric> metrics) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    _getConditionIcon(widget.condition.id),
                    color: AppColors.primary,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.condition.name,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.condition.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.condition.takesMedication != null) ...[
                        SizedBox(height: 8.h),
                        _buildMedicationBadge(widget.condition.takesMedication!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Entries',
                    entries.length.toString(),
                    Icons.timeline,
                    AppColors.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    'Metrics Tracked',
                    metrics.length.toString(),
                    Icons.analytics,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    'Days Active',
                    _calculateActiveDays(entries).toString(),
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection(List<HealthMetric> metrics) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Add Entry',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: metrics.length,
                itemBuilder: (context, index) {
                  final metric = metrics[index];
                  return Container(
                    width: 120.w,
                    margin: EdgeInsets.only(right: 12.w),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddHealthEntryScreen(
                              condition: widget.condition,
                              selectedMetric: metric,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadHealthData();
                        }
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: metric.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: metric.color.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              metric.icon,
                              color: metric.color,
                              size: 24.sp,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              metric.name,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverview(List<HealthMetric> metrics, List<HealthEntry> entries, HealthTrackingProvider healthProvider) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metrics Overview',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            ...metrics.map((metric) {
              final metricEntries = entries.where((e) => e.metricId == metric.id).toList();
              final latestEntry = metricEntries.isNotEmpty ? metricEntries.first : null;
              final average = healthProvider.getAverageForMetric(widget.condition.id, metric.id, days: 30);
              
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: metric.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: metric.color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(metric.icon, color: metric.color, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${metricEntries.length} entries',
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
                        if (latestEntry != null) ...[
                          Text(
                            latestEntry.getDisplayValue(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: metric.color,
                            ),
                          ),
                          Text(
                            'Latest',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'No data',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (average != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            '${average.toStringAsFixed(1)}${metric.getUnitDisplay()}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '30-day avg',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(List<HealthEntry> entries, List<HealthMetric> metrics, HealthTrackingProvider healthProvider) {
    final recentEntries = entries.take(10).toList();
    
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Entries',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (entries.length > 10)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full history
                    },
                    child: Text(
                      'View All (${entries.length})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            if (recentEntries.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
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
                      'Tap the + button to add your first entry',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...recentEntries.map((entry) {
                final metric = metrics.where((m) => m.id == entry.metricId).firstOrNull;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: (metric?.color ?? AppColors.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          metric?.icon ?? Icons.health_and_safety,
                          color: metric?.color ?? AppColors.primary,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric?.name ?? 'Unknown Metric',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (entry.notes != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                entry.notes!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
                              fontWeight: FontWeight.bold,
                              color: metric?.color ?? AppColors.primary,
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
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  int _calculateActiveDays(List<HealthEntry> entries) {
    if (entries.isEmpty) return 0;
    
    final uniqueDays = entries
        .map((entry) => DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day))
        .toSet();
    
    return uniqueDays.length;
  }

  Widget _buildMedicationBadge(bool takesMeds) {
    const purple = Color(0xFF9C27B0);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: purple.withOpacity(0.5)),
      ),
      child: Text(
        'Managed with Medication: ${takesMeds ? "YES" : "NO"}',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: purple,
        ),
      ),
    );
  }
}
