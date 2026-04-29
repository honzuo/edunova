/// study_task.dart — Data model for a study task.
///
/// Maps to the [study_tasks] table. Each task has a title, description,
/// subject, deadline, priority (Low/Medium/High), and completion status.
/// Supports CRUD operations through [DatabaseService].

class StudyTask {
  final int? id;
  final String userId;
  final String title;
  final String description;
  final String subject;
  final DateTime deadline;
  final String priority;
  final bool isCompleted;
  final String? proofPhotoPath;
  final DateTime createdAt;

  StudyTask({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.subject,
    required this.deadline,
    required this.priority,
    required this.isCompleted,
    this.proofPhotoPath,
    required this.createdAt,
  });

  StudyTask copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    String? subject,
    DateTime? deadline,
    String? priority,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return StudyTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      proofPhotoPath: proofPhotoPath ?? this.proofPhotoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'subject': subject,
      'deadline': deadline.toIso8601String(),
      'priority': priority,
      'is_completed': isCompleted ? 1 : 0,
      'proof_photo_path': proofPhotoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StudyTask.fromMap(Map<String, dynamic> map) {
    return StudyTask(
      id: (map['id'] as num?)?.toInt(),
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      deadline:
      DateTime.tryParse(map['deadline'] as String? ?? '') ?? DateTime.now(),
      priority: map['priority'] as String? ?? 'Medium',
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      proofPhotoPath: map['proof_photo_path'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}