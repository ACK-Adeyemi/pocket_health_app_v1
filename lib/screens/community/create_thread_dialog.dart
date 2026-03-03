import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../models/group.dart';
import '../../utils/app_colors.dart';

class CreateThreadDialog extends StatefulWidget {
  final Group group;

  const CreateThreadDialog({super.key, required this.group});

  @override
  State<CreateThreadDialog> createState() => _CreateThreadDialogState();
}

class _CreateThreadDialogState extends State<CreateThreadDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _createThread() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      final success = await communityProvider.createThread(
        groupId: widget.group.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discussion created successfully!')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(communityProvider.errorMessage ?? 'Failed to create discussion')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
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
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.add, color: Colors.white),
                SizedBox(width: 12.w),
                const Expanded(
                  child: Text(
                    'Start Discussion',
                    style: TextStyle(
                      fontSize: 18.0,
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
                    'Group: ${widget.group.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  const Text(
                    'Title *',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'What would you like to discuss?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.all(12.0),
                    ),
                    maxLength: 200,
                  ),
                  SizedBox(height: 16.h),
                  const Text(
                    'Content *',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts, experiences, or questions...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.all(12.0),
                    ),
                    maxLines: 4,
                    maxLength: 2000,
                  ),
                  SizedBox(height: 16.h),
                  const Text(
                    'Tags (Optional)',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: 'Add a tag...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsets.all(12.0),
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: _addTag,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(0, 48.h),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag, style: TextStyle(fontSize: 12.sp)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeTag(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      )).toList(),
                    ),
                  ],
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
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createThread,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 0),
                  ),
                  child: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
