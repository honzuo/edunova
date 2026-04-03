class PomodoroRecord {
  final int? id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int focusMinutes;
  final int breakMinutes;
  final bool completed;
  final DateTime createdAt;

  PomodoroRecord({
    this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.completed,
    required this.createdAt,
  });

  PomodoroRecord copyWith({
    int? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? focusMinutes,
    int? breakMinutes,
    bool? completed,
    DateTime? createdAt,
  }) {
    return PomodoroRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'focus_minutes': focusMinutes,
      'break_minutes': breakMinutes,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PomodoroRecord.fromMap(Map<String, dynamic> map) {
    return PomodoroRecord(
      id: (map['id'] as num?)?.toInt(),
      userId: map['user_id'] as String? ?? '',
      startTime: DateTime.tryParse(map['start_time'] as String? ?? '') ??
          DateTime.now(),
      endTime:
      DateTime.tryParse(map['end_time'] as String? ?? '') ?? DateTime.now(),
      focusMinutes: (map['focus_minutes'] as num?)?.toInt() ?? 25,
      breakMinutes: (map['break_minutes'] as num?)?.toInt() ?? 5,
      completed: map['completed'] == 1 || map['completed'] == true,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}