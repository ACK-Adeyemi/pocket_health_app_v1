import 'package:flutter/material.dart';
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
    // Use standard AlertDialog for better web compatibility
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag, color: Colors.white),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                'Report ${widget.contentType}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 500.0, // Fixed width for web/desktop
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why are you reporting this?',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),
              ...ReportCategory.values.map((category) {
                return RadioListTile<ReportCategory>(
                  title: Text(category.displayName),
                  subtitle: Text(
                    category.description,
                    style: const TextStyle(fontSize: 12.0),
                  ),
                  value: category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  activeColor: AppColors.error,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              const SizedBox(height: 16.0),
              const Text(
                'Additional Details (Optional)',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Provide more context...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}