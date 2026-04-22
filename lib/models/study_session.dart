/// study_session.dart — Data model for a study session record.
///
/// Maps to the [study_sessions] table. Tracks when a user studied,
/// for how long, which subject, and any notes. Can be linked to a task
/// via [taskId] for progress tracking.

class StudySession {
  final int? id;
  final String userId;
  final int? taskId;
  final String title;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String notes;
  final DateTime createdAt;

  StudySession({
    this.id,
    required this.userId,
    this.taskId,
    required this.title,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.notes,
    required this.createdAt,
  });

  StudySession copyWith({
    int? id,
    String? userId,
    int? taskId,
    String? title,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? notes,
    DateTime? createdAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'title': title,
      'subject': subject,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: (map['id'] as num?)?.toInt(),
      userId: map['user_id'] as String? ?? '',
      taskId: (map['task_id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      startTime: DateTime.tryParse(map['start_time'] as String? ?? '') ??
          DateTime.now(),
      endTime:
      DateTime.tryParse(map['end_time'] as String? ?? '') ?? DateTime.now(),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}