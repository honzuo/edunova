import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reminder_rule.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notification = NotificationService();

  List<ReminderRule> _reminders = [];
  List<ReminderRule> get reminders => _reminders;

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

  Future<void> loadReminders() async {
    final data = await _db.getRemindersByUser(_userId);
    _reminders = data.map((map) => ReminderRule.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addReminder({
    required int taskId,
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

    await _notification.scheduleReminder(
      id: id,
      title: 'Study Reminder',
      body: 'You have a task reminder scheduled.',
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