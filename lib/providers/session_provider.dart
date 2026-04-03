import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_session.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<StudySession> _sessions = [];
  List<StudySession> get sessions => _sessions;

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

  Future<void> loadSessions() async {
    final data = await _db.getSessionsByUser(_userId);
    _sessions = data.map((map) => StudySession.fromMap(map)).toList();
    notifyListeners();
  }

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
  }

  Future<void> removeSession(int id) async {
    await _db.deleteSession(id);
    await loadSessions();
  }
}