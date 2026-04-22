/// database_service.dart — Data access layer for EduNova.
///
/// Architecture:
/// ┌─────────────────────────────────────────────────────────┐
/// │  SUPABASE (Primary — cloud, important data)            │
/// │  app_users, study_tasks, study_sessions,               │
/// │  pomodoro_records, cgpa_records, subjects               │
/// ├─────────────────────────────────────────────────────────┤
/// │  SQLITE (Local — device-only, less critical data)      │
/// │  achievements, study_goals, reminder_rules,            │
/// │  user_preferences                                       │
/// └─────────────────────────────────────────────────────────┘
///
/// All important CRUD goes DIRECTLY to Supabase.
/// SQLite is only for local features (badges, goals, reminders).

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Supabase client shorthand.
  SupabaseClient get _supa => Supabase.instance.client;

  /// Local SQLite database (for achievements, goals, reminders, preferences).
  Future<Database> get database async {
    _database ??= await _initLocalDatabase();
    return _database!;
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║           SQLITE — Local database setup                  ║
  // ║  Only for: achievements, study_goals, reminder_rules,    ║
  // ║            user_preferences                              ║
  // ╚══════════════════════════════════════════════════════════╝

  Future<Database> _initLocalDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'edunova_local.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createLocalTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Recreate tables if upgrading from old schema
          await _createLocalTables(db);
        }
      },
    );
  }

  /// Create SQLite tables for LOCAL-ONLY data.
  Future<void> _createLocalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT, user_id TEXT, title TEXT, description TEXT, icon_name TEXT,
        target_value INTEGER, current_value INTEGER, is_unlocked INTEGER,
        unlocked_at TEXT,
        PRIMARY KEY (id, user_id))
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, title TEXT,
        goal_type TEXT, target_value INTEGER, current_value INTEGER DEFAULT 0,
        start_date TEXT, end_date TEXT, is_completed INTEGER DEFAULT 0,
        created_at TEXT)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, task_id INTEGER,
        reminder_type TEXT, trigger_time TEXT, is_active INTEGER,
        created_at TEXT)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT,
        dark_mode INTEGER, notification_enabled INTEGER,
        default_reminder_type TEXT, daily_summary_enabled INTEGER)
    ''');
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║           SUPABASE — Cloud database operations           ║
  // ║  For: app_users, study_tasks, study_sessions,            ║
  // ║       pomodoro_records, cgpa_records, subjects            ║
  // ╚══════════════════════════════════════════════════════════╝

  // ═══════════════════════════════════════
  // ── TASKS (Supabase) ──
  // ═══════════════════════════════════════

  /// Insert a new task. Returns the Supabase row with generated ID.
  Future<Map<String, dynamic>> insertTask(Map<String, dynamic> task) async {
    final clean = _cleanForSupabase(task);
    final result = await _supa.from('study_tasks').insert(clean).select().single();
    return result;
  }

  /// Get all tasks for a user, ordered by deadline.
  Future<List<Map<String, dynamic>>> getTasksByUser(String userId) async {
    return await _supa
        .from('study_tasks')
        .select()
        .eq('user_id', userId)
        .order('deadline', ascending: true);
  }

  /// Delete a task by its Supabase ID.
  Future<void> deleteTask(int id) async {
    await _supa.from('study_tasks').delete().eq('id', id);
  }

  /// Update a task by its Supabase ID.
  Future<void> updateTask(int id, Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    clean.remove('id'); // Don't update the primary key
    await _supa.from('study_tasks').update(clean).eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── SESSIONS (Supabase) ──
  // ═══════════════════════════════════════

  /// Insert a new study session. Returns the Supabase row.
  Future<Map<String, dynamic>> insertSession(Map<String, dynamic> session) async {
    final clean = _cleanForSupabase(session);
    final result = await _supa.from('study_sessions').insert(clean).select().single();
    return result;
  }

  /// Get all sessions for a user, ordered by start time descending.
  Future<List<Map<String, dynamic>>> getSessionsByUser(String userId) async {
    return await _supa
        .from('study_sessions')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);
  }

  /// Delete a session by its Supabase ID.
  Future<void> deleteSession(int id) async {
    await _supa.from('study_sessions').delete().eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── POMODORO (Supabase) ──
  // ═══════════════════════════════════════

  /// Insert a new pomodoro record. Returns the Supabase row.
  Future<Map<String, dynamic>> insertPomodoroRecord(Map<String, dynamic> record) async {
    final clean = _cleanForSupabase(record);
    final result = await _supa.from('pomodoro_records').insert(clean).select().single();
    return result;
  }

  /// Get all pomodoro records for a user.
  Future<List<Map<String, dynamic>>> getPomodorosByUser(String userId) async {
    return await _supa
        .from('pomodoro_records')
        .select()
        .eq('user_id', userId);
  }

  // ═══════════════════════════════════════
  // ── USER PROFILE (Supabase) ──
  // ═══════════════════════════════════════

  /// Get user profile by ID. Returns null if not found.
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    return await _supa
        .from('app_users')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  /// Update user profile fields.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final clean = Map<String, dynamic>.from(data);
    clean.remove('id');           // Don't update PK
    clean.remove('password_hash'); // Never overwrite password from profile
    // Convert SQLite-style int booleans to Supabase booleans
    if (clean.containsKey('dark_mode')) {
      clean['dark_mode'] = clean['dark_mode'] == 1 || clean['dark_mode'] == true;
    }
    await _supa.from('app_users').update(clean).eq('id', userId);
  }

  // ═══════════════════════════════════════
  // ── CGPA RECORDS (Supabase) ──
  // ═══════════════════════════════════════

  /// Insert a new CGPA record. Returns the Supabase row with ID.
  Future<Map<String, dynamic>> insertCgpaRecord(Map<String, dynamic> record) async {
    final clean = _cleanForSupabase(record);
    final result = await _supa.from('cgpa_records').insert(clean).select().single();
    return result;
  }

  /// Get all CGPA records for a user, ordered by year and semester.
  Future<List<Map<String, dynamic>>> getCgpaRecordsByUser(String userId) async {
    return await _supa
        .from('cgpa_records')
        .select()
        .eq('user_id', userId)
        .order('year', ascending: true)
        .order('semester', ascending: true);
  }

  /// Update a CGPA record by its Supabase ID.
  Future<void> updateCgpaRecord(int id, Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    clean.remove('id');
    await _supa.from('cgpa_records').update(clean).eq('id', id);
  }

  /// Delete a CGPA record by its Supabase ID.
  Future<void> deleteCgpaRecord(int id) async {
    await _supa.from('cgpa_records').delete().eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── SUBJECTS (Supabase) ──
  // ═══════════════════════════════════════

  /// Get all subjects for a user, ordered by code.
  Future<List<Map<String, dynamic>>> getSubjectsByUser(String userId) async {
    return await _supa
        .from('subjects')
        .select()
        .eq('user_id', userId)
        .order('code', ascending: true);
  }

  /// Insert a new subject.
  Future<void> insertSubject(Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    await _supa.from('subjects').insert(clean);
  }

  /// Update a subject by its Supabase ID.
  Future<void> updateSubject(int id, Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    clean.remove('id');
    await _supa.from('subjects').update(clean).eq('id', id);
  }

  /// Delete a subject by its Supabase ID.
  Future<void> deleteSubject(int id) async {
    await _supa.from('subjects').delete().eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── SEARCH (Supabase) ──
  // ═══════════════════════════════════════

  /// Search tasks by title, subject, or description.
  Future<List<Map<String, dynamic>>> searchTasks(String userId, String query) async {
    return await _supa
        .from('study_tasks')
        .select()
        .eq('user_id', userId)
        .or('title.ilike.%$query%,subject.ilike.%$query%,description.ilike.%$query%');
  }

  // ═══════════════════════════════════════
  // ── STUDY LOCATIONS (Supabase — GPS) ──
  // ═══════════════════════════════════════

  /// Get all saved study locations for a user.
  Future<List<Map<String, dynamic>>> getStudyLocations(String userId) async {
    return await _supa
        .from('study_locations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// Insert a new study location with GPS coordinates.
  Future<void> insertStudyLocation(Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    await _supa.from('study_locations').insert(clean);
  }

  /// Delete a study location by its Supabase ID.
  Future<void> deleteStudyLocation(int id) async {
    await _supa.from('study_locations').delete().eq('id', id);
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║           SQLITE — Local-only operations                 ║
  // ║  For: achievements, study_goals, reminder_rules,         ║
  // ║       user_preferences                                   ║
  // ╚══════════════════════════════════════════════════════════╝

  // ── REMINDERS (SQLite — local only) ──

  Future<int> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    return await db.insert('reminder_rules', reminder);
  }

  Future<List<Map<String, dynamic>>> getRemindersByUser(String userId) async {
    final db = await database;
    return await db.query('reminder_rules',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'trigger_time ASC');
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete('reminder_rules', where: 'id = ?', whereArgs: [id]);
  }

  // ── ACHIEVEMENTS (SQLite — local only) ──

  Future<List<Map<String, dynamic>>> getAchievementsByUser(String userId) async {
    final db = await database;
    return await db.query('achievements',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> upsertAchievement(String userId, Map<String, dynamic> data) async {
    final db = await database;
    data['user_id'] = userId;
    await db.insert('achievements', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── GOALS (SQLite — local only) ──

  Future<int> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;
    return await db.insert('study_goals', goal);
  }

  Future<List<Map<String, dynamic>>> getGoalsByUser(String userId) async {
    final db = await database;
    return await db.query('study_goals',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
  }

  Future<void> updateGoalProgress(int id, int currentValue,
      {bool? isCompleted}) async {
    final db = await database;
    final data = <String, dynamic>{'current_value': currentValue};
    if (isCompleted != null) data['is_completed'] = isCompleted ? 1 : 0;
    await db.update('study_goals', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete('study_goals', where: 'id = ?', whereArgs: [id]);
  }

  // ── PREFERENCES (SQLite — local only) ──

  Future<int> insertUserPreference(Map<String, dynamic> pref) async {
    final db = await database;
    return await db.insert('user_preferences', pref,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserPreference(String userId) async {
    final db = await database;
    final result = await db.query('user_preferences',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (result.isEmpty) return null;
    return result.first;
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║           HELPER — clean data before sending             ║
  // ╚══════════════════════════════════════════════════════════╝

  /// Remove fields that Supabase auto-generates or doesn't need.
  Map<String, dynamic> _cleanForSupabase(Map<String, dynamic> data) {
    final clean = Map<String, dynamic>.from(data);
    clean.remove('id');       // Supabase auto-generates bigint ID
    clean.remove('local_id'); // Legacy field, no longer used
    return clean;
  }
}
