import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
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

  Widget _quickButton(
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ProgressProvider>().report;
    final totalHours = (report.totalStudyMinutes / 60).toStringAsFixed(1);

    final todayTasks = context.watch<TaskProvider>().todayTasks;
    final todayMinutes = context.watch<SessionProvider>().todayStudyMinutes;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('EduNova Home'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Let\'s make today productive.'),
              const SizedBox(height: 16),

              Row(
                children: [
                  _summaryCard(
                    'Tasks',
                    '${report.completedTasks + report.pendingTasks}',
                    Icons.task_alt,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    'Studied',
                    '${totalHours}h',
                    Icons.timer,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    'Progress',
                    '${report.completionRate.toStringAsFixed(0)}%',
                    Icons.show_chart,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today Tasks (${todayTasks.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (todayTasks.isEmpty)
                        const Text('No tasks for today')
                      else
                        ...todayTasks.take(3).map(
                              (task) => Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• ${task.title}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Today Study Time'),
                  subtitle: Text('$todayMinutes minutes'),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              _quickButton(
                'Go to Tasks',
                Icons.task,
                    () => widget.onNavigate(1),
              ),
              _quickButton(
                'Open Calendar',
                Icons.calendar_today,
                    () => widget.onNavigate(2),
              ),
              _quickButton(
                'View Progress',
                Icons.bar_chart,
                    () => widget.onNavigate(3),
              ),
              _quickButton(
                'Pomodoro Timer',
                Icons.timer,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PomodoroScreen(),
                    ),
                  );
                },
              ),
              _quickButton(
                'Settings',
                Icons.settings,
                    () => widget.onNavigate(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}