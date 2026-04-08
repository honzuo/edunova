import 'package:flutter/material.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<DateTime, int> data;
  const HeatmapCalendar({super.key, required this.data});

  Color _color(int min, Brightness b) {
    if (min == 0) return b == Brightness.dark ? Colors.grey[850]! : Colors.grey[100]!;
    if (min < 30) return const Color(0xFF34C759).withAlpha(60);
    if (min < 60) return const Color(0xFF34C759).withAlpha(120);
    if (min < 120) return const Color(0xFF34C759).withAlpha(180);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 112));
    final aligned = start.subtract(Duration(days: start.weekday - 1));
    final days = now.difference(aligned).inDays + 1;
    final weeks = (days / 7).ceil();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Study Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(weeks, (w) => Column(
            children: List.generate(7, (d) {
              final date = aligned.add(Duration(days: w * 7 + d));
              if (date.isAfter(now)) return const SizedBox(width: 14, height: 14);
              final key = DateTime(date.year, date.month, date.day);
              final min = data[key] ?? 0;
              return Tooltip(
                message: '${date.day}/${date.month}: $min min',
                child: Container(
                  width: 12, height: 12,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(color: _color(min, b), borderRadius: BorderRadius.circular(3)),
                ),
              );
            }),
          )),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(width: 4),
        ...[0, 15, 45, 90, 150].map((m) => Container(
          width: 12, height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(color: _color(m, b), borderRadius: BorderRadius.circular(3)),
        )),
        const SizedBox(width: 4),
        Text('More', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    ]);
  }
}
