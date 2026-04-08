import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/database_service.dart';
import '../../providers/progress_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/achievement_provider.dart';
import '../search/search_screen.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    username = user?.userMetadata?['username'];

    Future.microtask(() async {
      await context.read<TaskProvider>().loadTasks();
      await context.read<SessionProvider>().loadSessions();

      if (mounted) {
        context.read<ProgressProvider>().generateReport(
          taskProvider: context.read<TaskProvider>(),
          sessionProvider: context.read<SessionProvider>(),
        );

        final ap = context.read<AchievementProvider>();
        await ap.loadAchievements();
        final streak = await ap.calculateStreak();
        final tasks = context.read<TaskProvider>().tasks;
        final sessions = context.read<SessionProvider>().sessions;
        final completedTasks = tasks.where((t) => t.isCompleted).length;
        final totalMinutes = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
        final pomodoroCount = await _getPomodoroCount();

        await ap.evaluate(
          completedTasks: completedTasks,
          pomodoroCount: pomodoroCount,
          totalStudyMinutes: totalMinutes,
          streak: streak,
        );
      }
    });
  }

  Future<int> _getPomodoroCount() async {
    final db = await DatabaseService().database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';
    final result = await db.query('pomodoro_records', where: 'user_id = ? AND completed = 1', whereArgs: [userId]);
    return result.length;
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ProgressProvider>().report;
    final totalHours = (report.totalStudyMinutes / 60).toStringAsFixed(1);
    final todayTasks = context.watch<TaskProvider>().todayTasks;
    final todayMinutes = context.watch<SessionProvider>().todayStudyMinutes;
    final streak = context.watch<AchievementProvider>().currentStreak;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, snap: true,
            title: const Text('EduNova'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting + Streak ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username?.isNotEmpty == true
                                  ? 'Welcome, $username'
                                  : 'Welcome',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _streakBadge(streak),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Stats Row ──
                  Row(children: [
                    _statCard('Tasks', '${report.completedTasks + report.pendingTasks}',
                        Icons.checklist_rounded, const Color(0xFF5856D6)),
                    const SizedBox(width: 10),
                    _statCard('Studied', '${totalHours}h',
                        Icons.timer_outlined, const Color(0xFFFF9500)),
                    const SizedBox(width: 10),
                    _statCard('Done', '${report.completionRate.toStringAsFixed(0)}%',
                        Icons.pie_chart_rounded, const Color(0xFF34C759)),
                  ]),

                  const SizedBox(height: 28),

                  // ── Today Section ──
                  _sectionTitle('Today'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(children: [
                            _iconBubble(Icons.access_time_rounded, const Color(0xFFFF9500)),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Study Time', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                Text('$todayMinutes min', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                              ],
                            ),
                          ]),
                          if (todayTasks.isNotEmpty) ...[
                            const Divider(height: 28),
                            ...todayTasks.take(3).map((task) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(children: [
                                Icon(task.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                                    size: 20, color: task.isCompleted ? const Color(0xFF34C759) : Colors.grey[400]),
                                const SizedBox(width: 10),
                                Expanded(child: Text(task.title, style: TextStyle(
                                  fontSize: 15,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? Colors.grey : null,
                                ))),
                              ]),
                            )),
                          ],
                          if (todayTasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('No tasks for today', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Quick Access ──
                  _sectionTitle('Quick Access'),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(children: [
                      _menuItem('Tasks', Icons.checklist_rounded, const Color(0xFF5856D6), () => widget.onNavigate(1)),
                      _divider(),
                      _menuItem('Calendar', Icons.calendar_month_rounded, const Color(0xFFFF3B30), () => widget.onNavigate(2)),
                      _divider(),
                      _menuItem('Progress', Icons.insights_rounded, const Color(0xFF34C759), () => widget.onNavigate(3)),
                      _divider(),
                      _menuItem('Pomodoro', Icons.timer_rounded, const Color(0xFFFF9500), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PomodoroScreen()));
                      }),
                    ]),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withAlpha(20),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9500), size: 18),
        const SizedBox(width: 4),
        Text('$streak', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFF9500))),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _iconBubble(icon, color, size: 32),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),
      ),
    );
  }

  Widget _iconBubble(IconData icon, Color color, {double size = 36}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5));
  }

  Widget _menuItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          _iconBubble(icon, color, size: 32),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
        ]),
      ),
    );
  }

  Widget _divider() => Divider(height: 0.5, indent: 64, color: Colors.grey.withAlpha(30));
}
