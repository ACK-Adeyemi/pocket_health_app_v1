import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../models/health_condition.dart';
import '../../utils/app_colors.dart';
import 'basic_info_step.dart';
import 'health_conditions_step.dart';
import 'gp_details_step.dart';
import 'preferences_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form data
  String _name = '';
  int _age = 0;
  double _height = 0;
  double _weight = 0;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  List<String> _selectedConditions = [];
  String _gpName = '';
  String _practiceName = '';
  String _gpPhone = '';
  String _gpEmail = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Helper method to convert condition IDs to HealthCondition objects
  List<HealthCondition> _getSelectedHealthConditions() {
    if (_selectedConditions.isEmpty) return [];
    
    final availableConditions = HealthCondition.getCommonConditions();
    final selectedHealthConditions = <HealthCondition>[];
    
    for (final conditionId in _selectedConditions) {
      final condition = availableConditions.firstWhere(
        (c) => c.id == conditionId,
        orElse: () => HealthCondition(
          id: conditionId,
          name: 'Unknown Condition',
          description: 'Custom health condition',
          addedAt: DateTime.now(),
          category: 'other',
        ),
      );
      selectedHealthConditions.add(condition);
    }
    
    return selectedHealthConditions;
  }

  Future<void> _completeOnboarding() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Create user profile
      final success = await userProvider.createUserProfile(
        name: _name,
        age: _age,
        height: _height,
        weight: _weight,
        heightUnit: _heightUnit,
        weightUnit: _weightUnit,
      );

      if (!success) {
        throw Exception('Failed to create user profile');
      }

      // Update health conditions if any selected
      if (_selectedConditions.isNotEmpty) {
        final healthConditions = _getSelectedHealthConditions();
        final conditionsSuccess = await userProvider.updateHealthConditions(healthConditions);
        if (!conditionsSuccess) {
          print('Warning: Failed to update health conditions, but continuing onboarding');
        }
      }

      // Update GP details if provided
      if (_gpName.isNotEmpty) {
        final gpSuccess = await userProvider.updateGPDetails(
          gpName: _gpName,
          practiceName: _practiceName,
          phone: _gpPhone,
          email: _gpEmail,
        );
        if (!gpSuccess) {
          print('Warning: Failed to update GP details, but continuing onboarding');
        }
      }

      // Complete onboarding
      final onboardingSuccess = await userProvider.completeOnboarding();
      if (!onboardingSuccess) {
        throw Exception('Failed to complete onboarding');
      }

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Setup Your Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4.h,
                ),
              ],
            ),
          ),
          
          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BasicInfoStep(
                  name: _name,
                  age: _age,
                  height: _height,
                  weight: _weight,
                  heightUnit: _heightUnit,
                  weightUnit: _weightUnit,
                  onDataChanged: (name, age, height, weight, heightUnit, weightUnit) {
                    setState(() {
                      _name = name;
                      _age = age;
                      _height = height;
                      _weight = weight;
                      _heightUnit = heightUnit;
                      _weightUnit = weightUnit;
                    });
                  },
                  onNext: _nextStep,
                ),
                HealthConditionsStep(
                  selectedConditions: _selectedConditions,
                  onConditionsChanged: (conditions) {
                    setState(() {
                      _selectedConditions = conditions;
                    });
                  },
                  onNext: _nextStep,
                ),
                GPDetailsStep(
                  gpName: _gpName,
                  practiceName: _practiceName,
                  phone: _gpPhone,
                  email: _gpEmail,
                  onDataChanged: (gpName, practiceName, phone, email) {
                    setState(() {
                      _gpName = gpName;
                      _practiceName = practiceName;
                      _gpPhone = phone;
                      _gpEmail = email;
                    });
                  },
                  onNext: _nextStep,
                ),
                PreferencesStep(
                  onComplete: _completeOnboarding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
