import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_task.dart';
import '../services/database_service.dart';

enum TaskFilter {
  all,
  completed,
  pending,
}

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<StudyTask> _tasks = [];
  List<StudyTask> get tasks => _tasks;

  String get _userId => Supabase.instance.client.auth.currentUser!.id;

  Future<void> loadTasks() async {
    final data = await _db.getTasksByUser(_userId);

    _tasks = data.map((map) => StudyTask.fromMap(map)).toList();
    notifyListeners();
  }

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
  }

  Future<void> removeTask(int id) async {
    await _db.deleteTask(id);
    await loadTasks();
  }

  Future<void> toggleComplete(StudyTask task) async {
    if (task.id == null) return;

    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
    );

    await _db.updateTask(task.id!, updated.toMap());
    await loadTasks();
  }

  Future<void> updateTask(StudyTask task) async {
    if (task.id == null) return;

    await _db.updateTask(task.id!, task.toMap());
    await loadTasks();
  }

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
}