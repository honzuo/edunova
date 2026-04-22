/// achievement_provider.dart — State management for gamification.
///
/// Defines 12 achievement badges across 4 categories:
/// - Task completion (1, 10, 50 tasks)
/// - Pomodoro sessions (10, 50, 100 sessions)
/// - Study streaks (3, 7, 30 days)
/// - Total study time (10, 50, 100 hours)
///
/// Calculates study streak by checking consecutive study days.
/// Persists achievement progress to SQLite.

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

import '../models/achievement.dart';
import '../services/database_service.dart';

class AchievementProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Achievement> _achievements = [];
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlocked =>
      _achievements.where((a) => a.isUnlocked).toList();

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  String get _userId =>
      AuthService().currentUserId ?? 'demo-user';

  static final List<Achievement> _definitions = [
    Achievement(
      id: 'first_task',
      title: 'Getting Started',
      description: 'Complete your first task',
      iconName: 'star',
      targetValue: 1,
    ),
    Achievement(
      id: 'task_10',
      title: 'Task Master',
      description: 'Complete 10 tasks',
      iconName: 'task_alt',
      targetValue: 10,
    ),
    Achievement(
      id: 'task_50',
      title: 'Unstoppable',
      description: 'Complete 50 tasks',
      iconName: 'military_tech',
      targetValue: 50,
    ),
    Achievement(
      id: 'pomodoro_10',
      title: 'Focus Beginner',
      description: 'Complete 10 pomodoro sessions',
      iconName: 'timer',
      targetValue: 10,
    ),
    Achievement(
      id: 'pomodoro_50',
      title: 'Deep Focus',
      description: 'Complete 50 pomodoro sessions',
      iconName: 'psychology',
      targetValue: 50,
    ),
    Achievement(
      id: 'pomodoro_100',
      title: 'Focus Legend',
      description: 'Complete 100 pomodoro sessions',
      iconName: 'emoji_events',
      targetValue: 100,
    ),
    Achievement(
      id: 'streak_3',
      title: 'On a Roll',
      description: 'Study 3 days in a row',
      iconName: 'local_fire_department',
      targetValue: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Weekly Warrior',
      description: 'Study 7 days in a row',
      iconName: 'whatshot',
      targetValue: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Monthly Champion',
      description: 'Study 30 days in a row',
      iconName: 'diamond',
      targetValue: 30,
    ),
    Achievement(
      id: 'study_10h',
      title: 'Dedicated Learner',
      description: 'Study for a total of 10 hours',
      iconName: 'school',
      targetValue: 600,
    ),
    Achievement(
      id: 'study_50h',
      title: 'Knowledge Seeker',
      description: 'Study for a total of 50 hours',
      iconName: 'auto_stories',
      targetValue: 3000,
    ),
    Achievement(
      id: 'study_100h',
      title: 'Scholar',
      description: 'Study for a total of 100 hours',
      iconName: 'workspace_premium',
      targetValue: 6000,
    ),
  ];

  Future<void> loadAchievements() async {
    final saved = await _db.getAchievementsByUser(_userId);
    final savedMap = {for (var a in saved) a['id'] as String: a};

    _achievements = _definitions.map((def) {
      final s = savedMap[def.id];
      if (s != null) return Achievement.fromMap(s);
      return def;
    }).toList();

    notifyListeners();
  }

  Future<void> evaluate({
    required int completedTasks,
    required int pomodoroCount,
    required int totalStudyMinutes,
    required int streak,
  }) async {
    _currentStreak = streak;

    final Map<String, int> valueMap = {
      'first_task': completedTasks,
      'task_10': completedTasks,
      'task_50': completedTasks,
      'pomodoro_10': pomodoroCount,
      'pomodoro_50': pomodoroCount,
      'pomodoro_100': pomodoroCount,
      'streak_3': streak,
      'streak_7': streak,
      'streak_30': streak,
      'study_10h': totalStudyMinutes,
      'study_50h': totalStudyMinutes,
      'study_100h': totalStudyMinutes,
    };

    for (int i = 0; i < _achievements.length; i++) {
      final a = _achievements[i];
      final value = valueMap[a.id] ?? 0;
      final wasUnlocked = a.isUnlocked;
      final nowUnlocked = value >= a.targetValue;

      _achievements[i] = a.copyWith(
        currentValue: value,
        isUnlocked: nowUnlocked,
        unlockedAt:
            nowUnlocked && !wasUnlocked ? DateTime.now() : a.unlockedAt,
      );

      await _db.upsertAchievement(_userId, _achievements[i].toMap());
    }

    notifyListeners();
  }

  Future<int> calculateStreak() async {
    final sessions = await _db.getSessionsByUser(_userId);
    if (sessions.isEmpty) return 0;

    final Set<String> studyDays = {};
    for (final s in sessions) {
      final dt = DateTime.tryParse(s['start_time'] as String? ?? '');
      if (dt != null) {
        studyDays.add('${dt.year}-${dt.month}-${dt.day}');
      }
    }

    final pomodoros = await _db.getPomodorosByUser(_userId);
    for (final p in pomodoros) {
      final dt = DateTime.tryParse(p['start_time'] as String? ?? '');
      if (dt != null) {
        studyDays.add('${dt.year}-${dt.month}-${dt.day}');
      }
    }

    int streak = 0;
    DateTime day = DateTime.now();
    final todayKey = '${day.year}-${day.month}-${day.day}';

    if (!studyDays.contains(todayKey)) {
      day = day.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = '${day.year}-${day.month}-${day.day}';
      if (studyDays.contains(key)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    _currentStreak = streak;
    return streak;
  }
}
