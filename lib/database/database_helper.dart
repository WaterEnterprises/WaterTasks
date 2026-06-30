import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_list_model.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'water_tasks.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE task_lists ADD COLUMN check_in_interval_seconds INTEGER NOT NULL DEFAULT 120',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE sessions ADD COLUMN last_check_in_time TEXT',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE task_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL DEFAULT 0,
        check_in_interval_seconds INTEGER NOT NULL DEFAULT 120,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (list_id) REFERENCES task_lists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER DEFAULT 0,
        check_in_count INTEGER DEFAULT 0,
        last_check_in_time TEXT,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Task Lists ---

  Future<List<TaskListModel>> getTaskLists() async {
    final db = await database;
    final maps = await db.query('task_lists', orderBy: 'created_at DESC');
    return maps.map((map) => TaskListModel.fromMap(map)).toList();
  }

  Future<int> insertTaskList(TaskListModel taskList) async {
    final db = await database;
    return await db.insert('task_lists', taskList.toMap());
  }

  Future<int> updateTaskList(TaskListModel taskList) async {
    final db = await database;
    return await db.update(
      'task_lists',
      taskList.toMap(),
      where: 'id = ?',
      whereArgs: [taskList.id],
    );
  }

  Future<int> deleteTaskList(int id) async {
    final db = await database;
    return await db.delete('task_lists', where: 'id = ?', whereArgs: [id]);
  }

  // --- Tasks ---

  Future<List<TaskModel>> getTasks(int listId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'created_at DESC');
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Sessions ---

  Future<List<SessionModel>> getSessions(int taskId) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => SessionModel.fromMap(map)).toList();
  }

  Future<List<SessionModel>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'start_time DESC');
    return maps.map((map) => SessionModel.fromMap(map)).toList();
  }

  Future<SessionModel?> getActiveSession() async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'end_time IS NULL',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SessionModel.fromMap(maps.first);
  }

  Future<int> insertSession(SessionModel session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<int> updateSession(SessionModel session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Statistics ---

  Future<int> getTotalCompletedTasks() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE completed_at IS NOT NULL',
    );
    return result.first['count'] as int;
  }

  Future<int> getTotalFocusSeconds() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_seconds), 0) as total FROM sessions',
    );
    return result.first['total'] as int;
  }

  Future<int> getTotalSessions() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sessions WHERE end_time IS NOT NULL',
    );
    return result.first['count'] as int;
  }

  Future<int> getTodayFocusSeconds() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_seconds), 0) as total FROM sessions WHERE start_time >= ?',
      [startOfDay.toIso8601String()],
    );
    return result.first['total'] as int;
  }

  Future<List<Map<String, dynamic>>> getFocusByDay(int days) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return await db.rawQuery('''
      SELECT DATE(start_time) as day, COALESCE(SUM(duration_seconds), 0) as total_seconds
      FROM sessions
      WHERE start_time >= ?
      GROUP BY DATE(start_time)
      ORDER BY day ASC
    ''', [cutoff.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> getTaskCompletionByList() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT tl.name, tl.color, COUNT(t.id) as total,
        SUM(CASE WHEN t.completed_at IS NOT NULL THEN 1 ELSE 0 END) as completed
      FROM task_lists tl
      LEFT JOIN tasks t ON t.list_id = tl.id
      GROUP BY tl.id
      ORDER BY tl.name ASC
    ''');
  }

  Future<Map<int, int>> getStreaks() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DATE(sessions.start_time) as day
      FROM sessions
      WHERE sessions.end_time IS NOT NULL
      GROUP BY DATE(sessions.start_time)
      ORDER BY day DESC
    ''');
    final days = result
        .map((r) => DateTime.parse(r['day'] as String))
        .toList();
    return _calculateStreaks(days);
  }

  Map<int, int> _calculateStreaks(List<DateTime> days) {
    if (days.isEmpty) return {1: 0};
    final unique = days.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    int current = 0;
    int longest = 0;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    for (int i = 0; i < unique.length; i++) {
      if (i == 0) {
        current = 1;
      } else {
        final diff = unique[i - 1].difference(unique[i]).inDays;
        if (diff == 1) {
          current++;
        } else {
          break;
        }
      }
      if (current > longest) longest = current;
    }
    if (unique.isNotEmpty && unique.first != todayStart &&
        unique.first != todayStart.subtract(const Duration(days: 1))) {
      current = 0;
    }
    return {1: current, 2: longest};
  }
}
