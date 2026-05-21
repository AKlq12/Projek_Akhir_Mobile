import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';

class SQLiteService {
  SQLiteService._();
  static final SQLiteService instance = SQLiteService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitpro_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE feedback (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        suggestion TEXT NOT NULL,
        impression TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        full_name TEXT NOT NULL,
        avatar_url TEXT,
        date_of_birth TEXT,
        gender TEXT,
        height_cm REAL,
        weight_kg REAL,
        fitness_goal TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER METHODS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toSQLiteJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FEEDBACK METHODS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> insertFeedback(FeedbackModel feedback) async {
    final db = await database;
    await db.insert(
      'feedback',
      feedback.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FeedbackModel>> getFeedback(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'feedback',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return FeedbackModel.fromJson(maps[i]);
    });
  }
}
