import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../models/report.dart';
import '../../utils/app_colors.dart';

class ReportDialog extends StatefulWidget {
  final String contentId;
  final String contentType;
  final String groupId;

  const ReportDialog({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.groupId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportCategory? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for reporting')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    final success = await communityProvider.reportContent(
      contentId: widget.contentId,
      contentType: widget.contentType,
      groupId: widget.groupId,
      category: _selectedCategory!,
      description: _descriptionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully. Thank you for keeping our community safe.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(communityProvider.errorMessage ?? 'Failed to submit report')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Report ${widget.contentType}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why are you reporting this?',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...ReportCategory.values.map((category) {
                    return RadioListTile<ReportCategory>(
                      title: Text(
                        category.displayName,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        category.description,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      value: category,
                      groupValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      activeColor: AppColors.error,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                  SizedBox(height: 16.h),
                  Text(
                    'Additional Details (Optional)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Provide more context...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                    maxLines: 3,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  // Extra space for keyboard if needed
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          
          // Actions
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 0),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.w,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
