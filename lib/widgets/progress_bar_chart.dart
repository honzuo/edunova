/// progress_bar_chart.dart — Weekly study minutes bar chart widget.
///
/// Uses [fl_chart] to display a bar chart of study minutes
/// broken down by day of the week (Mon–Sun).
/// Used on the Progress screen.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressBarChart extends StatelessWidget {
  final Map<String, int> weeklyStudyMinutes;

  const ProgressBarChart({
    super.key,
    required this.weeklyStudyMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final labels = weeklyStudyMinutes.keys.toList();
    final values = weeklyStudyMinutes.values.toList();

    // 计算 Y 轴的最大值
    final maxYValue = (values.isEmpty
        ? 10
        : (values.reduce((a, b) => a > b ? a : b) + 30))
        .toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxYValue,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${value.toInt()}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxYValue > 60 ? maxYValue / 5 : 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withAlpha(40),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          barGroups: List.generate(labels.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}