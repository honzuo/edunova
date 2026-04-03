import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/progress_bar_chart.dart';

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

  Widget _summaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ProgressProvider>().report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _summaryCard(
                  'Completed',
                  '${report.completedTasks}',
                  Icons.check_circle,
                ),
                const SizedBox(width: 8),
                _summaryCard(
                  'Pending',
                  '${report.pendingTasks}',
                  Icons.pending_actions,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _summaryCard(
                  'Study Time',
                  '${report.totalStudyMinutes} min',
                  Icons.timer,
                ),
                const SizedBox(width: 8),
                _summaryCard(
                  'Completion',
                  '${report.completionRate.toStringAsFixed(1)}%',
                  Icons.show_chart,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Weekly Study Minutes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ProgressBarChart(
                  weeklyStudyMinutes: report.weeklyStudyMinutes,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}