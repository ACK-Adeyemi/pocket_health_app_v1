import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';

enum SortOption {
  newest('Newest', Icons.access_time),
  oldest('Oldest', Icons.history),
  popular('Most Popular', Icons.trending_up),
  mostCommented('Most Comments', Icons.comment),
  recentlyActive('Recently Active', Icons.update);

  const SortOption(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

enum FilterOption {
  all('All Posts', Icons.forum),
  myPosts('My Posts', Icons.person),
  unanswered('Unanswered', Icons.question_answer),
  solved('Solved', Icons.check_circle);

  const FilterOption(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

class SearchFilterBar extends StatefulWidget {
  final Function(String)? onSearchChanged;
  final Function(SortOption)? onSortChanged;
  final Function(FilterOption)? onFilterChanged;
  final SortOption initialSort;
  final FilterOption initialFilter;
  final bool showFilters;

  const SearchFilterBar({
    super.key,
    this.onSearchChanged,
    this.onSortChanged,
    this.onFilterChanged,
    this.initialSort = SortOption.newest,
    this.initialFilter = FilterOption.all,
    this.showFilters = true,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late TextEditingController _searchController;
  late SortOption _selectedSort;
  late FilterOption _selectedFilter;
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedSort = widget.initialSort;
    _selectedFilter = widget.initialFilter;

    _searchController.addListener(() {
      widget.onSearchChanged?.call(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.grey200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search discussions, topics, or tags...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
              ),
              if (widget.showFilters) ...[
                SizedBox(width: 12.w),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showAdvancedFilters = !_showAdvancedFilters;
                    });
                  },
                  icon: Icon(
                    _showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Advanced Filters
        if (_showAdvancedFilters && widget.showFilters)
          Container(
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
                Text(
                  'Sort by',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: SortOption.values.map((option) {
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(option.icon, size: 16.sp),
                          SizedBox(width: 4.w),
                          Text(option.displayName),
                        ],
                      ),
                      selected: _selectedSort == option,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedSort = option);
                          widget.onSortChanged?.call(option);
                        }
                      },
                      selectedColor: AppColors.primary.withOpacity(0.1),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Filter by',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: FilterOption.values.map((option) {
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(option.icon, size: 16.sp),
                          SizedBox(width: 4.w),
                          Text(option.displayName),
                        ],
                      ),
                      selected: _selectedFilter == option,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = option);
                          widget.onFilterChanged?.call(option);
                        }
                      },
                      selectedColor: AppColors.primary.withOpacity(0.1),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
