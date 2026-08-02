import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../models/demo_models.dart';
import '../widgets/badges_row.dart';
import '../widgets/chart_card.dart';
import '../widgets/charts/calorie_trend_chart.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/goal_hero_card.dart';
import '../widgets/hydration_card.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/trainer_card.dart';
import '../widgets/workout_cards.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  
  // Kcal tracking data
  int _todayTargetKcal = 2200;
  int _todayBurnedKcal = 0;
  int _remainingKcal = 2200;
  double _donePct = 0;
  String _goalBadge = 'Weight Loss';
  String _clientName = 'Loading...';
  
  // Summary data for chart
  List<Map<String, dynamic>> _kcalSummary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    setState(() => _isLoading = true);
    
    try {
      final today = DateTime.now();
      final todayWeekday = today.weekday - 1; // 0 = Monday, 6 = Sunday
      final todayDate = today.toIso8601String().split('T')[0];
      
      // 1. Fetch kcal targets
      final targetsResponse = await _dio.get('/fitness/api/kcal-targets/');
      if (targetsResponse.statusCode == 200) {
        final targetsData = targetsResponse.data;
        List<dynamic> targets = [];
        
        if (targetsData is Map && targetsData.containsKey('results')) {
          targets = targetsData['results'];
        } else if (targetsData is List) {
          targets = targetsData;
        }
        
        // Find today's target
        final todayTarget = targets.firstWhere(
          (t) => t['day_of_week'] == todayWeekday,
          orElse: () => null,
        );
        
        if (todayTarget != null) {
          _todayTargetKcal = todayTarget['target_kcal'] ?? 2200;
        }
      }
      
      // 2. Fetch today's kcal log
      final logsResponse = await _dio.get('/fitness/api/kcal-logs/');
      if (logsResponse.statusCode == 200) {
        final logsData = logsResponse.data;
        List<dynamic> logs = [];
        
        if (logsData is Map && logsData.containsKey('results')) {
          logs = logsData['results'];
        } else if (logsData is List) {
          logs = logsData;
        }
        
        // Find today's log
        final todayLog = logs.firstWhere(
          (log) => log['date'] == todayDate,
          orElse: () => null,
        );
        
        if (todayLog != null) {
          _todayBurnedKcal = todayLog['actual_kcal'] ?? 0;
        }
      }
      
      // 3. Fetch kcal summary for chart (last 7 days)
      final startDate = today.subtract(const Duration(days: 6)).toIso8601String().split('T')[0];
      final endDate = todayDate;
      
      final summaryResponse = await _dio.get(
        '/fitness/api/kcal-summary/?start_date=$startDate&end_date=$endDate'
      );
      
      if (summaryResponse.statusCode == 200) {
        _kcalSummary = List<Map<String, dynamic>>.from(summaryResponse.data);
      }
      
      // Calculate remaining and percentage
      _remainingKcal = _todayTargetKcal - _todayBurnedKcal;
      if (_remainingKcal < 0) _remainingKcal = 0;
      _donePct = (_todayBurnedKcal / _todayTargetKcal) * 100;
      if (_donePct > 100) _donePct = 100;
      
      // 4. Fetch user profile for name and goal badge
      final profileResponse = await _dio.get('/accounts/api/me/');
      if (profileResponse.statusCode == 200) {
        final userData = profileResponse.data;
        _clientName = userData['full_name']?.split(' ').first ?? 'User';
        
        // Get goal badge from user's selected categories
        if (userData['selected_categories'] != null && 
            (userData['selected_categories'] as List).isNotEmpty) {
          _goalBadge = (userData['selected_categories'] as List).first;
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching home data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌤';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ClientScaffold(
        greeting: 'Loading...',
        title: '',
        showNotificationDot: true,
        onNotificationTap: () => NotificationsSheet.show(context),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return ClientScaffold(
      greeting: _getGreeting(),
      title: _clientName,
      showNotificationDot: true,
      onNotificationTap: () => NotificationsSheet.show(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GoalHeroCard(
            goalBadge: _goalBadge,
            title: "Today's Goal",
            subtitle: '${_todayTargetKcal} kcal target',
            burned: _todayBurnedKcal.toString(),
            remaining: _remainingKcal.toString(),
            donePct: _donePct.toInt(),
            onStartWorkout: () => context.go('${AppRouter.clientPath}/workout-active'),
          ),
          const SectionHeader(title: 'Your Streak'),
          const StreakCard(days: 12, litDots: 7),
          SectionHeader(
            title: 'Quick Access',
            actionLabel: null,
          ),
          QuickActionsGrid(
            items: [
              QuickActionModel(
                label: 'Workout',
                icon: Icons.fitness_center,
                gradient: const [Color(0xFF1A3AFF), Color(0xFF7C3AED)],
                onTap: () => context.go('${AppRouter.clientPath}/workout-active'),
              ),
              QuickActionModel(
                label: 'Diet Plan',
                icon: Icons.restaurant_menu,
                gradient: const [Color(0xFFFF6F00), Color(0xFFFF9800)],
                onTap: () => context.go('${AppRouter.clientPath}/plans'),
              ),
              QuickActionModel(
                label: 'Videos',
                icon: Icons.play_circle,
                gradient: const [Color(0xFFC2185B), Color(0xFFE91E63)],
                onTap: () => context.go('${AppRouter.clientPath}/videos'),
              ),
              QuickActionModel(
                label: 'Profile',
                icon: Icons.person,
                gradient: const [Color(0xFF00796B), Color(0xFF009688)],
                onTap: () => context.go('${AppRouter.clientPath}/profile'),
              ),
            ],
          ),
          const SectionHeader(title: "Today's Stats", actionLabel: 'Weekly ›'),
          _StatsGrid(burnedKcal: _todayBurnedKcal),
          ChartCard(
            title: 'Calorie Trend',
            periodLabel: '7 Days',
            child: CalorieTrendChart(summaryData: _kcalSummary),
          ),
          const SectionHeader(title: 'Hydration', actionLabel: 'Log ›'),
          const HydrationCard(),
          SectionHeader(
            title: "Today's Workout",
            actionLabel: 'See all ›',
            onActionTap: () => context.go('${AppRouter.clientPath}/exercises'),
          ),
          WorkoutCards(
            items: DemoClientData.workoutCards,
            onTap: (_) => context.go('${AppRouter.clientPath}/workout-active'),
          ),
          const SectionHeader(title: 'Your Trainer'),
          const TrainerCard(),
          const SectionHeader(title: 'Achievements', actionLabel: 'All ›'),
          const SizedBox(height: 4),
          BadgesRow(
            badges: const [
              BadgeModel(emoji: '🏆', name: 'First Week', earned: true),
              BadgeModel(emoji: '🔥', name: '10 Day Streak', earned: true),
              BadgeModel(emoji: '💪', name: 'Power User', earned: true),
              BadgeModel(emoji: '🥇', name: '30 Day Goal', earned: false),
              BadgeModel(emoji: '⚡', name: 'Speed Run', earned: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int burnedKcal;
  
  const _StatsGrid({required this.burnedKcal});

  @override
  Widget build(BuildContext context) {
    final items = <StatCardModel>[
      StatCardModel(
        value: '8,240',
        label: 'Steps Today',
        icon: const Icon(Icons.show_chart),
        accent: AppColors.primary,
        changeLabel: '↑ +12%',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: '42m',
        label: 'Active Time',
        icon: const Icon(Icons.schedule),
        accent: AppColors.orange,
        changeLabel: '↑ On track',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: burnedKcal.toString(),
        label: 'Cal Burned',
        icon: const Icon(Icons.local_fire_department_outlined),
        accent: AppColors.green,
        changeLabel: '↑ Today',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: '72',
        label: 'BPM Avg',
        icon: const Icon(Icons.favorite_border),
        accent: AppColors.accent,
        changeLabel: '↓ Resting',
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