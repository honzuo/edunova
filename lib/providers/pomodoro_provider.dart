import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pomodoro_record.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AudioService _audio = AudioService();

  Timer? _timer;

  // ── Duration Options ──
  static const List<int> durationOptions = [5, 10, 15, 20, 25, 30, 45, 60];
  int _selectedMinutes = 25;
  int get selectedMinutes => _selectedMinutes;

  int _secondsLeft = 25 * 60;
  bool _isRunning = false;

  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  double get progress {
    final total = _selectedMinutes * 60;
    return total == 0 ? 0 : 1.0 - (_secondsLeft / total);
  }

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

  void setDuration(int minutes) {
    if (_isRunning) return;
    _selectedMinutes = minutes;
    _secondsLeft = minutes * 60;
    notifyListeners();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;

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

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _secondsLeft = _selectedMinutes * 60;
    _isRunning = false;
    notifyListeners();
  }

  /// Stop timer + all audio
  Future<void> stopAll() async {
    _timer?.cancel();
    _isRunning = false;
    await _audio.stopAll();
    _secondsLeft = _selectedMinutes * 60;
    notifyListeners();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _isRunning = false;

    // Fade out all audio
    await _audio.stopAll();

    final now = DateTime.now();
    final record = PomodoroRecord(
      userId: _userId,
      startTime: now.subtract(Duration(minutes: _selectedMinutes)),
      endTime: now,
      focusMinutes: _selectedMinutes,
      breakMinutes: 5,
      completed: true,
      createdAt: now,
    );
    await _db.insertPomodoroRecord(record.toMap());

    _secondsLeft = _selectedMinutes * 60;
    notifyListeners();
  }
}
