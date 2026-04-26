/// database_service.dart — Data access layer for EduNova.
///
/// Architecture:
/// ┌─────────────────────────────────────────────────────────┐
/// │  SUPABASE (Primary — cloud, important data)             │
/// │  app_users, study_tasks, study_sessions,                │
/// │  pomodoro_records, cgpa_records, subjects               │
/// ├─────────────────────────────────────────────────────────┤
/// │  SQLITE (Local — device-only, less critical data)       │
/// │  achievements, study_goals, reminder_rules,             │
/// │  user_preferences                                       │
/// └─────────────────────────────────────────────────────────┘
///
/// All important CRUD goes DIRECTLY to Supabase.
/// SQLite is only for local features (badges, goals, reminders).

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  // ── 1. Singleton Setup ──
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Supabase client shorthand.
  SupabaseClient get _supa => Supabase.instance.client;

  /// Local SQLite database instance getter.
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
    final dbPath = join(dir.path, 'edunova_local.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await _createLocalTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Recreate tables if upgrading from an old schema
          await _createLocalTables(db);
        }
      },
    );
  }

  /// Creates SQLite tables for LOCAL-ONLY data.
  Future<void> _createLocalTables(Database db) async {
    // Achievements Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT, 
        user_id TEXT, 
        title TEXT, 
        description TEXT, 
        icon_name TEXT,
        target_value INTEGER, 
        current_value INTEGER, 
        is_unlocked INTEGER,
        unlocked_at TEXT,
        PRIMARY KEY (id, user_id)
      )
    ''');

    // Study Goals Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        user_id TEXT, 
        title TEXT,
        goal_type TEXT, 
        target_value INTEGER, 
        current_value INTEGER DEFAULT 0,
        start_date TEXT, 
        end_date TEXT, 
        is_completed INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Reminder Rules Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        user_id TEXT, 
        task_id INTEGER,
        reminder_type TEXT, 
        trigger_time TEXT, 
        is_active INTEGER,
        created_at TEXT
      )
    ''');

    // User Preferences Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        user_id TEXT,
        dark_mode INTEGER, 
        notification_enabled INTEGER,
        default_reminder_type TEXT, 
        daily_summary_enabled INTEGER
      )
    ''');
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║           SUPABASE — Cloud database operations           ║
  // ║  For: app_users, study_tasks, study_sessions,            ║
  // ║       pomodoro_records, cgpa_records, subjects           ║
  // ╚══════════════════════════════════════════════════════════╝

  // ═══════════════════════════════════════
  // ── TASKS (Supabase) ──
  // ═══════════════════════════════════════

  /// Inserts a new task and returns the inserted row.
  Future<Map<String, dynamic>> insertTask(Map<String, dynamic> task) async {
    final clean = _cleanForSupabase(task);
    final result = await _supa
        .from('study_tasks')
        .insert(clean)
        .select()
        .single();
    return result;
  }

  /// Retrieves all tasks for a specific user, ordered by deadline.
  Future<List<Map<String, dynamic>>> getTasksByUser(String userId) async {
    return await _supa
        .from('study_tasks')
        .select()
        .eq('user_id', userId)
        .order('deadline', ascending: true);
  }

  /// Deletes a task by its ID.
  Future<void> deleteTask(int id) async {
    await _supa
        .from('study_tasks')
        .delete()
        .eq('id', id);
  }

  /// Updates an existing task by its ID.
  Future<void> updateTask(int id, Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    clean.remove('id'); // Prevent updating the primary key
    await _supa
        .from('study_tasks')
        .update(clean)
        .eq('id', id);
  }

  /// Uploads a proof photo to Supabase Storage and updates the task status.
  Future<void> uploadProofAndUpdateTask(File photoFile, int taskId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileExtension = path.extension(photoFile.path);
      final fileName = 'task_${taskId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // 1. Upload the file to the bucket
      await supabase.storage
          .from('task_proofs')
          .upload(fileName, photoFile);

      // 2. Retrieve the public URL for the uploaded photo
      final String photoUrl = supabase.storage
          .from('task_proofs')
          .getPublicUrl(fileName);

      // 3. Update the task record in the database
      await supabase.from('study_tasks').update({
        'is_completed': 1,
        'proof_photo_path': photoUrl,
      }).eq('id', taskId);

      debugPrint('Photo uploaded and task updated successfully!');
    } catch (e) {
      debugPrint('Upload failed: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════
  // ── SESSIONS (Supabase) ──
  // ═══════════════════════════════════════

  /// Inserts a new study session and returns the inserted row.
  Future<Map<String, dynamic>> insertSession(Map<String, dynamic> session) async {
    final clean = _cleanForSupabase(session);
    final result = await _supa
        .from('study_sessions')
        .insert(clean)
        .select()
        .single();
    return result;
  }

  /// Retrieves all sessions for a specific user, newest first.
  Future<List<Map<String, dynamic>>> getSessionsByUser(String userId) async {
    return await _supa
        .from('study_sessions')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);
  }

  /// Deletes a session by its ID.
  Future<void> deleteSession(int id) async {
    await _supa
        .from('study_sessions')
        .delete()
        .eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── POMODORO (Supabase) ──
  // ═══════════════════════════════════════

  /// Inserts a new pomodoro record and returns the row.
  Future<Map<String, dynamic>> insertPomodoroRecord(Map<String, dynamic> record) async {
    final clean = _cleanForSupabase(record);
    final result = await _supa
        .from('pomodoro_records')
        .insert(clean)
        .select()
        .single();
    return result;
  }

  /// Retrieves all pomodoro records for a specific user.
  Future<List<Map<String, dynamic>>> getPomodorosByUser(String userId) async {
    try {
      return await _supa
          .from('pomodoro_records')
          .select()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint("Supabase Pomodoro Error: $e");
      return [];
    }
  }

  // ═══════════════════════════════════════
  // ── USER PROFILE (Supabase) ──
  // ═══════════════════════════════════════

  /// Retrieves user profile by ID. Returns null if not found.
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    return await _supa
        .from('app_users')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  /// Updates user profile fields safely.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final clean = Map<String, dynamic>.from(data);
    clean.remove('id');            // Prevent updating PK
    clean.remove('password_hash'); // Prevent accidental password overwrite

    // Convert SQLite integer booleans to Supabase native booleans
    if (clean.containsKey('dark_mode')) {
      clean['dark_mode'] = clean['dark_mode'] == 1 || clean['dark_mode'] == true;
    }

    await _supa
        .from('app_users')
        .update(clean)
        .eq('id', userId);
  }

  // ═══════════════════════════════════════
  // ── CGPA RECORDS (Supabase) ──
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> insertCgpaRecord(Map<String, dynamic> record) async {
    final clean = _cleanForSupabase(record);
    final result = await _supa
        .from('cgpa_records')
        .insert(clean)
        .select()
        .single();
    return result;
  }

  Future<List<Map<String, dynamic>>> getCgpaRecordsByUser(String userId) async {
    try {
      return await _supa
          .from('cgpa_records')
          .select()
          .eq('user_id', userId)
          .order('year', ascending: true)
          .order('semester', ascending: true);
    } catch (e) {
      debugPrint("Supabase CGPA Error: $e");
      return [];
    }
  }

  Future<void> updateCgpaRecord(int id, Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    clean.remove('id');
    await _supa
        .from('cgpa_records')
        .update(clean)
        .eq('id', id);
  }

  Future<void> deleteCgpaRecord(int id) async {
    await _supa
        .from('cgpa_records')
        .delete()
        .eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── SUBJECTS (Supabase) ──
  // ═══════════════════════════════════════

  Future<List<Map<String, dynamic>>> getSubjectsByUser(String userId) async {
    return await _supa
        .from('subjects')
        .select()
        .eq('user_id', userId)
        .order('code', ascending: true);
  }

  Future<void> insertSubject(Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    await _supa
        .from('subjects')
        .insert(clean);
  }

  Future<void> updateSubject(int id, Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    clean.remove('id');
    await _supa
        .from('subjects')
        .update(clean)
        .eq('id', id);
  }

  Future<void> deleteSubject(int id) async {
    await _supa
        .from('subjects')
        .delete()
        .eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── SEARCH (Supabase) ──
  // ═══════════════════════════════════════

  /// Performs a global text search across tasks.
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

  Future<List<Map<String, dynamic>>> getStudyLocations(String userId) async {
    return await _supa
        .from('study_locations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> insertStudyLocation(Map<String, dynamic> data) async {
    final clean = _cleanForSupabase(data);
    await _supa
        .from('study_locations')
        .insert(clean);
  }

  Future<void> deleteStudyLocation(int id) async {
    await _supa
        .from('study_locations')
        .delete()
        .eq('id', id);
  }

  // ═══════════════════════════════════════
  // ── LEADERBOARD (Supabase View) ──
  // ═══════════════════════════════════════

  /// Fetches the top 10 students based on focus time via a SQL View.
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      return await _supa
          .from('leaderboard_view')
          .select()
          .limit(10);
    } catch (e) {
      debugPrint("Leaderboard Error: $e");
      return [];
    }
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║           SQLITE — Local-only operations                 ║
  // ║  For: achievements, study_goals, reminder_rules,         ║
  // ║       user_preferences                                   ║
  // ╚══════════════════════════════════════════════════════════╝

  // ── REMINDERS (SQLite) ──

  Future<int> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    return await db.insert('reminder_rules', reminder);
  }

  Future<List<Map<String, dynamic>>> getRemindersByUser(String userId) async {
    final db = await database;
    return await db.query(
      'reminder_rules',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'trigger_time ASC',
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      'reminder_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── ACHIEVEMENTS (SQLite) ──

  Future<List<Map<String, dynamic>>> getAchievementsByUser(String userId) async {
    final db = await database;
    return await db.query(
      'achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> upsertAchievement(String userId, Map<String, dynamic> data) async {
    final db = await database;
    data['user_id'] = userId;
    await db.insert(
      'achievements',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── GOALS (SQLite) ──

  Future<int> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;
    return await db.insert('study_goals', goal);
  }

  Future<List<Map<String, dynamic>>> getGoalsByUser(String userId) async {
    final db = await database;
    return await db.query(
      'study_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> updateGoalProgress(int id, int currentValue, {bool? isCompleted}) async {
    final db = await database;
    final data = <String, dynamic>{'current_value': currentValue};

    if (isCompleted != null) {
      data['is_completed'] = isCompleted ? 1 : 0;
    }

    await db.update(
      'study_goals',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      'study_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── PREFERENCES (SQLite) ──

  Future<int> insertUserPreference(Map<String, dynamic> pref) async {
    final db = await database;
    return await db.insert(
      'user_preferences',
      pref,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserPreference(String userId) async {
    final db = await database;
    final result = await db.query(
      'user_preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║           HELPER — Clean data before sending             ║
  // ╚══════════════════════════════════════════════════════════╝

  /// Removes fields that Supabase auto-generates or doesn't need.
  Map<String, dynamic> _cleanForSupabase(Map<String, dynamic> data) {
    final clean = Map<String, dynamic>.from(data);
    clean.remove('id');       // Supabase auto-generates bigint IDs
    clean.remove('local_id'); // Legacy local SQLite reference, safely drop
    return clean;
  }
}