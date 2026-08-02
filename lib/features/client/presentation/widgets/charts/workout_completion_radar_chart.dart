import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class WorkoutCompletionRadarChart extends StatelessWidget {
  const WorkoutCompletionRadarChart({super.key});

  @override
  Widget build(BuildContext context) {
    const values = <double>[90, 75, 85, 60, 95, 70, 80];
    return SizedBox(
      height: 220,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              borderColor: AppColors.primary,
              fillColor: AppColors.primary.withValues(alpha: 0.18),
              entryRadius: 3,
              dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          radarBorderData: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          gridBorderData: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          titleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text3,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
          getTitle: (index, angle) {
            const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return RadarChartTitle(text: labels[index]);
          },
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
        ),
      ),
    );
  }
}

