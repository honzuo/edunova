/// app_user.dart — Data model for the application user.
///
/// Maps to the [app_users] table in both SQLite and Supabase.
/// Stores personal information, preferences (dark mode, target GPA),
/// and profile photo path. Supports JSON serialization via [toMap]/[fromMap].

class AppUser {
  final String id, email, passwordHash, fullName, gender, institution, course, studyGoal, profilePhotoPath;
  final int age;
  final double targetGpa;
  final bool darkMode;
  final DateTime createdAt;

  AppUser({required this.id, required this.email, this.passwordHash = '', required this.fullName,
    required this.age, required this.gender, required this.institution, required this.course,
    required this.studyGoal, this.targetGpa = 3.5, this.profilePhotoPath = '', this.darkMode = false, required this.createdAt});

  AppUser copyWith({String? id, String? email, String? passwordHash, String? fullName, int? age, String? gender,
    String? institution, String? course, String? studyGoal, double? targetGpa, String? profilePhotoPath, bool? darkMode, DateTime? createdAt}) =>
    AppUser(id: id ?? this.id, email: email ?? this.email, passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName, age: age ?? this.age, gender: gender ?? this.gender,
      institution: institution ?? this.institution, course: course ?? this.course, studyGoal: studyGoal ?? this.studyGoal,
      targetGpa: targetGpa ?? this.targetGpa, profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      darkMode: darkMode ?? this.darkMode, createdAt: createdAt ?? this.createdAt);

  Map<String, dynamic> toMap() => {'id': id, 'email': email, 'password_hash': passwordHash, 'full_name': fullName,
    'age': age, 'gender': gender, 'institution': institution, 'course': course, 'study_goal': studyGoal,
    'target_gpa': targetGpa, 'profile_photo_path': profilePhotoPath, 'dark_mode': darkMode ? 1 : 0, 'created_at': createdAt.toIso8601String()};

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(id: m['id'] as String? ?? '', email: m['email'] as String? ?? '',
    passwordHash: m['password_hash'] as String? ?? '', fullName: m['full_name'] as String? ?? '',
    age: (m['age'] as num?)?.toInt() ?? 0, gender: m['gender'] as String? ?? '', institution: m['institution'] as String? ?? '',
    course: m['course'] as String? ?? '', studyGoal: m['study_goal'] as String? ?? '',
    targetGpa: (m['target_gpa'] as num?)?.toDouble() ?? 3.5, profilePhotoPath: m['profile_photo_path'] as String? ?? '',
    darkMode: m['dark_mode'] == 1 || m['dark_mode'] == true,
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now());
}
