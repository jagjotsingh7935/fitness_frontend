import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/network/dio_client.dart';
import '../widgets/chart_card.dart';
import '../widgets/charts/macro_split_chart.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/diet_plan_card.dart';

class ClientPlansPage extends StatefulWidget {
  const ClientPlansPage({super.key});

  @override
  State<ClientPlansPage> createState() => _ClientPlansPageState();
}

class _ClientPlansPageState extends State<ClientPlansPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;

  int _selectedTab = 0; // 0 = Workout, 1 = Diet
  int _selectedDay = (DateTime.now().weekday - 1).clamp(0, 6); // 0=Mon ... 6=Sun

  // Workout Plans Data
  List<Map<String, dynamic>> _allWorkoutPlans = [];
  bool _isLoadingWorkouts = true;
  String? _workoutError;

  // Search & Filter state for Workout Schedule
  final TextEditingController _workoutSearchController = TextEditingController();
  String _workoutSearchQuery = '';
  String _selectedWorkoutCategory = 'All';
  List<String> _workoutCategories = ['All'];

  // Nutrition Data
  List<Map<String, dynamic>> _kcalTargets = [];
  int _todayBurnedKcal = 0;
  bool _isLoadingNutrition = true;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _fetchWorkoutPlans();
    _fetchNutritionData();
  }

  @override
  void dispose() {
    _workoutSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkoutPlans() async {
    setState(() {
      _isLoadingWorkouts = true;
      _workoutError = null;
    });

    try {
      final response = await _dio.get('/fitness/api/my-workout-plans/');
      if (response.statusCode == 200) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map && response.data['results'] is List) {
          data = response.data['results'];
        }
        final plansList = List<Map<String, dynamic>>.from(data);
        final Set<String> cats = {'All'};
        for (final p in plansList) {
          final ex = p['exercise_detail'];
          if (ex is Map && ex['categories'] is List) {
            for (final c in (ex['categories'] as List)) {
              final name = c is Map ? c['name']?.toString() : c.toString();
              if (name != null && name.trim().isNotEmpty) {
                cats.add(name.trim());
              }
            }
          }
        }

        setState(() {
          _allWorkoutPlans = plansList;
          _workoutCategories = cats.toList();
          _isLoadingWorkouts = false;
        });
      }
    } catch (e) {
      setState(() {
        _workoutError = 'Failed to load workout schedule';
        _isLoadingWorkouts = false;
      });
    }
  }

  Future<void> _fetchNutritionData() async {
    setState(() => _isLoadingNutrition = true);
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Targets
      final targetsRes = await _dio.get('/fitness/api/kcal-targets/');
      if (targetsRes.statusCode == 200) {
        List<dynamic> targets = [];
        if (targetsRes.data is List) {
          targets = targetsRes.data;
        } else if (targetsRes.data is Map && targetsRes.data['results'] is List) {
          targets = targetsRes.data['results'];
        }
        _kcalTargets = List<Map<String, dynamic>>.from(targets);
      }

      // Today's log
      final logsRes = await _dio.get('/fitness/api/kcal-logs/');
      if (logsRes.statusCode == 200) {
        List<dynamic> logs = [];
        if (logsRes.data is List) {
          logs = logsRes.data;
        } else if (logsRes.data is Map && logsRes.data['results'] is List) {
          logs = logsRes.data['results'];
        }
        final todayLog = logs.firstWhere((l) => l['date'] == today, orElse: () => null);
        if (todayLog != null) {
          _todayBurnedKcal = todayLog['actual_kcal'] ?? 0;
        }
      }

      setState(() => _isLoadingNutrition = false);
    } catch (_) {
      setState(() => _isLoadingNutrition = false);
    }
  }

  void _showLogKcalDialog() {
    final kcalCtrl = TextEditingController(text: _todayBurnedKcal > 0 ? _todayBurnedKcal.toString() : '');
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.local_fire_department_rounded, color: Color(0xFFE94560), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Log Today\'s Calories',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kcalCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Calories (kcal) *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF111425),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Notes (e.g. Lunch & Cardio)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF111425),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final val = int.tryParse(kcalCtrl.text);
                      if (val == null || val <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter valid calories')),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        final today = DateTime.now().toIso8601String().split('T')[0];
                        await _dio.post('/fitness/api/kcal-logs/', data: {
                          'date': today,
                          'actual_kcal': val,
                          'notes': notesCtrl.text.trim(),
                        });
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        _fetchNutritionData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Calories logged successfully!'),
                              backgroundColor: Color(0xFF00F5A0),
                            ),
                          );
                        }
                      } on DioException catch (e) {
                        setDialogState(() => isSaving = false);
                        final msg = e.response?.data is Map
                            ? (e.response?.data['detail'] ?? e.response?.data['error'] ?? e.response?.data['date'] ?? e.response?.data.values.join(', '))
                            : (e.message ?? 'Failed to log calories');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.redAccent),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Log'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetailSheet(Map<String, dynamic> plan) {
    final exercise = plan['exercise_detail'] ?? {};
    final title = exercise['title'] ?? 'Exercise';
    final desc = exercise['description'] ?? 'No description provided.';
    final videoUrl = exercise['video_url'] as String?;
    final sets = plan['sets'] ?? 0;
    final reps = plan['reps'] ?? 0;
    final timePerRep = plan['time_per_rep_seconds'] ?? 0;
    final notes = plan['notes']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseDetailModal(
        title: title,
        description: desc,
        videoUrl: videoUrl,
        sets: sets,
        reps: reps,
        timePerRep: timePerRep,
        notes: notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClientScaffold(
      greeting: 'Assigned Schedule',
      title: 'Training & Diet',
      onRefresh: () async {
        if (_selectedTab == 0) {
          await _fetchWorkoutPlans();
        } else {
          await _fetchNutritionData();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF141828),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMainTab('🏋️ Workout Schedule', 0),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildMainTab('🥗 Nutrition & Diet', 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedTab == 0) _buildWorkoutTab() else _buildNutritionTab(),
        ],
      ),
    );
  }

  Widget _buildMainTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE94560) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB 1: WORKOUT SCHEDULE
  // ─────────────────────────────────────────────

  Widget _buildWorkoutTab() {
    if (_isLoadingWorkouts) {
      return const Padding(
        padding: EdgeInsets.all(60.0),
        child: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560))),
        ),
      );
    }

    if (_workoutError != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF141828),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 10),
            Text(_workoutError!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _fetchWorkoutPlans, child: const Text('Retry')),
          ],
        ),
      );
    }

    final query = _workoutSearchQuery.toLowerCase();
    final filteredDayPlans = _allWorkoutPlans.where((p) {
      final matchesDay = p['day_of_week'] == _selectedDay;

      final ex = p['exercise_detail'];
      final title = (ex is Map ? (ex['title'] ?? '') : '').toString().toLowerCase();
      final desc = (ex is Map ? (ex['description'] ?? '') : '').toString().toLowerCase();
      final notes = (p['notes'] ?? '').toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          title.contains(query) ||
          desc.contains(query) ||
          notes.contains(query);

      bool matchesCat = _selectedWorkoutCategory == 'All';
      if (!matchesCat && ex is Map && ex['categories'] is List) {
        matchesCat = (ex['categories'] as List).any((c) {
          final cName = c is Map ? c['name']?.toString() : c.toString();
          return cName == _selectedWorkoutCategory;
        });
      }

      return matchesDay && matchesSearch && matchesCat;
    }).toList()
      ..sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

    final dayTotalCount = _allWorkoutPlans.where((p) => p['day_of_week'] == _selectedDay).length;
    final currentDayName = _fullDays[_selectedDay];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Bar for Workout Schedule
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5C07B).withValues(alpha: 0.25),
              ),
            ),
            child: TextField(
              controller: _workoutSearchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (val) => setState(() => _workoutSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search today\'s workouts, notes, exercises...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE5C07B), size: 20),
                suffixIcon: _workoutSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _workoutSearchController.clear();
                          setState(() => _workoutSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),

        // 2. Category Filter Chips (if available)
        if (_workoutCategories.length > 1)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _workoutCategories.length,
              itemBuilder: (context, index) {
                final cat = _workoutCategories[index];
                final isSelected = _selectedWorkoutCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE94560),
                    backgroundColor: const Color(0xFF161B30),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFE94560) : Colors.white12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedWorkoutCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),

        // 3. Days of Week Chip Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (index) {
              final isSelected = _selectedDay == index;
              final isToday = (DateTime.now().weekday - 1) == index;
              final count = _allWorkoutPlans.where((p) => p['day_of_week'] == index).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedDay = index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE94560)
                          : const Color(0xFF141828),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE94560)
                            : isToday
                                ? const Color(0xFF00F5A0).withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.08),
                        width: isToday ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE94560).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _days[index].toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black.withValues(alpha: 0.25)
                                : count > 0
                                    ? const Color(0xFF00F5A0).withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 0 ? '$count Ex' : 'Rest',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : count > 0
                                      ? const Color(0xFF00F5A0)
                                      : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Day Routine Header & Live Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentDayName Routine',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_workoutSearchQuery.isNotEmpty || _selectedWorkoutCategory != 'All') ...[
                  GestureDetector(
                    onTap: () {
                      _workoutSearchController.clear();
                      setState(() {
                        _workoutSearchQuery = '';
                        _selectedWorkoutCategory = 'All';
                      });
                    },
                    child: const Text('Reset', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5C07B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${filteredDayPlans.length} / $dayTotalCount Ex',
                    style: const TextStyle(
                      color: Color(0xFFE5C07B),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 5. Day Exercise Cards List
        if (filteredDayPlans.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            decoration: BoxDecoration(
              color: const Color(0xFF141828),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _workoutSearchQuery.isNotEmpty || _selectedWorkoutCategory != 'All'
                        ? Icons.search_off_rounded
                        : Icons.bedtime_rounded,
                    color: const Color(0xFF00F5A0),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _workoutSearchQuery.isNotEmpty || _selectedWorkoutCategory != 'All'
                      ? 'No routines match your filters'
                      : 'Rest & Active Recovery Day',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  _workoutSearchQuery.isNotEmpty || _selectedWorkoutCategory != 'All'
                      ? 'Try adjusting your search keywords or category filters.'
                      : 'No exercises scheduled for this day. Hydrate, stretch, and get 8 hours of deep sleep to rebuild muscle fibers.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                ),
                if (_workoutSearchQuery.isNotEmpty || _selectedWorkoutCategory != 'All') ...[
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      _workoutSearchController.clear();
                      setState(() {
                        _workoutSearchQuery = '';
                        _selectedWorkoutCategory = 'All';
                      });
                    },
                    child: const Text('Reset Search & Filters', style: TextStyle(color: Color(0xFF00F5A0))),
                  ),
                ],
              ],
            ),
          )
        else
          ...filteredDayPlans.map((plan) {
            final exercise = plan['exercise_detail'] ?? {};
            final title = exercise['title'] ?? 'Exercise';
            final sets = plan['sets'] ?? 0;
            final reps = plan['reps'] ?? 0;
            final timePerRep = plan['time_per_rep_seconds'] ?? 0;
            final notes = plan['notes']?.toString() ?? '';
            final videoUrl = exercise['video_url'] as String?;
            final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141828),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showExerciseDetailSheet(plan),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Exercise Icon / Video Indicator
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE94560), Color(0xFF8B0D2A)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            hasVideo ? Icons.play_arrow_rounded : Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title & Target Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$sets Sets × $reps Reps',
                                      style: const TextStyle(
                                        color: Color(0xFF00F5A0),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (timePerRep > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${timePerRep}s / rep',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                              if (notes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Coach Note: $notes',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFE5C07B),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),

        // Weekly Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF101323),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFE5C07B), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Weekly Training Volume',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Exercises', '${_allWorkoutPlans.length}', const Color(0xFF00F5A0)),
                  _buildStatItem(
                    'Active Days',
                    '${List.generate(7, (i) => _allWorkoutPlans.where((p) => p['day_of_week'] == i).length).where((c) => c > 0).length} / 7',
                    const Color(0xFFE94560),
                  ),
                  _buildStatItem(
                    'Est. Duration',
                    '${(_allWorkoutPlans.fold<int>(0, (sum, p) => sum + (((p['sets'] as num? ?? 3) * (p['reps'] as num? ?? 10) * (p['time_per_rep_seconds'] as num? ?? 4)).toInt())) ~/ 60)} min',
                    const Color(0xFFE5C07B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  TAB 2: NUTRITION & DIET
  // ─────────────────────────────────────────────

  Widget _buildNutritionTab() {
    if (_isLoadingNutrition) {
      return const Padding(
        padding: EdgeInsets.all(60.0),
        child: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560))),
        ),
      );
    }

    final todayWeekday = (DateTime.now().weekday - 1).clamp(0, 6);
    final todayTarget = _kcalTargets.firstWhere(
      (t) => t['day_of_week'] == todayWeekday,
      orElse: () => {'target_kcal': 2200, 'protein_grams': 140, 'carbs_grams': 220, 'fat_grams': 65},
    );

    final targetKcal = todayTarget['target_kcal'] ?? 2200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Kcal Tracker Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F243E), Color(0xFF141828)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TODAY\'S CALORIE BUDGET',
                        style: TextStyle(
                          color: Color(0xFFE5C07B),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_todayBurnedKcal / $targetKcal kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showLogKcalDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Log Kcal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (targetKcal > 0 ? (_todayBurnedKcal / targetKcal) : 0.0).clamp(0.0, 1.0).toDouble(),
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5A0)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Macro Split Card
        ChartCard(
          title: 'Macro Split Target',
          periodLabel: 'Today',
          child: MacroSplitChart(kcalTargets: _kcalTargets),
        ),
        const SizedBox(height: 8),

        const DietPlanCard(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  EXERCISE DETAIL MODAL WITH VIDEO PLAYER
// ─────────────────────────────────────────────

class _ExerciseDetailModal extends StatefulWidget {
  final String title;
  final String description;
  final String? videoUrl;
  final int sets;
  final int reps;
  final int timePerRep;
  final String notes;

  const _ExerciseDetailModal({
    required this.title,
    required this.description,
    this.videoUrl,
    required this.sets,
    required this.reps,
    required this.timePerRep,
    required this.notes,
  });

  @override
  State<_ExerciseDetailModal> createState() => _ExerciseDetailModalState();
}

class _ExerciseDetailModalState extends State<_ExerciseDetailModal> {
  VideoPlayerController? _videoCtrl;
  bool _isInit = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
        ..initialize().then((_) {
          if (mounted) setState(() => _isInit = true);
        }).catchError((_) {
          if (mounted) setState(() => _hasError = true);
        });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF101323),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                children: [
                  // Video Player / Thumbnail Header
                  if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 200,
                        color: Colors.black,
                        child: _isInit && _videoCtrl != null
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: _videoCtrl!.value.aspectRatio,
                                    child: VideoPlayer(_videoCtrl!),
                                  ),
                                  IconButton(
                                    iconSize: 48,
                                    icon: Icon(
                                      _videoCtrl!.value.isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_filled_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _videoCtrl!.value.isPlaying
                                            ? _videoCtrl!.pause()
                                            : _videoCtrl!.play();
                                      });
                                    },
                                  ),
                                ],
                              )
                            : Center(
                                child: _hasError
                                    ? const Icon(Icons.video_library_rounded, size: 48, color: Colors.white24)
                                    : const CircularProgressIndicator(color: Color(0xFFE94560)),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  const SizedBox(height: 12),

                  // Routine parameters
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181E3B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildParam('Sets', '${widget.sets}'),
                        _buildParam('Reps', '${widget.reps}'),
                        _buildParam('Rest', '${widget.timePerRep}s'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (widget.notes.isNotEmpty) ...[
                    const Text(
                      'Coach Instructions',
                      style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5C07B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        widget.notes,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text(
                    'Exercise Guide',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParam(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}