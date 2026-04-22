/// session_provider.dart — State management for study sessions.
///
/// All session data is stored in Supabase (cloud).

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/study_session.dart';
import '../services/database_service.dart';
import '../services/app_refresh_service.dart';

class SessionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AppRefreshService _refresh = AppRefreshService();

  List<StudySession> _sessions = [];
  List<StudySession> get sessions => _sessions;

  String get _userId => AuthService().currentUserId ?? 'demo-user';

  /// Load all study sessions from Supabase.
  Future<void> loadSessions() async {
    try {
      final data = await _db.getSessionsByUser(_userId);
      _sessions = data.map((map) => StudySession.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  /// Create a new study session in Supabase.
  Future<void> addSession({
    int? taskId,
    required String title,
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    required String notes,
  }) async {
    final duration = endTime.difference(startTime).inMinutes;
    final session = StudySession(
      userId: _userId,
      taskId: taskId,
      title: title,
      subject: subject,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: duration,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _db.insertSession(session.toMap());
    await loadSessions();
    _refresh.triggerRefresh();
  }

  /// Delete a session from Supabase.
  Future<void> removeSession(int id) async {
    await _db.deleteSession(id);
    await loadSessions();
    _refresh.triggerRefresh();
  }

  /// Total study minutes for today.
  int get todayStudyMinutes {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Total study minutes for a specific task.
  int minutesForTask(int taskId) {
    return _sessions
        .where((s) => s.taskId == taskId)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  List<StudySession> sessionsForTask(int taskId) {
    return _sessions.where((s) => s.taskId == taskId).toList();
  }

  /// Study minutes grouped by subject.
  Map<String, int> get minutesBySubject {
    final Map<String, int> result = {};
    for (final s in _sessions) {
      final sub = s.subject.isEmpty ? 'General' : s.subject;
      result[sub] = (result[sub] ?? 0) + s.durationMinutes;
    }
    return result;
  }

  /// Total study minutes since Monday of the current week.
  int get thisWeekStudyMinutes {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    return _sessions
        .where((s) => s.startTime.isAfter(weekStart))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }
}
