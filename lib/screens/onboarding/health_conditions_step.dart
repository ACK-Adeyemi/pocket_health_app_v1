import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';
import '../../models/health_condition.dart';

class HealthConditionsStep extends StatefulWidget {
  final List<String> selectedConditions;
  final Function(List<String>) onConditionsChanged;
  final VoidCallback onNext;

  const HealthConditionsStep({
    super.key,
    required this.selectedConditions,
    required this.onConditionsChanged,
    required this.onNext,
  });

  @override
  State<HealthConditionsStep> createState() => _HealthConditionsStepState();
}

class _HealthConditionsStepState extends State<HealthConditionsStep> {
  late List<String> _selectedConditions;
  late List<HealthCondition> _availableConditions;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedConditions = List.from(widget.selectedConditions);
    _availableConditions = HealthCondition.getCommonConditions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HealthCondition> get _filteredConditions {
    if (_searchQuery.isEmpty) {
      return _availableConditions;
    }
    return _availableConditions.where((condition) {
      return condition.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          condition.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleCondition(String conditionId) {
    setState(() {
      if (_selectedConditions.contains(conditionId)) {
        _selectedConditions.remove(conditionId);
      } else {
        _selectedConditions.add(conditionId);
      }
    });
    widget.onConditionsChanged(_selectedConditions);
  }

  void _handleNext() {
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 32.h),

                  // Title
                  Text(
                    'Health Conditions',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Text(
                    'Select any health conditions you have or would like to track. This is optional and can be updated later.',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search conditions...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Selected Count
                  if (_selectedConditions.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${_selectedConditions.length} condition${_selectedConditions.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: 16.h),

                  // Conditions List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredConditions.length,
                    itemBuilder: (context, index) {
                      final condition = _filteredConditions[index];
                      final isSelected = _selectedConditions.contains(condition.id);

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          leading: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              isSelected ? Icons.check : _getConditionIcon(condition.category),
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              size: 20.sp,
                            ),
                          ),
                          title: Text(
                            condition.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            condition.description,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: condition.severity != null
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(condition.severity!).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    condition.severity!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: _getSeverityColor(condition.severity!),
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => _toggleCondition(condition.id),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Skip/Continue Buttons
                  Padding(
                    padding: EdgeInsets.only(bottom: 32.h),
                    child: Column(
                      children: [
                        LoadingButton(
                          onPressed: _handleNext,
                          isLoading: false,
                          text: _selectedConditions.isEmpty ? 'Skip for Now' : 'Continue',
                        ),
                        if (_selectedConditions.isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedConditions.clear();
                              });
                              widget.onConditionsChanged(_selectedConditions);
                              _handleNext();
                            },
                            child: Text(
                              'Skip for Now',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getConditionIcon(String? category) {
    switch (category) {
      case 'chronic':
        return Icons.timeline;
      case 'mental_health':
        return Icons.psychology;
      case 'acute':
        return Icons.warning;
      default:
        return Icons.health_and_safety;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return AppColors.success;
      case 'moderate':
        return AppColors.warning;
      case 'severe':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
