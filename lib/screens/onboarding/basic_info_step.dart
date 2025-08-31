import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_validator/form_validator.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class BasicInfoStep extends StatefulWidget {
  final String name;
  final int age;
  final double height;
  final double weight;
  final String heightUnit;
  final String weightUnit;
  final Function(String name, int age, double height, double weight, String heightUnit, String weightUnit) onDataChanged;
  final VoidCallback onNext;

  const BasicInfoStep({
    super.key,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.heightUnit,
    required this.weightUnit,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late String _heightUnit;
  late String _weightUnit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ageController = TextEditingController(text: widget.age > 0 ? widget.age.toString() : '');
    _heightController = TextEditingController(text: widget.height > 0 ? widget.height.toString() : '');
    _weightController = TextEditingController(text: widget.weight > 0 ? widget.weight.toString() : '');
    _heightUnit = widget.heightUnit;
    _weightUnit = widget.weightUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      widget.onDataChanged(
        _nameController.text.trim(),
        int.tryParse(_ageController.text) ?? 0,
        double.tryParse(_heightController.text) ?? 0.0,
        double.tryParse(_weightController.text) ?? 0.0,
        _heightUnit,
        _weightUnit,
      );
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32.h),
            
            // Title
            Text(
              'Tell us about yourself',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            
            Text(
              'This information helps us personalize your health experience.',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 40.h),
            
            // Name Field
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              textCapitalization: TextCapitalization.words,
              validator: ValidationBuilder()
                  .required('Name is required')
                  .minLength(2, 'Name must be at least 2 characters')
                  .build(),
            ),
            SizedBox(height: 24.h),
            
            // Age Field
            CustomTextField(
              controller: _ageController,
              label: 'Age',
              keyboardType: TextInputType.number,
              validator: ValidationBuilder()
                  .required('Age is required')
                  .regExp(RegExp(r'^\d+$'), 'Please enter a valid age')
                  .add((value) {
                    final age = int.tryParse(value ?? '');
                    if (age == null || age < 13 || age > 120) {
                      return 'Age must be between 13 and 120';
                    }
                    return null;
                  })
                  .build(),
            ),
            SizedBox(height: 24.h),
            
            // Height Field with Unit Selector
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _heightController,
                    label: 'Height',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: ValidationBuilder()
                        .required('Height is required')
                        .regExp(RegExp(r'^\d+\.?\d*$'), 'Please enter a valid height')
                        .add((value) {
                          final height = double.tryParse(value ?? '');
                          if (height == null || height <= 0) {
                            return 'Please enter a valid height';
                          }
                          if (_heightUnit == 'cm' && (height < 50 || height > 300)) {
                            return 'Height must be between 50-300 cm';
                          }
                          if (_heightUnit == 'ft' && (height < 2 || height > 10)) {
                            return 'Height must be between 2-10 ft';
                          }
                          return null;
                        })
                        .build(),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: _heightUnit,
                        items: const [
                          DropdownMenuItem(value: 'cm', child: Text('cm')),
                          DropdownMenuItem(value: 'ft', child: Text('ft')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _heightUnit = value!;
                          });
                        },
                        decoration: InputDecoration(
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
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Weight Field with Unit Selector
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _weightController,
                    label: 'Weight',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: ValidationBuilder()
                        .required('Weight is required')
                        .regExp(RegExp(r'^\d+\.?\d*$'), 'Please enter a valid weight')
                        .add((value) {
                          final weight = double.tryParse(value ?? '');
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight';
                          }
                          if (_weightUnit == 'kg' && (weight < 20 || weight > 300)) {
                            return 'Weight must be between 20-300 kg';
                          }
                          if (_weightUnit == 'lbs' && (weight < 44 || weight > 660)) {
                            return 'Weight must be between 44-660 lbs';
                          }
                          return null;
                        })
                        .build(),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: _weightUnit,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _weightUnit = value!;
                          });
                        },
                        decoration: InputDecoration(
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
                    ],
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Next Button
            Padding(
              padding: EdgeInsets.only(bottom: 32.h),
              child: LoadingButton(
                onPressed: _handleNext,
                isLoading: false,
                text: 'Continue',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
