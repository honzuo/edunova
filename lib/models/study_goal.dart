/// study_goal.dart — Data model for user-defined study goals.
///
/// Maps to the [study_goals] table. Goals can track weekly/monthly
/// study hours, daily completed tasks, or study streaks.
/// Progress is automatically updated by [GoalProvider].

class StudyGoal {
  final int? id;
  final String userId;
  final String title;
  final String goalType; // weekly_hours, monthly_hours, daily_tasks, streak
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final DateTime createdAt;

  StudyGoal({
    this.id,
    required this.userId,
    required this.title,
    required this.goalType,
    required this.targetValue,
    this.currentValue = 0,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  StudyGoal copyWith({
    int? id,
    String? userId,
    String? title,
    String? goalType,
    int? targetValue,
    int? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return StudyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      goalType: goalType ?? this.goalType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress =>
      targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'goal_type': goalType,
      'target_value': targetValue,
      'current_value': currentValue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StudyGoal.fromMap(Map<String, dynamic> map) {
    return StudyGoal(
      id: (map['id'] as num?)?.toInt(),
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      goalType: map['goal_type'] as String? ?? 'weekly_hours',
      targetValue: (map['target_value'] as num?)?.toInt() ?? 0,
      currentValue: (map['current_value'] as num?)?.toInt() ?? 0,
      startDate: DateTime.tryParse(map['start_date'] as String? ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(map['end_date'] as String? ?? '') ??
          DateTime.now(),
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
