/// progress_provider.dart — Generates comprehensive progress reports.
///
/// Computes statistics from task, session, pomodoro, and CGPA data:
/// - Task completion rates and priority distribution
/// - Weekly study breakdown by day (Mon–Sun)
/// - Subject-wise study minutes
/// - Pomodoro session counts and completion rate
/// - CGPA from saved semester records
/// - Overdue task count
/// - 30-day daily study average

import 'package:flutter/foundation.dart';

import '../models/progress_report.dart';
import '../models/cgpa_record.dart';
import '../providers/task_provider.dart';
import '../providers/session_provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class ProgressProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  ProgressReport _report = ProgressReport(
    completedTasks: 0,
    pendingTasks: 0,
    totalStudyMinutes: 0,
    completionRate: 0,
    weeklyStudyMinutes: const {},
  );

  ProgressReport get report => _report;

  /// Generate a comprehensive progress report from all data sources.
  ///
  /// Aggregates data from:
  /// - [TaskProvider] for task completion and priority stats
  /// - [SessionProvider] for study time and subject breakdown
  /// - SQLite pomodoro_records table for focus session stats
  /// - SQLite cgpa_records table for GPA tracking
  Future<void> generateReport({
    required TaskProvider taskProvider,
    required SessionProvider sessionProvider,
  }) async {
    final tasks = taskProvider.tasks;
    final sessions = sessionProvider.sessions;
    final now = DateTime.now();
    final userId = AuthService().currentUserId ?? 'demo-user';

    // ── Task Statistics ──
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final pendingTasks = tasks.where((t) => !t.isCompleted).length;
    final totalTasks = tasks.length;
    final completionRate =
        totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100;

    // ── Priority Distribution ──
    final highPriority =
        tasks.where((t) => t.priority.toLowerCase() == 'high').length;
    final mediumPriority =
        tasks.where((t) => t.priority.toLowerCase() == 'medium').length;
    final lowPriority =
        tasks.where((t) => t.priority.toLowerCase() == 'low').length;

    // ── Overdue Tasks (past deadline + not completed) ──
    final overdueTasks = tasks.where((t) {
      return !t.isCompleted && t.deadline.isBefore(now);
    }).length;

    // ── Study Time ──
    final totalStudyMinutes =
        sessions.fold(0, (sum, s) => sum + s.durationMinutes);
    final todayMinutes = sessionProvider.todayStudyMinutes;
    final thisWeekMinutes = sessionProvider.thisWeekStudyMinutes;

    // ── Weekly Breakdown (Mon–Sun) ──
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final Map<String, int> weeklyStudyMinutes = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0,
      'Fri': 0, 'Sat': 0, 'Sun': 0,
    };
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final session in sessions) {
      if (session.startTime.isAfter(weekStart)) {
        final dayKey = dayNames[session.startTime.weekday - 1];
        weeklyStudyMinutes[dayKey] =
            weeklyStudyMinutes[dayKey]! + session.durationMinutes;
      }
    }

    // ── Subject Breakdown ──
    final subjectMinutes = sessionProvider.minutesBySubject;

    // ── 30-Day Daily Average ──
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentSessions =
        sessions.where((s) => s.startTime.isAfter(thirtyDaysAgo));
    final recentTotal =
        recentSessions.fold(0, (sum, s) => sum + s.durationMinutes);
    final avgDaily = recentTotal / 30.0;

    // ── Pomodoro Statistics (from database) ──
    int pomodoroCompleted = 0;
    int pomodoroTotal = 0;
    int totalFocusMinutes = 0;
    try {
      final pomodoroData = await _db.getPomodorosByUser(userId);
      pomodoroTotal = pomodoroData.length;
      for (final p in pomodoroData) {
        final completed = p['completed'] == 1 || p['completed'] == true;
        if (completed) pomodoroCompleted++;
        totalFocusMinutes += (p['focus_minutes'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading pomodoro stats: $e');
    }

    // ── CGPA (from database) ──
    double currentCgpa = 0;
    int totalSemesters = 0;
    try {
      final cgpaData = await _db.getCgpaRecordsByUser(userId);
      totalSemesters = cgpaData.length;
      if (cgpaData.isNotEmpty) {
        double totalPts = 0;
        int totalCredits = 0;
        for (final m in cgpaData) {
          final record = CgpaRecord.fromMap(m);
          totalPts += record.gpa * record.totalCredits;
          totalCredits += record.totalCredits;
        }
        currentCgpa = totalCredits > 0 ? totalPts / totalCredits : 0;
      }
    } catch (e) {
      debugPrint('Error loading CGPA: $e');
    }

    // ── Build Final Report ──
    _report = ProgressReport(
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      totalStudyMinutes: totalStudyMinutes,
      completionRate: completionRate,
      weeklyStudyMinutes: weeklyStudyMinutes,
      subjectMinutes: subjectMinutes,
      todayMinutes: todayMinutes,
      thisWeekMinutes: thisWeekMinutes,
      avgDailyMinutes: avgDaily,
      pomodoroCompleted: pomodoroCompleted,
      pomodoroTotal: pomodoroTotal,
      totalFocusMinutes: totalFocusMinutes,
      highPriorityTasks: highPriority,
      mediumPriorityTasks: mediumPriority,
      lowPriorityTasks: lowPriority,
      overdueTasks: overdueTasks,
      currentCgpa: currentCgpa,
      totalSemesters: totalSemesters,
    );

    notifyListeners();
  }
}
