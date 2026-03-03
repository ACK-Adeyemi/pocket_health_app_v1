import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/quick_check_in_provider.dart';
import '../../models/health_metric.dart';
import '../../utils/app_colors.dart';

class QuickCheckInModal extends StatefulWidget {
  const QuickCheckInModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickCheckInModal(),
    );
  }

  @override
  State<QuickCheckInModal> createState() => _QuickCheckInModalState();
}

class _QuickCheckInModalState extends State<QuickCheckInModal> {
  dynamic _currentValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<QuickCheckInProvider>(context, listen: false);
      provider.prepareCheckIn();
      if (provider.selectedMetric != null) {
        _initializeValue(provider.selectedMetric!);
      }
    });
  }

  void _initializeValue(HealthMetric metric) {
    setState(() {
      if (metric.type == MetricType.pain || 
          metric.type == MetricType.mood || 
          metric.type == MetricType.anxiety) {
        _currentValue = 5.0; // Default middle
      } else if (metric.options != null && metric.options!.isNotEmpty) {
        _currentValue = metric.options!.first;
      } else {
        _currentValue = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickCheckInProvider>(
      builder: (context, provider, child) {
        final condition = provider.selectedCondition;
        final metric = provider.selectedMetric;

        // While saving, show loading state to prevent "Empty state" flash
        if (provider.isSaving) {
          return _buildLoadingState();
        }

        if (condition == null || metric == null) {
          return _buildEmptyState();
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32.h,
              left: 24.w,
              right: 24.w,
              top: 12.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),

                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: metric.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 24.sp),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Pulse',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            condition.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // Question
                Text(
                  metric.instructions ?? 'How are you feeling today?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),

                // Input Area
                _buildInput(metric),

                SizedBox(height: 32.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Skip',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: provider.isSaving ? null : () async {
                          final success = await provider.submitCheckIn(_currentValue);
                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Daily pulse logged! Keep it up.'),
                                backgroundColor: AppColors.secondary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: metric.color,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: const Text('Log Entry'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput(HealthMetric metric) {
    if (metric.type == MetricType.pain || 
        metric.type == MetricType.mood || 
        metric.type == MetricType.anxiety) {
      return _buildSlider(metric);
    } else if (metric.options != null) {
      return _buildChips(metric);
    } else {
      return _buildNumericFallback(metric);
    }
  }

  Widget _buildSlider(HealthMetric metric) {
    return Column(
      children: [
        Slider(
          value: (_currentValue as num?)?.toDouble() ?? 5.0,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: metric.color,
          onChanged: (val) => setState(() => _currentValue = val),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(fontSize: 12.sp, color: AppColors.textLight)),
              Text(
                '${(_currentValue as num?)?.toInt() ?? 5}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: metric.color,
                ),
              ),
              Text('High', style: TextStyle(fontSize: 12.sp, color: AppColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChips(HealthMetric metric) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: metric.options!.map((option) {
        final isSelected = _currentValue == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _currentValue = option);
          },
          selectedColor: metric.color.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? metric.color : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumericFallback(HealthMetric metric) {
    return Column(
      children: [
        Text(
          'Enter ${metric.name}',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 8.h),
        // Since typing is discouraged, we show a simple +/- selector for common numeric ranges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => _currentValue = (_currentValue as num) - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Container(
              width: 100.w,
              alignment: Alignment.center,
              child: Text(
                '${_currentValue ?? 0}',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _currentValue = (_currentValue as num) + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 48.sp, color: AppColors.textLight),
          SizedBox(height: 16.h),
          const Text('No metrics to log today!'),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
