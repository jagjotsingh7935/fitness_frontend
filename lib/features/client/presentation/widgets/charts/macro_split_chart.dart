import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class MacroSplitChart extends StatelessWidget {
  final List<Map<String, dynamic>> kcalTargets;
  
  const MacroSplitChart({super.key, this.kcalTargets = const []});

  @override
  Widget build(BuildContext context) {
    // Get today's target
    final todayWeekday = DateTime.now().weekday - 1;
    final Map<String, dynamic>? todayTarget = kcalTargets.cast<Map<String, dynamic>?>().firstWhere(
      (t) => t?['day_of_week'] == todayWeekday,
      orElse: () => null,
    );

    final totalCalories = todayTarget != null 
        ? (todayTarget['target_kcal'] ?? 2000).toDouble()
        : 2000.0;
    
    // Calculate macros based on standard distribution
    // Protein: 30%, Carbs: 50%, Fats: 20%
    final proteinCalories = totalCalories * 0.3;
    final carbsCalories = totalCalories * 0.5;
    final fatsCalories = totalCalories * 0.2;
    
    // Convert to grams (1g protein = 4 kcal, 1g carb = 4 kcal, 1g fat = 9 kcal)
    final proteinGrams = (proteinCalories / 4).round();
    final carbsGrams = (carbsCalories / 4).round();
    final fatsGrams = (fatsCalories / 9).round();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 46,
          sections: [
            _section(
              value: proteinGrams.toDouble(),
              color: AppColors.primary,
              title: 'Protein',
              grams: proteinGrams,
            ),
            _section(
              value: carbsGrams.toDouble(),
              color: const Color(0xFFFF9800),
              title: 'Carbs',
              grams: carbsGrams,
            ),
            _section(
              value: fatsGrams.toDouble(),
              color: const Color(0xFFE91E63),
              title: 'Fats',
              grams: fatsGrams,
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section({
    required double value,
    required Color color,
    required String title,
    required int grams,
  }) {
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 70,
      showTitle: false,
      title: title,
    );
  }
}