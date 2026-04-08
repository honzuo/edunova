import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'edunova.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // USER
    await db.execute('''
      CREATE TABLE app_users (
        id TEXT PRIMARY KEY,
        email TEXT,
        full_name TEXT,
        age INTEGER,
        gender TEXT,
        institution TEXT,
        course TEXT,
        study_goal TEXT,
        created_at TEXT
      )
    ''');

    // TASK
    await db.execute('''
      CREATE TABLE study_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        title TEXT,
        description TEXT,
        subject TEXT,
        deadline TEXT,
        priority TEXT,
        is_completed INTEGER,
        created_at TEXT
      )
    ''');

    // SESSION
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        task_id INTEGER,
        title TEXT,
        subject TEXT,
        start_time TEXT,
        end_time TEXT,
        duration_minutes INTEGER,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // REMINDER
    await db.execute('''
      CREATE TABLE reminder_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        task_id INTEGER,
        reminder_type TEXT,
        trigger_time TEXT,
        is_active INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pomodoro_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        start_time TEXT,
        end_time TEXT,
        focus_minutes INTEGER,
        break_minutes INTEGER,
        completed INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        dark_mode INTEGER,
        notification_enabled INTEGER,
        default_reminder_type TEXT,
        daily_summary_enabled INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
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

    await db.execute('''
      CREATE TABLE study_goals (
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
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('study_tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasksByUser(String userId) async {
    final db = await database;
    return await db.query(
      'study_tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'study_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTask(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'study_tasks',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    return await db.insert('study_sessions', session);
  }

  Future<List<Map<String, dynamic>>> getSessionsByUser(String userId) async {
    final db = await database;
    return await db.query(
      'study_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'study_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<List<Map<String, dynamic>>> getRemindersByTask(int taskId) async {
    final db = await database;
    return await db.query(
      'reminder_rules',
      where: 'task_id = ?',
      whereArgs: [taskId],
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

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'app_users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final db = await database;
    final result = await db.query(
      'app_users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<int> updateUser(String userId, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'app_users',
      user,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> insertPomodoroRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('pomodoro_records', record);
  }

  Future<int> insertUserPreference(Map<String, dynamic> preference) async {
    final db = await database;
    return await db.insert(
      'user_preferences',
      preference,
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

  Future<int> updateUserPreference(
      String userId,
      Map<String, dynamic> preference,
      ) async {
    final db = await database;
    return await db.update(
      'user_preferences',
      preference,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ── Achievements ──

  Future<List<Map<String, dynamic>>> getAchievementsByUser(
      String userId) async {
    final db = await database;
    return await db.query(
      'achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> upsertAchievement(
      String userId, Map<String, dynamic> data) async {
    final db = await database;
    data['user_id'] = userId;
    await db.insert(
      'achievements',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Goals ──

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

  // ── Pomodoro query ──

  Future<List<Map<String, dynamic>>> getPomodorosByUser(
      String userId) async {
    final db = await database;
    return await db.query(
      'pomodoro_records',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ── Search helper ──

  Future<List<Map<String, dynamic>>> searchTasks(
      String userId, String query) async {
    final db = await database;
    return await db.query(
      'study_tasks',
      where:
          "user_id = ? AND (title LIKE ? OR subject LIKE ? OR description LIKE ?)",
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
    );
  }
}