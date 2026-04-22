/// pomodoro_provider.dart — State management for the Pomodoro timer.
///
/// Timer records and auto-generated study sessions are saved
/// directly to Supabase via [DatabaseService].

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/pomodoro_record.dart';
import '../models/study_task.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../services/app_refresh_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AudioService _audio = AudioService();
  final AppRefreshService _refresh = AppRefreshService();

  Timer? _timer;

  static const List<int> durationOptions = [5, 10, 15, 20, 25, 30, 45, 60];
  int _selectedMinutes = 25;
  int get selectedMinutes => _selectedMinutes;

  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  DateTime? _startedAt;

  // ── Linked Task ──
  StudyTask? _linkedTask;
  StudyTask? get linkedTask => _linkedTask;

  // ── Session just created (for UI feedback) ──
  bool _sessionJustSaved = false;
  bool get sessionJustSaved => _sessionJustSaved;
  void clearSessionSavedFlag() => _sessionJustSaved = false;

  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  double get progress {
    final total = _selectedMinutes * 60;
    return total == 0 ? 0 : 1.0 - (_secondsLeft / total);
  }

  String get _userId => AuthService().currentUserId ?? 'demo-user';

  /// Link a task to the current Pomodoro session for tracking.
  void linkTask(StudyTask? task) {
    if (_isRunning) return;
    _linkedTask = task;
    notifyListeners();
  }

  /// Set the focus duration. Only allowed when timer is not running.
  void setDuration(int minutes) {
    if (_isRunning) return;
    _selectedMinutes = minutes;
    _secondsLeft = minutes * 60;
    notifyListeners();
  }

  /// Start the countdown timer.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _startedAt = DateTime.now();
    _sessionJustSaved = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
      } else {
        _completeSession();
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Pause the running timer.
  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// Reset the timer to the selected duration.
  void reset() {
    _timer?.cancel();
    _secondsLeft = _selectedMinutes * 60;
    _isRunning = false;
    _startedAt = null;
    notifyListeners();
  }

  /// Stop timer and audio, save partial session if applicable.
  Future<void> stopAll() async {
    final hadStarted = _startedAt != null && _isRunning;
    _timer?.cancel();
    _isRunning = false;
    await _audio.stopAll();

    if (hadStarted && _startedAt != null) {
      final now = DateTime.now();
      final actualMinutes = now.difference(_startedAt!).inMinutes;
      if (actualMinutes >= 1) {
        await _saveSession(actualMinutes, completed: false);
      }
    }

    _secondsLeft = _selectedMinutes * 60;
    _startedAt = null;
    notifyListeners();
  }

  /// Called when timer reaches zero. Saves completed session.
  Future<void> _completeSession() async {
    _timer?.cancel();
    _isRunning = false;
    await _audio.stopAll();

    await _saveSession(_selectedMinutes, completed: true);

    _secondsLeft = _selectedMinutes * 60;
    _startedAt = null;
    notifyListeners();
  }

  /// Persist Pomodoro record + study session to Supabase.
  Future<void> _saveSession(int minutes, {required bool completed}) async {
    final now = DateTime.now();
    final start = _startedAt ?? now.subtract(Duration(minutes: minutes));

    // Save pomodoro record to Supabase
    final record = PomodoroRecord(
      userId: _userId,
      startTime: start,
      endTime: now,
      focusMinutes: minutes,
      breakMinutes: 5,
      completed: completed,
      createdAt: now,
    );
    await _db.insertPomodoroRecord(record.toMap());

    // Also save as a study session to Supabase
    final title = _linkedTask != null
        ? _linkedTask!.title
        : '${minutes}min Focus Session';
    final subject = _linkedTask?.subject ?? 'General';

    await _db.insertSession({
      'user_id': _userId,
      'task_id': _linkedTask?.id,
      'title': title,
      'subject': subject,
      'start_time': start.toIso8601String(),
      'end_time': now.toIso8601String(),
      'duration_minutes': minutes,
      'notes': completed ? 'Pomodoro completed' : 'Pomodoro stopped early',
      'created_at': now.toIso8601String(),
    });

    _sessionJustSaved = true;
    _refresh.triggerRefresh();
  }
}
