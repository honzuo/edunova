/// reminder_provider.dart — State management for task reminders.
///
/// Manages reminder CRUD operations and schedules/cancels
/// local notifications through [NotificationService].

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

import '../models/reminder_rule.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notification = NotificationService();

  List<ReminderRule> _reminders = [];
  List<ReminderRule> get reminders => _reminders;

  String get _userId =>
      AuthService().currentUserId ?? 'demo-user';

  Future<void> loadReminders() async {
    final data = await _db.getRemindersByUser(_userId);
    _reminders = data.map((map) => ReminderRule.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addReminder({
    required int taskId,
    required String taskTitle,
    required String reminderType,
    required DateTime triggerTime,
  }) async {
    final reminder = ReminderRule(
      userId: _userId,
      taskId: taskId,
      reminderType: reminderType,
      triggerTime: triggerTime,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final id = await _db.insertReminder(reminder.toMap());

    // Schedule a local push notification with the task title
    await _notification.scheduleReminder(
      id: id,
      title: '📚 Study Reminder',
      body: '$taskTitle — $reminderType',
      triggerTime: triggerTime,
    );

    await loadReminders();
  }

  Future<void> removeReminder(int id) async {
    await _db.deleteReminder(id);
    await _notification.cancelReminder(id);
    await loadReminders();
  }
}