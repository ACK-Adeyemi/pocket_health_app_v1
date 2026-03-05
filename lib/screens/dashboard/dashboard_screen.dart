import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/quick_check_in_provider.dart';
import '../../providers/health_tracking_provider.dart';
import '../../models/user_profile.dart';
import '../../models/health_entry.dart';
import '../../models/health_condition.dart';
import '../../utils/app_colors.dart';
import '../health/health_tracking_screen.dart';
import '../community/community_screen.dart';
import '../health/quick_check_in_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserProfileLegacy();
    _checkOnboarding();
    
    if (mounted && userProvider.userProfile != null) {
      final healthProvider = Provider.of<HealthTrackingProvider>(context, listen: false);
      await healthProvider.loadHealthEntries(userProvider.userProfile!.uid);
    }
  }

  void _showQuickCheckIn() {
    QuickCheckInModal.show(context);
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _checkOnboarding() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;
    
    if (userProfile != null && !userProfile.hasSeenQuickCheckInOnboarding) {
      _showOnboardingDialog();
    }
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.bolt, color: AppColors.accent),
            SizedBox(width: 8.w),
            const Text('New: Daily Pulse'),
          ],
        ),
        content: const Text(
          'We\'ve added a faster way to track your health. Use the new Check-In button to log your vitals in under 10 seconds.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).markQuickCheckInOnboardingAsSeen();
              Navigator.pop(context);
            },
            child: const Text('Got it!'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).markQuickCheckInOnboardingAsSeen();
              Navigator.pop(context);
              _showQuickCheckIn();
            },
            child: const Text('Try it now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;
    final isGroupA = userProfile?.abTestGroup == 'A';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : (_currentIndex == 2 ? 0 : _currentIndex),
        children: [
          _ProfileTab(onTabChange: _onTabChanged, onRefresh: _loadData),
          const HealthTrackingScreen(),
          const CommunityScreen(),
          const _LearnTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showQuickCheckIn();
          } else {
            _onTabChanged(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: const Icon(Icons.favorite),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isGroupA ? 1.0 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: isGroupA ? Colors.white : AppColors.primary,
                size: 24.sp,
              ),
            ),
            label: 'Check-In',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Discuss',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Learn',
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Function(int) onTabChange;
  final Future<void> Function() onRefresh;

  const _ProfileTab({required this.onTabChange, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.userProfile;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                SizedBox(height: 32.h),
                if (user != null) ...[
                  _buildHealthOverview(user),
                  SizedBox(height: 16.h),
                  const _WellbeingSnapshotCard(),
                  SizedBox(height: 24.h),
                ],
                _buildDailyPulseCard(context),
                _buildQuickActions(context, user),
                SizedBox(height: 24.h),
                _buildRecentActivity(),
                SizedBox(height: 32.h),
                _buildSignOutButton(context),
                SizedBox(height: 24.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(UserProfile? user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}!',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                user?.name ?? 'Welcome',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (user != null) ...[
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Column(
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(32.r),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 32.sp,
              ),
            ),
            if (user != null && (user.role == UserRole.admin || user.role == UserRole.moderator)) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: user.role == UserRole.admin
                      ? AppColors.accent.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: user.role == UserRole.admin ? AppColors.accent : AppColors.primary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.verified_user,
                      size: 14.sp,
                      color: user.role == UserRole.admin ? AppColors.accentDark : AppColors.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      user.role.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: user.role == UserRole.admin ? AppColors.accentDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHealthOverview(UserProfile user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Overview',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _HealthMetric(
                  label: 'BMI',
                  value: user.bmi.toStringAsFixed(1),
                  subtitle: user.bmiCategory,
                ),
              ),
              Expanded(
                child: _HealthMetric(
                  label: 'Age',
                  value: user.age.toString(),
                  subtitle: 'years',
                ),
              ),
              Expanded(
                child: _HealthMetric(
                  label: 'Conditions',
                  value: user.healthConditions.length.toString(),
                  subtitle: 'tracked',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPulseCard(BuildContext context) {
    return Consumer<QuickCheckInProvider>(
      builder: (context, quickProvider, child) {
        final condition = quickProvider.selectedCondition;
        final streak = quickProvider.streak;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Pulse',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            condition != null
                ? _buildActiveCheckInCard(context, condition)
                : _buildCompletionStreakCard(streak),
            SizedBox(height: 32.h),
          ],
        );
      },
    );
  }

  Widget _buildActiveCheckInCard(BuildContext context, HealthCondition condition) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt, color: AppColors.primary, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Check-In',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Log your ${condition.name}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => QuickCheckInModal.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size(80.w, 36.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStreakCard(int streak) {
    String currentEmoji;
    if (streak == 0) {
      currentEmoji = '🌱';
    } else if (streak <= 3) {
      currentEmoji = '👏';
    } else if (streak <= 6) {
      currentEmoji = '🎉';
    } else if (streak <= 9) {
      currentEmoji = '🔥';
    } else if (streak <= 12) {
      currentEmoji = '🚀';
    } else {
      currentEmoji = '🏆';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(currentEmoji, style: TextStyle(fontSize: 40.sp)),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thanks for checking in today. Well done!',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Streak: $streak days',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Please come back tomorrow for your next check in. Feel free to log more detailed entries on the Track page.',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          _buildMilestoneRow(streak),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(int currentStreak) {
    final milestones = [
      {'val': 0, 'emoji': '🌱'},
      {'val': 1, 'emoji': '👏'},
      {'val': 4, 'emoji': '🎉'},
      {'val': 7, 'emoji': '🔥'},
      {'val': 10, 'emoji': '🚀'},
      {'val': 13, 'emoji': '🏆'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: milestones.map((m) {
        final isUnlocked = currentStreak >= (m['val'] as int);
        return Column(
          children: [
            Text(
              m['val'].toString(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? AppColors.textPrimary : AppColors.textLight,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              m['emoji'] as String,
              style: TextStyle(
                fontSize: 20.sp,
                color: isUnlocked ? null : Colors.grey.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 4.h),
            Icon(
              isUnlocked ? Icons.check_circle : Icons.lock,
              size: 14.sp,
              color: isUnlocked ? AppColors.success : AppColors.textLight,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserProfile? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 1.2,
          children: [
            _QuickActionCard(
              icon: Icons.add_circle_outline,
              title: 'Log Health Data',
              subtitle: 'Track symptoms, vitals',
              color: AppColors.secondary,
              onTap: () {
                if (user?.preferredLoggingMode == 'quick') {
                  QuickCheckInModal.show(context);
                } else {
                  onTabChange(1);
                }
              },
            ),
            _QuickActionCard(
              icon: Icons.calendar_today,
              title: 'Appointments',
              subtitle: 'Manage schedule',
              color: AppColors.accent,
              onTap: () {},
            ),
            _QuickActionCard(
              icon: Icons.school,
              title: 'Learn',
              subtitle: 'Health education',
              color: AppColors.info,
              onTap: () => onTabChange(4),
            ),
            _QuickActionCard(
              icon: Icons.chat_bubble_outline,
              title: 'Discuss',
              subtitle: 'Connect & share',
              color: AppColors.primary,
              onTap: () => onTabChange(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16.h),
              Text(
                'No recent activity',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Start logging your health data to see your progress here.',
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
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await authProvider.signOut();
          userProvider.clearUserProfile();
          if (context.mounted) {
            context.go('/welcome');
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          minimumSize: Size(double.infinity, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _WellbeingSnapshotCard extends StatelessWidget {
  const _WellbeingSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return Consumer2<HealthTrackingProvider, UserProvider>(
      builder: (context, healthProvider, userProvider, child) {
        final entries = healthProvider.getEntriesForCondition('wellbeing')
            .where((e) => e.metricId == 'overall')
            .toList();
        
        final last7Days = List.generate(7, (index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          final entry = entries.firstWhere(
            (e) => e.timestamp.year == date.year && 
                   e.timestamp.month == date.month && 
                   e.timestamp.day == date.day,
            orElse: () => HealthEntry(
              id: '', userId: '', conditionId: '', metricId: '', value: null, timestamp: date,
            ),
          );
          return {'date': date, 'value': entry.value};
        });

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wellbeing 7 Day Snapshot',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: last7Days.map((day) {
                  final date = day['date'] as DateTime;
                  final value = day['value'] as String?;
                  final dayLabel = DateFormat('E').format(date).substring(0, 3).toUpperCase();
                  
                  String emoji = '';
                  if (value == 'good') emoji = '😊\u{FE0F}';
                  else if (value == 'okay') emoji = '😐\u{FE0F}';
                  else if (value == 'not_great') emoji = '😟\u{FE0F}';

                  return Column(
                    children: [
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (emoji.isNotEmpty)
                        Text(emoji, style: TextStyle(fontSize: 24.sp))
                      else
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.grey200, width: 2),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LearnTab extends StatelessWidget {
  const _LearnTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learn',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Welcome to the Learn section! Here you can find seminars and videos to help you understand and manage your specific health conditions.',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Learn about typical symptoms, management strategies for when you\'re alone, and when to consult your GP. We also provide education to help you identify and avoid health misinformation.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 48.h),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64.sp,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _HealthMetric({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                size: 20.sp,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
