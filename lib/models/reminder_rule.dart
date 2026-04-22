/// reminder_rule.dart — Data model for study task reminders.
///
/// Maps to the [reminder_rules] table. Each reminder is linked to
/// a task and triggers a local notification at the specified time.

class ReminderRule {
  final int? id;
  final String userId;
  final int taskId;
  final String reminderType;
  final DateTime triggerTime;
  final bool isActive;
  final DateTime createdAt;

  ReminderRule({
    this.id,
    required this.userId,
    required this.taskId,
    required this.reminderType,
    required this.triggerTime,
    required this.isActive,
    required this.createdAt,
  });

  ReminderRule copyWith({
    int? id,
    String? userId,
    int? taskId,
    String? reminderType,
    DateTime? triggerTime,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ReminderRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      reminderType: reminderType ?? this.reminderType,
      triggerTime: triggerTime ?? this.triggerTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'reminder_type': reminderType,
      'trigger_time': triggerTime.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderRule.fromMap(Map<String, dynamic> map) {
    return ReminderRule(
      id: (map['id'] as num?)?.toInt(),
      userId: map['user_id'] as String? ?? '',
      taskId: (map['task_id'] as num?)?.toInt() ?? 0,
      reminderType: map['reminder_type'] as String? ?? 'Custom',
      triggerTime: DateTime.tryParse(map['trigger_time'] as String? ?? '') ??
          DateTime.now(),
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}