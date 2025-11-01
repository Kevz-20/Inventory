import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance (only one DatabaseHelper throughout the app)
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Database reference
  static Database? _database;

  // Private constructor
  DatabaseHelper._init();

  // Getter to access the database, initializes it if not yet opened
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  // Initializes the database and sets its path
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); // Gets default database directory
    final path = join(dbPath, filePath); // Combines directory and filename
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Creates the database tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');
  }

  // Closes the database connection
  Future close() async {
    final db = await database;
    db.close();
  }
}
