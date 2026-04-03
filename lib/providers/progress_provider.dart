import 'package:flutter/foundation.dart';

import '../models/progress_report.dart';
import '../providers/task_provider.dart';
import '../providers/session_provider.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressReport _report = ProgressReport(
    completedTasks: 0,
    pendingTasks: 0,
    totalStudyMinutes: 0,
    completionRate: 0,
    weeklyStudyMinutes: const {},
  );

  ProgressReport get report => _report;

  void generateReport({
    required TaskProvider taskProvider,
    required SessionProvider sessionProvider,
  }) {
    final tasks = taskProvider.tasks;
    final sessions = sessionProvider.sessions;

    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final pendingTasks = tasks.where((task) => !task.isCompleted).length;
    final totalStudyMinutes =
    sessions.fold(0, (sum, session) => sum + session.durationMinutes);

    final totalTasks = tasks.length;
    final completionRate =
    totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100;

    final Map<String, int> weeklyStudyMinutes = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    for (final session in sessions) {
      final weekday = session.startTime.weekday;
      switch (weekday) {
        case DateTime.monday:
          weeklyStudyMinutes['Mon'] =
              weeklyStudyMinutes['Mon']! + session.durationMinutes;
          break;
        case DateTime.tuesday:
          weeklyStudyMinutes['Tue'] =
              weeklyStudyMinutes['Tue']! + session.durationMinutes;
          break;
        case DateTime.wednesday:
          weeklyStudyMinutes['Wed'] =
              weeklyStudyMinutes['Wed']! + session.durationMinutes;
          break;
        case DateTime.thursday:
          weeklyStudyMinutes['Thu'] =
              weeklyStudyMinutes['Thu']! + session.durationMinutes;
          break;
        case DateTime.friday:
          weeklyStudyMinutes['Fri'] =
              weeklyStudyMinutes['Fri']! + session.durationMinutes;
          break;
        case DateTime.saturday:
          weeklyStudyMinutes['Sat'] =
              weeklyStudyMinutes['Sat']! + session.durationMinutes;
          break;
        case DateTime.sunday:
          weeklyStudyMinutes['Sun'] =
              weeklyStudyMinutes['Sun']! + session.durationMinutes;
          break;
      }
    }

    _report = ProgressReport(
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      totalStudyMinutes: totalStudyMinutes,
      completionRate: completionRate,
      weeklyStudyMinutes: weeklyStudyMinutes,
    );

    notifyListeners();
  }
}