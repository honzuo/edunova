/// cgpa_record.dart — Data models for CGPA calculation.
///
/// [CgpaCourse] represents a single course with name, credits, and grade.
/// [CgpaRecord] represents a semester's GPA record stored in the
/// [cgpa_records] table. Courses are stored as a JSON-encoded string.

class CgpaCourse {
  String name;
  int credits;
  String? grade;

  CgpaCourse({this.name = '', this.credits = 3, this.grade});

  Map<String, dynamic> toMap() => {'name': name, 'credits': credits, 'grade': grade};

  factory CgpaCourse.fromMap(Map<String, dynamic> map) => CgpaCourse(
    name: map['name'] as String? ?? '',
    credits: (map['credits'] as num?)?.toInt() ?? 3,
    grade: map['grade'] as String?,
  );
}

class CgpaRecord {
  final int? id;
  final String userId;
  final int year;
  final int semester;
  final double gpa;
  final int totalCredits;
  final String coursesJson; // JSON encoded list of CgpaCourse
  final DateTime createdAt;

  CgpaRecord({
    this.id,
    required this.userId,
    required this.year,
    required this.semester,
    required this.gpa,
    required this.totalCredits,
    required this.coursesJson,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'user_id': userId, 'year': year, 'semester': semester,
    'gpa': gpa, 'total_credits': totalCredits,
    'courses_json': coursesJson, 'created_at': createdAt.toIso8601String(),
  };

  factory CgpaRecord.fromMap(Map<String, dynamic> map) => CgpaRecord(
    id: (map['id'] as num?)?.toInt(),
    userId: map['user_id'] as String? ?? '',
    year: (map['year'] as num?)?.toInt() ?? 1,
    semester: (map['semester'] as num?)?.toInt() ?? 1,
    gpa: (map['gpa'] as num?)?.toDouble() ?? 0,
    totalCredits: (map['total_credits'] as num?)?.toInt() ?? 0,
    coursesJson: map['courses_json'] as String? ?? '[]',
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  String get label => 'Year $year Sem $semester';
}
