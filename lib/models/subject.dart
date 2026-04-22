/// subject.dart — Data model for academic subjects.
///
/// Maps to the [subjects] table in SQLite and Supabase.
/// Each subject has a code (e.g. CSC1024), name, and credit hours.
/// Used for task categorization and CGPA calculation.

/// Subject model with code, name, and credit hours.
/// Stored in Supabase [subjects] table and local SQLite.
class Subject {
  final int? id;
  final String userId;
  final String code;
  final String name;
  final int creditHour;
  final DateTime createdAt;

  Subject({
    this.id, required this.userId, required this.code,
    required this.name, required this.creditHour, required this.createdAt,
  });

  /// Display as "CODE - Name"
  String get display => '$code - $name';

  Map<String, dynamic> toMap() => {
    'id': id, 'user_id': userId, 'code': code,
    'name': name, 'credit_hour': creditHour,
    'created_at': createdAt.toIso8601String(),
  };

  factory Subject.fromMap(Map<String, dynamic> m) => Subject(
    id: (m['id'] as num?)?.toInt(),
    userId: m['user_id'] as String? ?? '',
    code: m['code'] as String? ?? '',
    name: m['name'] as String? ?? '',
    creditHour: (m['credit_hour'] as num?)?.toInt() ?? 3,
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
