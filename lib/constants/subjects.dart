/// subjects.dart — Subject CRUD service using Supabase.
///
/// All subject data is stored in Supabase (cloud).
/// Provides methods for listing, adding, updating, and deleting subjects.
/// Used by task creation, CGPA calculator, and session logging.

import '../models/subject.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SubjectService {
  static final SubjectService _instance = SubjectService._();
  factory SubjectService() => _instance;
  SubjectService._();

  final DatabaseService _db = DatabaseService();
  List<Subject> _subjects = [];

  /// All loaded subjects.
  List<Subject> get subjects => _subjects;

  /// Subject display names for dropdowns (e.g. "CSC1024 - Programming").
  List<String> get names => _subjects.map((s) => s.display).toList();

  /// Subject names only (without code).
  List<String> get nameOnly => _subjects.map((s) => s.name).toList();

  String get _uid => AuthService().currentUserId ?? 'demo-user';

  /// Load subjects from Supabase.
  Future<void> load() async {
    try {
      final rows = await _db.getSubjectsByUser(_uid);
      _subjects = rows.map((r) => Subject.fromMap(r)).toList();
    } catch (e) {
      _subjects = [];
    }
  }

  /// CREATE — Add a new subject to Supabase.
  Future<void> add({
    required String code,
    required String name,
    required int creditHour,
  }) async {
    await _db.insertSubject({
      'user_id': _uid,
      'code': code.trim(),
      'name': name.trim(),
      'credit_hour': creditHour,
      'created_at': DateTime.now().toIso8601String(),
    });
    await load();
  }

  /// UPDATE — Edit a subject in Supabase.
  Future<void> update(int id, {
    required String code,
    required String name,
    required int creditHour,
  }) async {
    await _db.updateSubject(id, {
      'code': code.trim(),
      'name': name.trim(),
      'credit_hour': creditHour,
    });
    await load();
  }

  /// DELETE — Remove a subject from Supabase.
  Future<void> delete(int id) async {
    await _db.deleteSubject(id);
    await load();
  }

  /// Find subject by name (used in CGPA calculator for credit hours).
  Subject? findByName(String name) {
    try {
      return _subjects.firstWhere(
          (s) => s.name == name || s.display == name);
    } catch (_) {
      return null;
    }
  }
}
