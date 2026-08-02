import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/theme/app_colors.dart';

class CalorieTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> summaryData;
  
  const CalorieTrendChart({super.key, this.summaryData = const []});

  @override
  Widget build(BuildContext context) {
    if (summaryData.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.text2),
        ),
      );
    }

    final spots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    
    for (int i = 0; i < summaryData.length; i++) {
      final data = summaryData[i];
      final actualKcal = (data['actual_kcal'] ?? 0).toDouble();
      final targetKcal = (data['target_kcal'] ?? 0).toDouble();
      
      spots.add(FlSpot(i.toDouble(), actualKcal));
      targetSpots.add(FlSpot(i.toDouble(), targetKcal));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: AppColors.text2, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < summaryData.length) {
                    final day = summaryData[index]['day'] ?? '';
                    return Text(
                      day.substring(0, 3),
                      style: const TextStyle(color: AppColors.text2, fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: targetSpots,
              isCurved: true,
              color: AppColors.primary.withOpacity(0.5),
              barWidth: 2,
              dotData: FlDotData(show: false),
              dashArray: [5, 5],
            ),
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}