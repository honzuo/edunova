/// goal_provider.dart — State management for user-defined study goals.
///
/// Supports four goal types: weekly hours, monthly hours,
/// daily tasks, and study streak. Automatically updates
/// progress values and marks goals as completed.

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

import '../models/study_goal.dart';
import '../services/database_service.dart';

class GoalProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<StudyGoal> _goals = [];
  List<StudyGoal> get goals => _goals;
  List<StudyGoal> get activeGoals =>
      _goals.where((g) => !g.isCompleted).toList();

  String get _userId =>
      AuthService().currentUserId ?? 'demo-user';

  Future<void> loadGoals() async {
    final data = await _db.getGoalsByUser(_userId);
    _goals = data.map((m) => StudyGoal.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addGoal({
    required String title,
    required String goalType,
    required int targetValue,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final goal = StudyGoal(
      userId: _userId,
      title: title,
      goalType: goalType,
      targetValue: targetValue,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );
    await _db.insertGoal(goal.toMap());
    await loadGoals();
  }

  Future<void> updateGoalProgress(int id, int currentValue) async {
    await _db.updateGoalProgress(id, currentValue);
    await loadGoals();
  }

  Future<void> removeGoal(int id) async {
    await _db.deleteGoal(id);
    await loadGoals();
  }

  Future<void> refreshGoalValues({
    required int weeklyStudyMinutes,
    required int monthlyStudyMinutes,
    required int dailyCompletedTasks,
    required int streak,
  }) async {
    for (final goal in _goals) {
      if (goal.isCompleted || goal.id == null) continue;
      int value = 0;
      switch (goal.goalType) {
        case 'weekly_hours':
          value = (weeklyStudyMinutes / 60).round();
          break;
        case 'monthly_hours':
          value = (monthlyStudyMinutes / 60).round();
          break;
        case 'daily_tasks':
          value = dailyCompletedTasks;
          break;
        case 'streak':
          value = streak;
          break;
      }
      final completed = value >= goal.targetValue;
      await _db.updateGoalProgress(goal.id!, value,
          isCompleted: completed);
    }
    await loadGoals();
  }
}
