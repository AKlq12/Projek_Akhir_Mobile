import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/feedback_model.dart';

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
  }

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
