import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_validator/form_validator.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class GPDetailsStep extends StatefulWidget {
  final String gpName;
  final String practiceName;
  final String phone;
  final String email;
  final Function(String gpName, String practiceName, String phone, String email) onDataChanged;
  final VoidCallback onNext;

  const GPDetailsStep({
    super.key,
    required this.gpName,
    required this.practiceName,
    required this.phone,
    required this.email,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<GPDetailsStep> createState() => _GPDetailsStepState();
}

class _GPDetailsStepState extends State<GPDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _gpNameController;
  late TextEditingController _practiceNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _skipGPDetails = false;

  @override
  void initState() {
    super.initState();
    _gpNameController = TextEditingController(text: widget.gpName);
    _practiceNameController = TextEditingController(text: widget.practiceName);
    _phoneController = TextEditingController(text: widget.phone);
    _emailController = TextEditingController(text: widget.email);
    
    // If all fields are empty, assume user wants to skip
    _skipGPDetails = widget.gpName.isEmpty && 
                    widget.practiceName.isEmpty && 
                    widget.phone.isEmpty && 
                    widget.email.isEmpty;
  }

  @override
  void dispose() {
    _gpNameController.dispose();
    _practiceNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_skipGPDetails) {
      // Skip GP details
      widget.onDataChanged('', '', '', '');
      widget.onNext();
    } else {
      // Validate form if not skipping
      if (_formKey.currentState!.validate()) {
        widget.onDataChanged(
          _gpNameController.text.trim(),
          _practiceNameController.text.trim(),
          _phoneController.text.trim(),
          _emailController.text.trim(),
        );
        widget.onNext();
      }
    }
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
                    'GP Details',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  
                  Text(
                    'Add your GP information for better health coordination. This is optional and can be updated later.',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  
                  // Skip Toggle
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Having GP details helps with emergency contacts and health coordination.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Skip Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _skipGPDetails,
                        onChanged: (value) {
                          setState(() {
                            _skipGPDetails = value ?? false;
                            if (_skipGPDetails) {
                              // Clear all fields when skipping
                              _gpNameController.clear();
                              _practiceNameController.clear();
                              _phoneController.clear();
                              _emailController.clear();
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text(
                          'Skip GP details for now',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Form Fields (only show if not skipping)
                  if (!_skipGPDetails) ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // GP Name Field
                          CustomTextField(
                            controller: _gpNameController,
                            label: 'GP Name',
                            textCapitalization: TextCapitalization.words,
                            validator: ValidationBuilder()
                                .required('GP name is required')
                                .minLength(2, 'GP name must be at least 2 characters')
                                .build(),
                          ),
                          SizedBox(height: 24.h),
                          
                          // Practice Name Field
                          CustomTextField(
                            controller: _practiceNameController,
                            label: 'Practice/Clinic Name',
                            textCapitalization: TextCapitalization.words,
                            validator: ValidationBuilder()
                                .required('Practice name is required')
                                .minLength(2, 'Practice name must be at least 2 characters')
                                .build(),
                          ),
                          SizedBox(height: 24.h),
                          
                          // Phone Field
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            validator: ValidationBuilder()
                                .required('Phone number is required')
                                .phone('Please enter a valid phone number')
                                .build(),
                          ),
                          SizedBox(height: 24.h),
                          
                          // Email Field
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address (Optional)',
                            keyboardType: TextInputType.emailAddress,
                            validator: ValidationBuilder()
                                .email('Please enter a valid email address')
                                .build(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                    
                    // Skip Message
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.secondary,
                            size: 48.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Problem!',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'You can add your GP details later in your profile settings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Next Button
                  Padding(
                    padding: EdgeInsets.only(bottom: 32.h),
                    child: Column(
                      children: [
                        LoadingButton(
                          onPressed: _handleNext,
                          isLoading: false,
                          text: 'Continue',
                        ),
                        if (!_skipGPDetails) ...[
                          SizedBox(height: 12.h),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _skipGPDetails = true;
                                _gpNameController.clear();
                                _practiceNameController.clear();
                                _phoneController.clear();
                                _emailController.clear();
                              });
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
}
