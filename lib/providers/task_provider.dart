/// task_provider.dart — State management for study tasks.
///
/// All task data is stored in Supabase (cloud).
/// CRUD operations go directly to Supabase via [DatabaseService].

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/study_task.dart';
import '../services/database_service.dart';
import '../services/app_refresh_service.dart';

enum TaskFilter { all, completed, pending }

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AppRefreshService _refresh = AppRefreshService();

  List<StudyTask> _tasks = [];
  List<StudyTask> get tasks => _tasks;

  String get _userId => AuthService().currentUserId ?? 'demo-user';

  /// Load all tasks from Supabase for the current user.
  Future<void> loadTasks() async {
    try {
      final data = await _db.getTasksByUser(_userId);
      _tasks = data.map((map) => StudyTask.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  /// Create a new task in Supabase.
  Future<void> addTask({
    required String title,
    required String description,
    required String subject,
    required DateTime deadline,
    required String priority,
  }) async {
    final task = StudyTask(
      userId: _userId,
      title: title,
      description: description,
      subject: subject,
      deadline: deadline,
      priority: priority,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    await _db.insertTask(task.toMap());
    await loadTasks();
    _refresh.triggerRefresh();
  }

  /// Delete a task from Supabase by ID.
  Future<void> removeTask(int id) async {
    await _db.deleteTask(id);
    await loadTasks();
    _refresh.triggerRefresh();
  }

  /// Toggle task completion status in Supabase.
  Future<void> toggleComplete(StudyTask task) async {
    if (task.id == null) return;
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _db.updateTask(task.id!, updated.toMap());
    await loadTasks();
    _refresh.triggerRefresh();
  }

  /// Update an existing task in Supabase.
  Future<void> updateTask(StudyTask task) async {
    if (task.id == null) return;
    await _db.updateTask(task.id!, task.toMap());
    await loadTasks();
    _refresh.triggerRefresh();
  }

  // ── Filter ──

  TaskFilter _filter = TaskFilter.all;
  TaskFilter get filter => _filter;

  List<StudyTask> get filteredTasks {
    switch (_filter) {
      case TaskFilter.completed:
        return _tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.pending:
        return _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  void setFilter(TaskFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  /// Get tasks with deadlines matching today's date.
  List<StudyTask> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((task) {
      final d = task.deadline;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }
}
