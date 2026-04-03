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

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (values.isEmpty
              ? 10
              : (values.reduce((a, b) => a > b ? a : b) + 30))
              .toDouble(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
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
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(labels[index]);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(labels.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].toDouble(),
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