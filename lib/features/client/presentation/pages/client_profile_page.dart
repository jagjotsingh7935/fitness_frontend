import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/chart_card.dart';
import '../widgets/charts/weight_progress_chart.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/preferences_section.dart';
import '../widgets/profile_hero.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ClientScaffold(
      greeting: 'Settings & Stats',
      title: 'Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileHero(),
          const ChartCard(
            title: 'Weight Progress',
            periodLabel: '30 Days',
            child: WeightProgressChart(),
          ),
          const SectionHeader(title: 'Body Metrics'),
          _BodyMetricsGrid(),
          const SectionHeader(title: 'Account'),
          PreferencesSection(
            items: [
              PreferenceItemModel(
                icon: const Icon(Icons.person_outline, color: AppColors.primary),
                iconBg: AppColors.primary.withValues(alpha: 0.15),
                title: 'Edit Profile',
                subtitle: 'Name, photo, goals',
              ),
              PreferenceItemModel(
                icon: const Icon(Icons.photo_camera_outlined,
                    color: AppColors.green),
                iconBg: AppColors.green.withValues(alpha: 0.15),
                title: 'Progress Photos',
                subtitle: 'Track your transformation',
              ),
              PreferenceItemModel(
                icon: const Text('🏆', style: TextStyle(fontSize: 18)),
                iconBg: AppColors.yellow.withValues(alpha: 0.15),
                title: 'Achievements',
                subtitle: '3 badges earned',
              ),
              PreferenceItemModel(
                icon:
                    const Icon(Icons.notifications_none, color: AppColors.accent),
                iconBg: AppColors.accent.withValues(alpha: 0.15),
                title: 'Notifications',
                subtitle: 'Reminders & alerts',
              ),
              PreferenceItemModel(
                icon: const Text('🚪', style: TextStyle(fontSize: 18)),
                iconBg: AppColors.orange.withValues(alpha: 0.15),
                title: 'Log Out',
                subtitle: 'Sign out of account',
                arrowColor: AppColors.orange,
                onTap: () => context.go(AppRouter.loginPath),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyMetricsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <StatCardModel>[
      StatCardModel(
        value: '82.4',
        label: 'Weight (kg)',
        icon: const Text('⚖️', style: TextStyle(fontSize: 16)),
        accent: AppColors.primary,
        changeLabel: '↓ −3.2 kg',
        changeDirection: StatChangeDirection.down,
      ),
      StatCardModel(
        value: '178',
        label: 'Height (cm)',
        icon: const Text('📏', style: TextStyle(fontSize: 16)),
        accent: AppColors.green,
        changeLabel: 'BMI: 26.0',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: '78',
        label: 'Goal (kg)',
        icon: const Text('🎯', style: TextStyle(fontSize: 16)),
        accent: AppColors.orange,
        changeLabel: '4.4 kg left',
        changeDirection: StatChangeDirection.down,
      ),
      StatCardModel(
        value: '24%',
        label: 'Body Fat',
        icon: const Text('📊', style: TextStyle(fontSize: 16)),
        accent: AppColors.accent,
        changeLabel: '↓ −2%',
        changeDirection: StatChangeDirection.down,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => StatCard(model: items[i]),
    );
  }
}

