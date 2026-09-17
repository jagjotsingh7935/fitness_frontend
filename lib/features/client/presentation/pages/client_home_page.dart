import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/notification_service.dart';
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
import '../widgets/streak_celebration_dialog.dart';
import '../widgets/achievement_unlocked_dialog.dart';
import '../widgets/all_achievements_sheet.dart';
import '../widgets/trainer_card.dart';

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
  Map<String, dynamic>? _trainerData;
  
  // Workouts for today
  List<Map<String, dynamic>> _todayWorkouts = [];
  int _estimatedWorkoutMins = 0;

  // Hydration data
  int _hydrationCups = 0;
  int _targetCups = 8;
  
  // Summary data for chart
  List<Map<String, dynamic>> _kcalSummary = [];

  // Streak & Achievements live data
  int _streakDays = 1;
  int _streakLitDots = 1;
  List<dynamic> _weekDots = [];
  List<BadgeModel> _badges = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    NotificationService().initialize().then((_) {
      NotificationService().scheduleDailyDietReminder();
    });
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    setState(() => _isLoading = true);
    
    try {
      final today = DateTime.now();
      final todayWeekday = (today.weekday - 1).clamp(0, 6); // 0 = Monday, 6 = Sunday
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
      
      // 4. Fetch user profile for name, trainer, and goal badge
      final profileResponse = await _dio.get('/accounts/api/me/');
      if (profileResponse.statusCode == 200) {
        final userData = profileResponse.data;
        _clientName = userData['first_name'] ?? userData['full_name']?.split(' ').first ?? 'User';
        
        if (userData['categories'] != null && (userData['categories'] as List).isNotEmpty) {
          _goalBadge = userData['categories'][0]['name'] ?? 'Weight Loss';
        }

        if (userData['active_trainers'] != null && (userData['active_trainers'] as List).isNotEmpty) {
          _trainerData = Map<String, dynamic>.from(userData['active_trainers'][0]);
        }
      }

      // 5. Fetch assigned workout plans for today
      try {
        final workoutsRes = await _dio.get('/fitness/api/my-workout-plans/');
        if (workoutsRes.statusCode == 200) {
          List<dynamic> allW = [];
          if (workoutsRes.data is List) {
            allW = workoutsRes.data;
          } else if (workoutsRes.data is Map && workoutsRes.data['results'] is List) {
            allW = workoutsRes.data['results'];
          }
          final todaysList = allW.where((p) => p['day_of_week'] == todayWeekday).toList();
          _todayWorkouts = List<Map<String, dynamic>>.from(todaysList);

          int totalSec = 0;
          for (final p in _todayWorkouts) {
            final sets = p['sets'] ?? 3;
            final reps = p['reps'] ?? 10;
            final timePerRep = p['time_per_rep_seconds'] ?? 4;
            totalSec += (sets * reps * timePerRep) as int;
          }
          _estimatedWorkoutMins = (totalSec ~/ 60).clamp(15, 90);
        }
      } catch (_) {}

      // 6. Fetch hydration targets & logs
      try {
        final hydTargetsRes = await _dio.get('/fitness/api/hydration-targets/');
        if (hydTargetsRes.statusCode == 200) {
          List<dynamic> ht = hydTargetsRes.data is List ? hydTargetsRes.data : hydTargetsRes.data['results'] ?? [];
          final todayTarget = ht.firstWhere((t) => t['day_of_week'] == todayWeekday, orElse: () => null);
          if (todayTarget != null) {
            _targetCups = todayTarget['target_cups'] ?? 8;
          }
        }

        final hydLogsRes = await _dio.get('/fitness/api/hydration-logs/');
        if (hydLogsRes.statusCode == 200) {
          List<dynamic> hl = hydLogsRes.data is List ? hydLogsRes.data : hydLogsRes.data['results'] ?? [];
          final todayHyd = hl.firstWhere((l) => l['date'] == todayDate, orElse: () => null);
          if (todayHyd != null) {
            _hydrationCups = todayHyd['actual_cups'] ?? 0;
          }
        }
      } catch (_) {}

      // 7. Check-in for daily streak & auto-unlocked achievements
      try {
        final checkinRes = await _dio.post('/fitness/api/client-checkin/');
        if (checkinRes.statusCode == 200 && checkinRes.data is Map) {
          final data = checkinRes.data as Map<String, dynamic>;
          final streakData = data['streak'] as Map<String, dynamic>?;
          if (streakData != null) {
            _streakDays = streakData['current_streak'] ?? 1;
            _streakLitDots = streakData['lit_dots'] ?? 1;
            _weekDots = (streakData['week_dots'] as List?) ?? [];

            // If it is the first open today, trigger celebration dialog and notification!
            final isFirstOpenToday = streakData['is_first_open_today'] == true;
            if (isFirstOpenToday && mounted) {
              // Send mobile notification
              NotificationService().showNotification(
                id: 101,
                title: '🔥 Day $_streakDays Streak!',
                body: "Awesome work! You're on a $_streakDays day streak. Keep it up!",
              );

              // Schedule popup celebration modal after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  StreakCelebrationDialog.show(
                    context,
                    streakDays: _streakDays,
                    weekDots: _weekDots,
                  );
                }
              });
            }
          }

          // Badges
          if (data['badges'] is List) {
            final bList = (data['badges'] as List).map((b) => BadgeModel(
              emoji: b['emoji'] ?? '🏆',
              name: b['name'] ?? '',
              description: b['description'] ?? '',
              earned: b['earned'] == true,
            )).toList();
            _badges = bList;
          }

          // Newly unlocked badges celebration
          if (data['newly_unlocked'] is List && (data['newly_unlocked'] as List).isNotEmpty) {
            final newlyList = List<Map<String, dynamic>>.from(data['newly_unlocked']);
            final newlyKeys = <String>[];

            for (final n in newlyList) {
              final emoji = n['emoji'] ?? '🏆';
              final title = n['name'] ?? 'Achievement Unlocked';
              final desc = n['description'] ?? '';
              final key = n['badge_key'] ?? '';
              newlyKeys.add(key);

              // Mobile notification
              NotificationService().showNotification(
                id: 200 + (key.hashCode.abs() % 1000),
                title: '🏆 Achievement Unlocked: $title',
                body: desc,
              );

              // Show modal celebration
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  AchievementUnlockedDialog.show(
                    context,
                    emoji: emoji,
                    title: title,
                    description: desc,
                  );
                }
              });
            }

            // Mark seen on backend
            try {
              await _dio.post('/fitness/api/client-achievements/mark-seen/', data: {
                'badge_keys': newlyKeys,
              });
            } catch (_) {}
          }
        }
      } catch (_) {}
      
      setState(() => _isLoading = false);
    } catch (e) {
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
          ),
        ),
      );
    }

    return ClientScaffold(
      greeting: _getGreeting(),
      title: _clientName,
      showNotificationDot: true,
      onNotificationTap: () => NotificationsSheet.show(context),
      onRefresh: _fetchHomeData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GoalHeroCard(
            goalBadge: _goalBadge,
            title: "Today's Goal",
            subtitle: '$_todayTargetKcal kcal target',
            burned: _todayBurnedKcal.toString(),
            remaining: _remainingKcal.toString(),
            donePct: _donePct.toInt(),
            onStartWorkout: () => context.go('${AppRouter.clientPath}/plans'),
          ),
          const SectionHeader(title: 'Your Streak'),
          StreakCard(
            days: _streakDays,
            litDots: _streakLitDots,
            weekDots: _weekDots,
            onTap: () => StreakCelebrationDialog.show(
              context,
              streakDays: _streakDays,
              weekDots: _weekDots,
            ),
          ),
          const SizedBox(height: 14),

          const SectionHeader(title: 'Quick Access', actionLabel: null),
          QuickActionsGrid(
            items: [
              QuickActionModel(
                label: 'Workouts',
                icon: Icons.fitness_center_rounded,
                gradient: const [Color(0xFFE94560), Color(0xFF8B0D2A)],
                onTap: () => context.go('${AppRouter.clientPath}/plans'),
              ),
              QuickActionModel(
                label: 'Diet Plan',
                icon: Icons.restaurant_menu_rounded,
                gradient: const [Color(0xFFFF8C00), Color(0xFFE5C07B)],
                onTap: () => context.go('${AppRouter.clientPath}/plans'),
              ),
              QuickActionModel(
                label: 'Exercises',
                icon: Icons.play_circle_fill_rounded,
                gradient: const [Color(0xFF0056FF), Color(0xFF00C9FF)],
                onTap: () => context.go('${AppRouter.clientPath}/exercises'),
              ),
              QuickActionModel(
                label: 'Profile',
                icon: Icons.person_rounded,
                gradient: const [Color(0xFF00F5A0), Color(0xFF00796B)],
                onTap: () => context.go('${AppRouter.clientPath}/profile'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const SectionHeader(title: "Today's Performance", actionLabel: 'Weekly ›'),
          _StatsGrid(
            burnedKcal: _todayBurnedKcal,
            todayWorkoutsCount: _todayWorkouts.length,
            activeMins: _estimatedWorkoutMins > 0 ? '${_estimatedWorkoutMins}m' : '30m',
            hydration: '$_hydrationCups / $_targetCups',
          ),
          const SizedBox(height: 14),

          ChartCard(
            title: 'Calorie Trend',
            periodLabel: '7 Days',
            child: CalorieTrendChart(summaryData: _kcalSummary),
          ),
          const SizedBox(height: 14),

          const SectionHeader(title: 'Hydration', actionLabel: 'Log ›'),
          HydrationCard(onUpdated: _fetchHomeData),
          const SizedBox(height: 14),

          SectionHeader(
            title: "Today's Routine",
            actionLabel: 'Schedule ›',
            onActionTap: () => context.go('${AppRouter.clientPath}/plans'),
          ),
          _buildTodayWorkoutsList(),
          const SizedBox(height: 14),

          const SectionHeader(title: 'Your Coach'),
          TrainerCard(trainerData: _trainerData),
          const SizedBox(height: 14),

          SectionHeader(
            title: 'Achievements',
            actionLabel: 'All ›',
            onActionTap: () => AllAchievementsSheet.show(
              context,
              badges: _getAllAchievementsList(),
            ),
          ),
          const SizedBox(height: 4),
          BadgesRow(
            badges: _badges.isNotEmpty
                ? _badges
                : _getAllAchievementsList().take(5).toList(),
            onBadgeTap: (_) => AllAchievementsSheet.show(
              context,
              badges: _getAllAchievementsList(),
            ),
          ),
        ],
      ),
    );
  }

  List<BadgeModel> _getAllAchievementsList() {
    final defaultBadges = [
      const BadgeModel(
        emoji: '🏆',
        name: 'First Step',
        earned: true,
        description: 'Welcome! You started your daily fitness journey.',
      ),
      BadgeModel(
        emoji: '🔥',
        name: '3-Day Streak',
        earned: _streakDays >= 3,
        description: 'Consistent warrior! 3 consecutive active days logged.',
      ),
      BadgeModel(
        emoji: '⚡',
        name: '7-Day Warrior',
        earned: _streakDays >= 7,
        description: '7 consecutive days strong! Building real discipline.',
      ),
      BadgeModel(
        emoji: '🥇',
        name: '14-Day Legend',
        earned: _streakDays >= 14,
        description: 'Two full weeks of unstoppable fitness momentum!',
      ),
      BadgeModel(
        emoji: '👑',
        name: '30-Day Master',
        earned: _streakDays >= 30,
        description: 'A whole month of dedicated fitness excellence.',
      ),
      BadgeModel(
        emoji: '💧',
        name: 'Hydration Hero',
        earned: _badges.any((b) => b.name == 'Hydration Hero' && b.earned),
        description: 'Reached 100% of your daily target water intake.',
      ),
      BadgeModel(
        emoji: '🎯',
        name: 'Goal Crusher',
        earned: _badges.any((b) => b.name == 'Goal Crusher' && b.earned),
        description: 'Completed scheduled diet meals & hit calorie target.',
      ),
      BadgeModel(
        emoji: '💪',
        name: 'Workout Ready',
        earned: _badges.any((b) => b.name == 'Workout Ready' && b.earned) || _todayWorkouts.isNotEmpty,
        description: 'Equipped with personalized training routine from coach.',
      ),
      BadgeModel(
        emoji: '🥗',
        name: 'Diet Dedicated',
        earned: _badges.any((b) => b.name == 'Diet Dedicated' && b.earned) || _todayBurnedKcal > 0,
        description: 'Actively tracking and following assigned nutrition plan.',
      ),
    ];

    final result = <BadgeModel>[];
    for (final db in defaultBadges) {
      final existing = _badges.where((b) => b.name.toLowerCase() == db.name.toLowerCase()).firstOrNull;
      if (existing != null) {
        result.add(BadgeModel(
          emoji: existing.emoji.isNotEmpty ? existing.emoji : db.emoji,
          name: existing.name,
          earned: existing.earned,
          description: existing.description.isNotEmpty ? existing.description : db.description,
        ));
      } else {
        result.add(db);
      }
    }

    for (final b in _badges) {
      if (!result.any((r) => r.name.toLowerCase() == b.name.toLowerCase())) {
        result.add(b);
      }
    }

    return result;
  }

  Widget _buildTodayWorkoutsList() {
    if (_todayWorkouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141828),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bedtime_rounded, color: Color(0xFF00F5A0), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Rest & Muscle Recovery Day',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'No workouts assigned for today. Stay hydrated & recover!',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('${AppRouter.clientPath}/plans'),
              child: const Text('View All', style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _todayWorkouts.take(3).map((plan) {
        final ex = plan['exercise_detail'] ?? {};
        final title = ex['title'] ?? 'Exercise';
        final sets = plan['sets'] ?? 3;
        final reps = plan['reps'] ?? 10;
        final notes = plan['notes']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141828),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE94560), Color(0xFF8B0D2A)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$sets Sets × $reps Reps ${notes.isNotEmpty ? '· $notes' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int burnedKcal;
  final int todayWorkoutsCount;
  final String activeMins;
  final String hydration;
  
  const _StatsGrid({
    required this.burnedKcal,
    required this.todayWorkoutsCount,
    required this.activeMins,
    required this.hydration,
  });

  @override
  Widget build(BuildContext context) {
    final items = <StatCardModel>[
      StatCardModel(
        value: todayWorkoutsCount > 0 ? '$todayWorkoutsCount Ex' : 'Rest',
        label: 'Daily Routine',
        icon: const Icon(Icons.fitness_center_rounded),
        accent: const Color(0xFF00F5A0),
        changeLabel: todayWorkoutsCount > 0 ? 'Assigned' : 'Recovery',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: activeMins,
        label: 'Active Target',
        icon: const Icon(Icons.schedule_rounded),
        accent: AppColors.orange,
        changeLabel: 'On track',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: '$burnedKcal kcal',
        label: 'Cal Burned',
        icon: const Icon(Icons.local_fire_department_rounded),
        accent: const Color(0xFFE94560),
        changeLabel: 'Today',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: '$hydration Cups',
        label: 'Hydration',
        icon: const Icon(Icons.water_drop_rounded),
        accent: const Color(0xFF00C9FF),
        changeLabel: 'Water',
        changeDirection: StatChangeDirection.up,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => StatCard(model: items[i]),
    );
  }
}