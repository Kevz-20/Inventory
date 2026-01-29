import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;
  DBService._init();

  // Singleton database getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_data.db');
    return _database!;
  }

  // Initialize database file
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // increment version for new table
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE customer ADD COLUMN account_id INTEGER;',
          );
          await db.execute(
            'ALTER TABLE customer ADD COLUMN municipality TEXT;',
          );
          await db.execute('ALTER TABLE customer ADD COLUMN barangay TEXT;');
          await db.execute('ALTER TABLE customer ADD COLUMN landmark TEXT;');
        }

        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE sales_credit_payment ADD COLUMN sales_credit_id INTEGER;',
          );
        }

        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE sales_credit_payment ADD COLUMN payment_date TEXT;',
          );
        }

        // NEW: Create customer_payment table if upgrading from older version
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS customer_payment (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              paid_at TEXT NOT NULL,
              FOREIGN KEY (customer_id) REFERENCES customer(id)
            )
          ''');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Create all tables
  Future<void> _createDB(Database db, int version) async {
    // --- Existing tables ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mobile_number TEXT UNIQUE NOT NULL,
        association_name TEXT,
        pin TEXT NOT NULL,
        security_question_id INTEGER,
        security_answer TEXT,
        profile_image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        first_name TEXT NOT NULL,
        middle_name TEXT,
        last_name TEXT,
        phone_number TEXT NOT NULL,
        municipality TEXT,
        barangay TEXT,
        landmark TEXT,
        credit_limit REAL,
        FOREIGN KEY (account_id) REFERENCES account(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        name TEXT,
        category TEXT,
        purchase_price REAL,
        selling_price REAL,
        quantity INTEGER,
        image TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_credit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        customer_id INTEGER,
        product_id INTEGER,
        amount REAL,
        quantity INTEGER,
        credit_date TEXT,
        FOREIGN KEY (account_id) REFERENCES account(id),
        FOREIGN KEY (customer_id) REFERENCES customer(id),
        FOREIGN KEY (product_id) REFERENCES product(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_credit_payment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        customer_id INTEGER,
        amount REAL,
        sales_credit_id INTEGER,
        paid_at TEXT,
        payment_date TEXT,
        remarks TEXT,
        FOREIGN KEY (account_id) REFERENCES account(id),
        FOREIGN KEY (customer_id) REFERENCES customer(id)
      )
    ''');

    // --- NEW: customer_payment table ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_payment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        paid_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer(id)
      )
    ''');

    // Insert predefined data
    await _insertDefaultData(db);
  }

  // Seed initial reference data
  Future<void> _insertDefaultData(Database db) async {
    const securityQuestions = [
      'Unsa ang una nimo negosyo?',
      'Kinsay imong unang silingan o suod nga amigo/amiga sa pagkabata?',
      'Asa nga tindahan o merkado ka una kanunay mamalit ug pagkaon o gamit?',
      'Unsa imong paboritong lugar nga bisitahan?',
      'Unsa ang butang nga kanunay nimo dala kung mag-biyahe ka?',
    ];
    for (final q in securityQuestions) {
      await db.insert('security_questions', {'question': q});
    }
  }

  // Close database safely
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
