import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';

class DietPlanCard extends StatefulWidget {
  const DietPlanCard({super.key});

  @override
  State<DietPlanCard> createState() => _DietPlanCardState();
}

class _DietPlanCardState extends State<DietPlanCard> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  Map<String, dynamic>? _dietPlan;
  List<Map<String, dynamic>> _meals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDietPlan();
  }

  Future<void> _fetchDietPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _dio.get('/fitness/api/my-diet-plan/');
      if (res.statusCode == 200 && res.data is Map) {
        final planData = res.data['plan'];
        if (planData != null && planData is Map<String, dynamic>) {
          _dietPlan = planData;
          final mList = planData['meals'] as List? ?? [];
          _meals = List<Map<String, dynamic>>.from(mList);
        } else {
          _dietPlan = null;
          _meals = [];
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load diet plan';
        });
      }
    }
  }

  Future<void> _toggleMeal(int index) async {
    if (index < 0 || index >= _meals.length) return;
    final meal = _meals[index];
    final mealId = meal['id'];
    final currentDone = meal['done'] == true;

    // Optimistic UI update
    setState(() {
      _meals[index]['done'] = !currentDone;
    });

    try {
      final res = await _dio.post('/fitness/api/my-diet-plan/meals/$mealId/toggle/');
      if (res.statusCode == 200 && res.data is Map) {
        final actualDone = res.data['done'] == true;
        if (mounted && _meals[index]['done'] != actualDone) {
          setState(() {
            _meals[index]['done'] = actualDone;
          });
        }
      }
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _meals[index]['done'] = currentDone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update meal status. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF141829),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE5C07B), strokeWidth: 2.5),
        ),
      );
    }

    if (_error != null || _dietPlan == null) {
      return _buildEmptyState();
    }

    final plan = _dietPlan!;
    final title = plan['title'] ?? 'Personalized Nutrition Plan';
    final targetKcal = plan['daily_calorie_target'] ?? 2000;
    final protein = plan['protein_grams'] ?? 140;
    final carbs = plan['carbs_grams'] ?? 220;
    final fat = plan['fat_grams'] ?? 65;
    final trainerName = plan['trainer_name'] ?? 'Coach';
    final notes = (plan['notes'] ?? '').toString().trim();

    final doneCount = _meals.where((m) => m['done'] == true).length;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B2038),
            Color(0xFF14172B),
            Color(0xFF0D0F1D),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5C07B).withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFE5C07B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🥗', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Assigned by $trainerName · $targetKcal kcal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  '✓ Active',
                  style: TextStyle(
                    color: Color(0xFF00F5A0),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          // Coach Instructions Callout
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE5C07B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5C07B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFE5C07B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Macro Breakdown Row
          _MacroRow(protein: (protein as num).toInt(), carbs: (carbs as num).toInt(), fat: (fat as num).toInt()),

          const SizedBox(height: 16),

          // Meals List Header
          Row(
            children: [
              const Text(
                'SCHEDULED MEALS',
                style: TextStyle(
                  color: Color(0xFFE5C07B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/${_meals.length} Eaten',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Meals List
          if (_meals.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No specific meal items listed yet.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...List<Widget>.generate(_meals.length, (i) {
              final m = _meals[i];
              final mealType = (m['meal_type_display'] ?? '').toString();
              final timeLabel = (m['time_label'] ?? '').toString();
              final subTitle = timeLabel.isNotEmpty ? '$timeLabel · $mealType' : mealType;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MealItem(
                  emoji: (m['emoji'] ?? '🍽️').toString(),
                  name: (m['name'] ?? 'Meal').toString(),
                  time: subTitle,
                  calories: '${m['calories'] ?? 0} kcal',
                  done: m['done'] == true,
                  onToggle: () => _toggleMeal(i),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF141829),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE5C07B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFE5C07B), size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Custom Diet Plan Assigned Yet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Your trainer or coach will assign a personalized nutrition schedule for you soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final int protein;
  final int carbs;
  final int fat;

  const _MacroRow({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroItem(
            value: '${protein}g',
            label: 'Protein',
            color: const Color(0xFF00F5A0),
            bar: const [Color(0xFF00F5A0), Color(0xFF00C9FF)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroItem(
            value: '${carbs}g',
            label: 'Carbs',
            color: const Color(0xFFFF8C00),
            bar: const [Color(0xFFFF8C00), Color(0xFFE5C07B)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroItem(
            value: '${fat}g',
            label: 'Fats',
            color: const Color(0xFFFF5252),
            bar: const [Color(0xFFFF5252), Color(0xFFFF7A7A)],
          ),
        ),
      ],
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.value,
    required this.label,
    required this.color,
    required this.bar,
  });

  final String value;
  final String label;
  final Color color;
  final List<Color> bar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1322),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(colors: bar),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  const _MealItem({
    required this.emoji,
    required this.name,
    required this.time,
    required this.calories,
    required this.done,
    required this.onToggle,
  });

  final String emoji;
  final String name;
  final String time;
  final String calories;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1322),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? const Color(0xFF00F5A0).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Auto-assigned emoji / icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: done ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            calories,
            style: const TextStyle(
              color: Color(0xFFFF8C00),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(99),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFF00F5A0) : Colors.transparent,
                border: Border.all(
                  color: done ? const Color(0xFF00F5A0) : Colors.white30,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check, size: 15, color: Color(0xFF0C101E))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
