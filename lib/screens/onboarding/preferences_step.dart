import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';
import '../../providers/user_provider.dart';

class PreferencesStep extends StatefulWidget {
  final VoidCallback onComplete;

  const PreferencesStep({
    super.key,
    required this.onComplete,
  });

  @override
  State<PreferencesStep> createState() => _PreferencesStepState();
}

class _PreferencesStepState extends State<PreferencesStep> {
  bool _healthReminders = true;
  bool _communityNotifications = true;
  bool _weeklyReports = true;
  bool _dataSharing = false;
  String _preferredLanguage = 'English';
  String _theme = 'System';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),
          
          // Title
          Text(
            'Preferences',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          
          Text(
            'Customize your Pocket Health experience. You can change these settings anytime.',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 40.h),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications Section
                  _SectionHeader(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Stay informed about your health journey',
                  ),
                  SizedBox(height: 16.h),
                  
                  _PreferenceItem(
                    title: 'Health Reminders',
                    subtitle: 'Medication, appointments, and health check reminders',
                    value: _healthReminders,
                    onChanged: (value) {
                      setState(() {
                        _healthReminders = value;
                      });
                    },
                  ),
                  
                  _PreferenceItem(
                    title: 'Community Notifications',
                    subtitle: 'Updates from community discussions and support groups',
                    value: _communityNotifications,
                    onChanged: (value) {
                      setState(() {
                        _communityNotifications = value;
                      });
                    },
                  ),
                  
                  _PreferenceItem(
                    title: 'Weekly Health Reports',
                    subtitle: 'Summary of your health progress and insights',
                    value: _weeklyReports,
                    onChanged: (value) {
                      setState(() {
                        _weeklyReports = value;
                      });
                    },
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Privacy Section
                  _SectionHeader(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy',
                    subtitle: 'Control how your data is used',
                  ),
                  SizedBox(height: 16.h),
                  
                  _PreferenceItem(
                    title: 'Anonymous Data Sharing',
                    subtitle: 'Help improve health research with anonymized data',
                    value: _dataSharing,
                    onChanged: (value) {
                      setState(() {
                        _dataSharing = value;
                      });
                    },
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // App Settings Section
                  _SectionHeader(
                    icon: Icons.settings_outlined,
                    title: 'App Settings',
                    subtitle: 'Customize your app experience',
                  ),
                  SizedBox(height: 16.h),
                  
                  // Language Preference
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<String>(
                          value: _preferredLanguage,
                          items: const [
                            DropdownMenuItem(value: 'English', child: Text('English')),
                            DropdownMenuItem(value: 'Spanish', child: Text('Español')),
                            DropdownMenuItem(value: 'French', child: Text('Français')),
                            DropdownMenuItem(value: 'German', child: Text('Deutsch')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _preferredLanguage = value!;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: AppColors.grey300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: AppColors.grey300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Theme Preference
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<String>(
                          value: _theme,
                          items: const [
                            DropdownMenuItem(value: 'System', child: Text('System Default')),
                            DropdownMenuItem(value: 'Light', child: Text('Light')),
                            DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _theme = value!;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: AppColors.grey300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: AppColors.grey300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          
          // Complete Button
          Padding(
            padding: EdgeInsets.only(bottom: 32.h),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return LoadingButton(
                  onPressed: widget.onComplete,
                  isLoading: userProvider.isLoading,
                  text: 'Complete Setup',
                  icon: Icon(
                    Icons.check_circle_outline,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
