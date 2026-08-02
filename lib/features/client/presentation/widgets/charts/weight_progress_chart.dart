import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class WeightProgressChart extends StatelessWidget {
  const WeightProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      const FlSpot(0, 85.6),
      const FlSpot(1, 85.1),
      const FlSpot(2, 84.7),
      const FlSpot(3, 84.3),
      const FlSpot(4, 83.9),
      const FlSpot(5, 83.4),
      const FlSpot(6, 83.1),
      const FlSpot(7, 82.8),
      const FlSpot(8, 82.6),
      const FlSpot(9, 82.4),
    ];

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              dashArray: [4, 4],
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              dashArray: [4, 4],
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const labels = ['D1', 'D4', 'D7', 'D10', 'D13', 'D16', 'D19', 'D22', 'D25', 'D28'];
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
          minX: 0,
          maxX: 9,
          minY: 78,
          maxY: 86,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 78,
                color: AppColors.orange.withValues(alpha: 0.9),
                strokeWidth: 1,
                dashArray: [6, 6],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 2),
                  style: TextStyle(
                    color: AppColors.orange,
                    backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  labelResolver: (_) => 'Goal: 78 kg',
                ),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: AppColors.green,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.green,
                  strokeWidth: 2,
                  strokeColor: AppColors.background2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.green.withValues(alpha: 0.25),
                    AppColors.green.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

