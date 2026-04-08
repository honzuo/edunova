import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/progress_bar_chart.dart';
import '../../widgets/heatmap_calendar.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<TaskProvider>().loadTasks();
      await context.read<SessionProvider>().loadSessions();
      if (mounted) {
        context.read<ProgressProvider>().generateReport(
          taskProvider: context.read<TaskProvider>(),
          sessionProvider: context.read<SessionProvider>(),
        );
      }
    });
  }

  Map<DateTime, int> _buildHeatmapData() {
    final sessions = context.read<SessionProvider>().sessions;
    final Map<DateTime, int> data = {};
    for (final s in sessions) {
      final key = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      data[key] = (data[key] ?? 0) + s.durationMinutes;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ProgressProvider>().report;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, snap: true, title: Text('Progress')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                Row(children: [
                  _stat('Completed', '${r.completedTasks}', const Color(0xFF34C759)),
                  const SizedBox(width: 10),
                  _stat('Pending', '${r.pendingTasks}', const Color(0xFFFF9500)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _stat('Study Time', '${(r.totalStudyMinutes / 60).toStringAsFixed(1)}h', const Color(0xFF5856D6)),
                  const SizedBox(width: 10),
                  _stat('Completion', '${r.completionRate.toStringAsFixed(0)}%', const Color(0xFF0A84FF)),
                ]),

                const SizedBox(height: 28),
                const Text('Weekly Study', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 10),
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProgressBarChart(weeklyStudyMinutes: r.weeklyStudyMinutes),
                )),

                const SizedBox(height: 28),
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: HeatmapCalendar(data: _buildHeatmapData()),
                )),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ]),
        ),
      ),
    );
  }
}
