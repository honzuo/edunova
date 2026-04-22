/// main_screen.dart — Main navigation shell with bottom navigation bar.
///
/// Uses [IndexedStack] to maintain state across 5 tabs:
/// Home, Tasks, Calendar, Progress, and Settings.
/// Listens to [AppRefreshService] to reload data when changes
/// occur in any provider (e.g. Pomodoro creates a session).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../services/app_refresh_service.dart';

import '../home/home_screen.dart';
import '../task/task_screen.dart';
import '../calendar/calendar_screen.dart';
import '../progress/progress_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final _refreshService = AppRefreshService();

  void changeTab(int index) => setState(() => currentIndex = index);

  late final List<Widget> screens = [
    HomeScreen(onNavigate: changeTab),
    const TaskScreen(),
    const CalendarScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Listen to global refresh events (e.g. pomodoro creates a session)
    _refreshService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _refreshService.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Reload all providers when data changes anywhere.
  Future<void> _onDataChanged() async {
    if (!mounted) return;
    await context.read<SessionProvider>().loadSessions();
    await context.read<TaskProvider>().loadTasks();
    if (mounted) {
      context.read<ProgressProvider>().generateReport(
        taskProvider: context.read<TaskProvider>(),
        sessionProvider: context.read<SessionProvider>(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerTheme.color ?? Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: changeTab,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.house_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'More'),
          ],
        ),
      ),
    );
  }
}
