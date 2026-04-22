/// progress_screen.dart — Comprehensive study analytics dashboard.
///
/// Displays statistics from all database tables:
/// - Overview stats (today, this week, completed, pending, total, avg)
/// - Task completion rate with circular progress indicator
/// - Pomodoro session statistics and completion rate
/// - CGPA tracking from semester records
/// - Task priority distribution (High/Medium/Low)
/// - Weekly study bar chart (Mon–Sun) using [fl_chart]
/// - Subject breakdown with percentage bars
/// - GitHub-style study activity heatmap (last 16 weeks)

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
    // Load data and generate report on screen initialization
    Future.microtask(() async {
      await context.read<TaskProvider>().loadTasks();
      await context.read<SessionProvider>().loadSessions();
      if (mounted) {
        await context.read<ProgressProvider>().generateReport(
              taskProvider: context.read<TaskProvider>(),
              sessionProvider: context.read<SessionProvider>(),
            );
      }
    });
  }

  /// Build heatmap data from study sessions.
  Map<DateTime, int> _buildHeatmapData() {
    final sessions = context.read<SessionProvider>().sessions;
    final Map<DateTime, int> data = {};
    for (final s in sessions) {
      final key =
          DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      data[key] = (data[key] ?? 0) + s.durationMinutes;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ProgressProvider>().report;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Progress'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ══════════════════════════════════
                  // ── Overview Statistics (6 cards) ──
                  // ══════════════════════════════════
                  Row(children: [
                    _stat('Today', '${r.todayMinutes}m',
                        const Color(0xFFFF9500)),
                    const SizedBox(width: 10),
                    _stat(
                        'This Week',
                        '${(r.thisWeekMinutes / 60).toStringAsFixed(1)}h',
                        const Color(0xFF5856D6)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _stat('Completed', '${r.completedTasks}',
                        const Color(0xFF34C759)),
                    const SizedBox(width: 10),
                    _stat('Pending', '${r.pendingTasks}',
                        const Color(0xFFFF3B30)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _stat(
                        'Total Study',
                        '${(r.totalStudyMinutes / 60).toStringAsFixed(1)}h',
                        const Color(0xFF0A84FF)),
                    const SizedBox(width: 10),
                    _stat('Avg/Day', '${r.avgDailyMinutes.toStringAsFixed(0)}m',
                        const Color(0xFFAF52DE)),
                  ]),
                  const SizedBox(height: 28),

                  // ══════════════════════════════════
                  // ── Task Completion Rate ──
                  // ══════════════════════════════════
                  _sectionTitle('Task Completion'),
                  const SizedBox(height: 10),
                  _buildCompletionCard(r),
                  const SizedBox(height: 28),

                  // ══════════════════════════════════
                  // ── Pomodoro Statistics ──
                  // ══════════════════════════════════
                  _sectionTitle('Pomodoro Sessions'),
                  const SizedBox(height: 10),
                  _buildPomodoroCard(r),
                  const SizedBox(height: 28),

                  // ══════════════════════════════════
                  // ── CGPA Tracking ──
                  // ══════════════════════════════════
                  if (r.totalSemesters > 0) ...[
                    _sectionTitle('Academic Performance'),
                    const SizedBox(height: 10),
                    _buildCgpaCard(r),
                    const SizedBox(height: 28),
                  ],

                  // ══════════════════════════════════
                  // ── Task Priority Distribution ──
                  // ══════════════════════════════════
                  if (r.completedTasks + r.pendingTasks > 0) ...[
                    _sectionTitle('Priority Distribution'),
                    const SizedBox(height: 10),
                    _buildPriorityCard(r),
                    const SizedBox(height: 28),
                  ],

                  // ══════════════════════════════════
                  // ── Weekly Study Bar Chart ──
                  // ══════════════════════════════════
                  _sectionTitle('Weekly Study'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ProgressBarChart(
                          weeklyStudyMinutes: r.weeklyStudyMinutes),
                    ),
                  ),

                  // ══════════════════════════════════
                  // ── Subject Breakdown ──
                  // ══════════════════════════════════
                  if (r.subjectMinutes.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _sectionTitle('By Subject'),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: () {
                            final entries = r.subjectMinutes.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));
                            return entries.take(8).map((e) {
                              final total = r.totalStudyMinutes == 0
                                  ? 1
                                  : r.totalStudyMinutes;
                              final pct = (e.value / total * 100);
                              return _subjectRow(e.key, e.value, pct, cs);
                            }).toList();
                          }(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ══════════════════════════════════
                  // ── Study Activity Heatmap ──
                  // ══════════════════════════════════
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: HeatmapCalendar(data: _buildHeatmapData()),
                    ),
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

  // ═══════════════════════════════════════
  // ── Card Builder Widgets ──
  // ═══════════════════════════════════════

  /// Task completion rate card with circular progress and linear bar.
  Widget _buildCompletionCard(dynamic r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.completionRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1),
                  ),
                  Text('completion rate',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: r.completionRate / 100,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.grey.withAlpha(30),
                color: const Color(0xFF34C759),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: r.completionRate / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.withAlpha(30),
              color: const Color(0xFF34C759),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${r.completedTasks} completed',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text('${r.pendingTasks} remaining',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          // Show overdue warning if there are overdue tasks
          if (r.overdueTasks > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFFF3B30)),
                  const SizedBox(width: 6),
                  Text(
                    '${r.overdueTasks} overdue task${r.overdueTasks > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF3B30)),
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  /// Pomodoro session statistics card.
  Widget _buildPomodoroCard(dynamic r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          // Completed / Total row
          Row(children: [
            _pomodoroStat(
                '${r.pomodoroCompleted}', 'Completed', const Color(0xFF34C759)),
            _pomodoroStat(
                '${r.pomodoroTotal}', 'Total', const Color(0xFF0A84FF)),
            _pomodoroStat(
                '${(r.totalFocusMinutes / 60).toStringAsFixed(1)}h',
                'Focus Time',
                const Color(0xFFFF9500)),
          ]),
          const SizedBox(height: 14),
          // Completion rate bar
          Row(children: [
            Text('Completion',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const Spacer(),
            Text(
              '${r.pomodoroCompletionRate.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600]),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: r.pomodoroCompletionRate / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.withAlpha(30),
              color: const Color(0xFFFF9500),
            ),
          ),
        ]),
      ),
    );
  }

  /// Individual pomodoro stat column.
  Widget _pomodoroStat(String value, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
    );
  }

  /// CGPA tracking card.
  Widget _buildCgpaCard(dynamic r) {
    Color gpaColor(double gpa) {
      if (gpa >= 3.67) return const Color(0xFF34C759);
      if (gpa >= 3.0) return const Color(0xFF0A84FF);
      if (gpa >= 2.0) return const Color(0xFFFF9500);
      return const Color(0xFFFF3B30);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          // GPA value
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: gpaColor(r.currentCgpa).withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                r.currentCgpa.toStringAsFixed(2),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: gpaColor(r.currentCgpa)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current CGPA',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${r.totalSemesters} semester${r.totalSemesters > 1 ? 's' : ''} recorded',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                // GPA progress bar (out of 4.0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (r.currentCgpa / 4.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.withAlpha(30),
                    color: gpaColor(r.currentCgpa),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  /// Task priority distribution card.
  Widget _buildPriorityCard(dynamic r) {
    final total = r.highPriorityTasks + r.mediumPriorityTasks + r.lowPriorityTasks;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          _priorityRow('High', r.highPriorityTasks, total,
              const Color(0xFFFF3B30)),
          const SizedBox(height: 10),
          _priorityRow('Medium', r.mediumPriorityTasks, total,
              const Color(0xFFFF9500)),
          const SizedBox(height: 10),
          _priorityRow(
              'Low', r.lowPriorityTasks, total, const Color(0xFF34C759)),
        ]),
      ),
    );
  }

  /// Single priority row with label, count, and progress bar.
  Widget _priorityRow(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 60,
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.grey.withAlpha(20),
            color: color,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text('$count',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600])),
    ]);
  }

  // ═══════════════════════════════════════
  // ── Reusable Widgets ──
  // ═══════════════════════════════════════

  /// Stat card with colored dot indicator.
  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  /// Section title text.
  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5));
  }

  /// Subject row with name, hours, percentage, and progress bar.
  Widget _subjectRow(
      String subject, int minutes, double pct, ColorScheme cs) {
    final colors = [
      const Color(0xFF0A84FF),
      const Color(0xFF5856D6),
      const Color(0xFFFF9500),
      const Color(0xFF34C759),
      const Color(0xFFFF3B30),
      const Color(0xFFAF52DE),
      const Color(0xFF5AC8FA),
      const Color(0xFFFF6482),
    ];
    final color = colors[subject.hashCode.abs() % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(subject,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Text('${(minutes / 60).toStringAsFixed(1)}h',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600])),
            const SizedBox(width: 8),
            Text('${pct.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.withAlpha(20),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
