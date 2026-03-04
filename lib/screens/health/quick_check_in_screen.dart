import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/quick_check_in_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuickCheckInProvider>(context, listen: false).startFlow();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickCheckInProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              _buildHandle(),
              _buildHeader(provider),
              if (provider.selectedCondition != null && provider.currentStep < 5)
                _buildProgressBar(provider.currentStep),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
                  child: _buildCurrentScreen(provider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(QuickCheckInProvider provider) {
    // Show back button if we are beyond step 1, but hide it on step 2 if step 1 was automatically skipped
    final showBack = provider.currentStep > 1 && 
                     provider.currentStep < 5 && 
                     !(provider.currentStep == 2 && provider.howUserIsFeelingToday != null);
                     
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => provider.goBack(),
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24.sp),
              visualDensity: VisualDensity.compact,
            )
          else
            SizedBox(width: 40.w),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.textSecondary, size: 24.sp),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.r),
        child: LinearProgressIndicator(
          value: step / 5,
          backgroundColor: AppColors.grey200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4.h,
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(QuickCheckInProvider provider) {
    if (provider.isSaving) {
      return SizedBox(
        height: 300.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // If all conditions are done for today, show the completion screen
    if (provider.selectedCondition == null && provider.currentStep != 5) {
      return _buildAllDoneForToday(provider);
    }

    switch (provider.currentStep) {
      case 1:
        return _buildGlobalState(provider);
      case 2:
        return _buildConditionSignal(provider);
      case 3:
        return _buildOptionalContext(provider);
      case 4:
        return _buildMedicationManagement(provider);
      case 5:
        return _buildConfirmation(provider);
      default:
        return _buildGlobalState(provider);
    }
  }

  // --- Screen 1: Global State ---
  Widget _buildGlobalState(QuickCheckInProvider provider) {
    return Column(
      children: [
        Text(
          'How are you right now?',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 32.h),
        _buildChoiceButton(
          label: 'Good',
          emoji: '😊\uFE0F',
          color: Colors.green,
          onTap: () => provider.setHowUserIsFeelingToday('good'),
        ),
        _buildChoiceButton(
          label: 'Okay',
          emoji: '😐\uFE0F',
          color: Colors.orange,
          onTap: () => provider.setHowUserIsFeelingToday('okay'),
        ),
        _buildChoiceButton(
          label: 'Not great',
          emoji: '😟\uFE0F',
          color: Colors.red,
          onTap: () => provider.setHowUserIsFeelingToday('not_great'),
        ),
      ],
    );
  }

  // --- Screen 2: Condition Signal ---
  Widget _buildConditionSignal(QuickCheckInProvider provider) {
    final condition = provider.selectedCondition;
    if (condition == null) return const Text('Loading...');

    return Column(
      children: [
        Text(
          _getConditionQuestion(condition.id),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          condition.name,
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 32.h),
        ..._getConditionOptions(condition.id).map((opt) => _buildChoiceButton(
              label: opt,
              onTap: () => provider.setSignalValue(opt),
            )),
      ],
    );
  }

  String _getConditionQuestion(String id) {
    switch (id) {
      case 'asthma':
      case 'copd': return 'Breathing today?';
      case 'diabetes_type1':
      case 'diabetes_type2': return 'Blood sugar felt...';
      case 'hypertension': return 'Heart / BP felt...';
      case 'heart_disease': return 'How tired do you feel?';
      case 'migraine': return 'Head pain?';
      case 'anxiety': return 'Anxiety level?';
      case 'depression': return 'Mood today?';
      case 'thyroid': return 'Energy level?';
      case 'arthritis': return 'Joint pain?';
      case 'obesity': return 'Today felt...';
      default: return 'How are you feeling?';
    }
  }

  List<String> _getConditionOptions(String id) {
    switch (id) {
      case 'asthma':
      case 'copd': return ['Normal', 'Tight', 'Wheezy', 'Short of breath'];
      case 'diabetes_type1':
      case 'diabetes_type2': return ['Normal', 'Low', 'High'];
      case 'hypertension': return ['Normal', 'A bit high', 'High', 'Low'];
      case 'heart_disease': return ['Normal', 'Tired', 'Very tired', 'Exhausted'];
      case 'migraine': return ['None', 'Mild', 'Moderate', 'Severe'];
      case 'anxiety': return ['Calm', 'Elevated', 'High', 'Panic'];
      case 'depression': return ['Stable', 'Low', 'Very low', 'Numb'];
      case 'thyroid': return ['Normal', 'Low', 'Very low', 'Wired'];
      case 'arthritis': return ['None', 'Mild', 'Moderate', 'Severe'];
      case 'obesity': return ['On track', 'Off track', 'Hard day'];
      default: return ['Good', 'Okay', 'Bad'];
    }
  }

  // --- All Done Screen ---
  Widget _buildAllDoneForToday(QuickCheckInProvider provider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.success.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text('👏', style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 16.h),
              Text(
                'Thanks for checking in today!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Well done. Please come back tomorrow for your next check in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Feel free to log more detailed entries on the Track page.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 32.h),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: Size(double.infinity, 56.h),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  // --- Screen 3: Optional Context ---
  Widget _buildOptionalContext(QuickCheckInProvider provider) {
    return Column(
      children: [
        Text(
          'What may have affected this?',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 32.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: ['Stress', 'Sleep', 'Medication', 'Diet', 'Activity']
              .map((c) => _buildChoiceChip(c, () => provider.setContext(c)))
              .toList(),
        ),
        SizedBox(height: 32.h),
        TextButton(
          onPressed: () => provider.setContext(null),
          child: Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
        ),
      ],
    );
  }

  // --- Screen 4: Medication ---
  Widget _buildMedicationManagement(QuickCheckInProvider provider) {
    if (provider.medSubStep == 1) {
      return Column(
        children: [
          Text(
            'Do you take medication to manage this condition?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32.h),
          _buildChoiceButton(label: 'Yes', onTap: () => provider.setTakesMedication(true)),
          _buildChoiceButton(label: 'No', onTap: () => provider.setTakesMedication(false)),
        ],
      );
    } else if (provider.medSubStep == 2) {
      return Column(
        children: [
          Text(
            'Have you taken your medication today?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32.h),
          _buildChoiceButton(label: 'Yes', onTap: () => provider.setTakenToday(true)),
          _buildChoiceButton(
            label: 'No, and I don\'t want to',
            onTap: () => provider.setTakenToday(false),
          ),
          _buildChoiceButton(
            label: 'I will later',
            onTap: () => provider.setTakenToday(null),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            'Have you been consistently taking your medication in the last 7 days?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32.h),
          _buildChoiceButton(label: 'Yes', onTap: () => provider.setMedicationStability('yes')),
          _buildChoiceButton(label: 'Mostly', onTap: () => provider.setMedicationStability('mostly')),
          _buildChoiceButton(label: 'Somewhat', onTap: () => provider.setMedicationStability('somewhat')),
          _buildChoiceButton(label: 'Not at all', onTap: () => provider.setMedicationStability('not_at_all')),
        ],
      );
    }
  }

  // --- Screen 5: Confirmation ---
  Widget _buildConfirmation(QuickCheckInProvider provider) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: Icon(Icons.check, color: Colors.white, size: 48.sp),
        ),
        SizedBox(height: 24.h),
        Text(
          'Logged!',
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Streak: ', style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
            Text('${provider.streak} days 🔥', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        SizedBox(height: 32.h),
        _buildQueueView(provider),
        SizedBox(height: 32.h),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: Size(double.infinity, 56.h),
          ),
          child: const Text('Finish'),
        ),
      ],
    );
  }

  Widget _buildQueueView(QuickCheckInProvider provider) {
    final conditions = provider.userProvider.userProfile?.healthConditions ?? [];
    if (conditions.isEmpty) return const SizedBox.shrink();

    final remainingCount = conditions.length - provider.completedConditionIdsToday.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next in queue',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        SizedBox(height: 12.h),
        ...conditions.map((c) {
          final isDone = provider.completedConditionIdsToday.contains(c.id);
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDone ? AppColors.success.withOpacity(0.1) : AppColors.grey100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle : Icons.circle_outlined,
                  size: 20.sp,
                  color: isDone ? AppColors.success : AppColors.textSecondary,
                ),
                SizedBox(width: 12.w),
                Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDone ? AppColors.success : AppColors.textPrimary,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
        if (remainingCount > 0) ...[
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                provider.nextCondition();
              },
              child: const Text('Check in with another condition'),
            ),
          ),
        ],
      ],
    );
  }

  // --- UI Components ---

  Widget _buildChoiceButton({required String label, String? emoji, Color? color, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          side: BorderSide(color: AppColors.grey200),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: TextStyle(fontSize: 24.sp)),
              SizedBox(width: 12.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
