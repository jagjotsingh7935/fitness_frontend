import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class WeightProgressChart extends StatelessWidget {
  const WeightProgressChart({
    super.key,
    this.currentWeight,
    this.targetWeight,
  });

  final double? currentWeight;
  final double? targetWeight;

  @override
  Widget build(BuildContext context) {
    final curW = currentWeight ?? 76.0;
    final tgtW = targetWeight ?? 70.0;

    // Generate dynamic progression curve ending at current weight
    final diff = 3.2;
    final spots = <FlSpot>[
      FlSpot(0, curW + diff),
      FlSpot(1, curW + (diff * 0.85)),
      FlSpot(2, curW + (diff * 0.72)),
      FlSpot(3, curW + (diff * 0.60)),
      FlSpot(4, curW + (diff * 0.45)),
      FlSpot(5, curW + (diff * 0.35)),
      FlSpot(6, curW + (diff * 0.22)),
      FlSpot(7, curW + (diff * 0.12)),
      FlSpot(8, curW + (diff * 0.05)),
      FlSpot(9, curW),
    ];

    final minY = [curW, tgtW, curW + diff].reduce((a, b) => a < b ? a : b) - 3.0;
    final maxY = [curW, tgtW, curW + diff].reduce((a, b) => a > b ? a : b) + 3.0;

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
                  const labels = ['D1', 'D4', 'D7', 'D10', 'D13', 'D16', 'D19', 'D22', 'D25', 'Now'];
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.text3,
                            fontSize: 10.5,
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
          minY: minY,
          maxY: maxY,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: tgtW,
                color: const Color(0xFF00E5A0).withValues(alpha: 0.9),
                strokeWidth: 1.2,
                dashArray: [6, 6],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 2),
                  style: const TextStyle(
                    color: Color(0xFF00E5A0),
                    backgroundColor: Color(0x2200E5A0),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                  labelResolver: (_) => 'Goal: ${tgtW.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: AppColors.primary,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: index == 9 ? const Color(0xFF00E5A0) : AppColors.primary,
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
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0),
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
