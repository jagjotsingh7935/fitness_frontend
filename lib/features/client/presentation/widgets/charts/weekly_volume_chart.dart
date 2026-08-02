import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class WeeklyVolumeChart extends StatelessWidget {
  const WeeklyVolumeChart({super.key});

  @override
  Widget build(BuildContext context) {
    final values = <double>[2400, 1800, 2900, 0, 3200, 0, 1500];
    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.text3,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List<BarChartGroupData>.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 14,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

