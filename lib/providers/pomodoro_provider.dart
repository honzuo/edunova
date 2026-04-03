import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pomodoro_record.dart';
import '../services/database_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  Timer? _timer;

  int _secondsLeft = 25 * 60;
  bool _isRunning = false;

  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

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
    _secondsLeft = 25 * 60;
    _isRunning = false;
    notifyListeners();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _isRunning = false;

    final now = DateTime.now();

    final record = PomodoroRecord(
      userId: _userId,
      startTime: now.subtract(const Duration(minutes: 25)),
      endTime: now,
      focusMinutes: 25,
      breakMinutes: 5,
      completed: true,
      createdAt: now,
    );

    await _db.insertPomodoroRecord(record.toMap());

    _secondsLeft = 25 * 60;

    notifyListeners();
  }
}