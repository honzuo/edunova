class AppUser {
  final String id;
  final String email;
  final String fullName;
  final int age;
  final String gender;
  final String institution;
  final String course;
  final String studyGoal;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.institution,
    required this.course,
    required this.studyGoal,
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    int? age,
    String? gender,
    String? institution,
    String? course,
    String? studyGoal,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      institution: institution ?? this.institution,
      course: course ?? this.course,
      studyGoal: studyGoal ?? this.studyGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'institution': institution,
      'course': course,
      'study_goal': studyGoal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] as String? ?? '',
      institution: map['institution'] as String? ?? '',
      course: map['course'] as String? ?? '',
      studyGoal: map['study_goal'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}