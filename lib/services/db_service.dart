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
      version: 5,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          // your existing upgrade logic...
        }

        if (oldVersion < 5) {
          // Rename create_at -> created_at in payable
          await db.execute('''
      CREATE TABLE IF NOT EXISTS payable_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        supplier_name TEXT,
        item TEXT,
        original_amount REAL,
        remaining_amount REAL,
        due_date TEXT,
        note TEXT,
        is_paid INTEGER,
        has_plan INTEGER,
        plan_months INTEGER,
        plan_monthly REAL,
        first_due_date TEXT,
        next_due_date TEXT,
        is_asset INTEGER,
        asset_category TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id)
      )
    ''');

          // Copy data from old table
          await db.execute('''
      INSERT INTO payable_new (
        id, account_id, supplier_name, item, original_amount, remaining_amount,
        due_date, note, is_paid, has_plan, plan_months, plan_monthly,
        first_due_date, next_due_date, is_asset, asset_category, created_at, updated_at
      )
      SELECT
        id, account_id, supplier_name, item, original_amount, remaining_amount,
        due_date, note, is_paid, has_plan, plan_months, plan_monthly,
        first_due_date, next_due_date, is_asset, asset_category, create_at, updated_at
      FROM payable;
    ''');

          await db.execute('DROP TABLE payable;');
          await db.execute('ALTER TABLE payable_new RENAME TO payable;');
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
        account_id INTEGER,
        name TEXT,
        category TEXT,
        cost REAL,
        date_acquired TEXT,
        accumulated_depreciation REAL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id)
      )
    ''');

    // Stock in
    await db.execute('''
      CREATE TABLE stock_in ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        product_id INTEGER,
        quantity INTEGER,
        purchase_price REAL,
        markup_rate REAL,
        image TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id),
        FOREIGN KEY (product_id) REFERENCES product (id)
      )
    ''');

    // Sale item
    await db.execute('''
      CREATE TABLE sale_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id),
        FOREIGN KEY (product_id) REFERENCES product(id)
      )
    ''');

    // Bank transaction
    await db.execute('''

      CREATE TABLE bank_transaction (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        amount REAL,
        transaction_type_id INTEGER,
        remarks TEXT,
        date TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id),
        FOREIGN KEY (transaction_type_id) REFERENCES transaction_type_choices (id)
      )
    ''');

    // Sales cash
    await db.execute('''
      CREATE TABLE sales_cash (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        product_id INTEGER,
        amount REAL,
        quantity INTEGER,
        date TEXT,
        created_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id),
        FOREIGN KEY (product_id) REFERENCES product (id)
      )
    ''');

    // Sales credit
    await db.execute('''
      CREATE TABLE sales_credit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        sale_id INTEGER,
        product_id INTEGER,
        customer_id INTEGER,
        amount REAL,
        quantity INTEGER,
        status_id INTEGER,
        credit_date TEXT,
        paid_date TEXT,
        due_date TEXT,
        created_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id),
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES product (id),
        FOREIGN KEY (customer_id) REFERENCES customer (id),
        FOREIGN KEY (status_id) REFERENCES credit_status (id)
      )
    ''');

    // Payable
    await db.execute('''
      CREATE TABLE payable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        supplier_name TEXT,
        item TEXT,
        original_amount REAL,
        remaining_amount REAL,
        due_date TEXT,
        note TEXT,
        is_paid INTEGER,
        has_plan INTEGER,
        plan_months INTEGER,
        plan_monthly REAL,
        first_due_date TEXT,
        next_due_date TEXT,
        is_asset INTEGER,
        asset_category TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id)
      )
    ''');

    // Payable payment
    await db.execute('''
      CREATE TABLE payable_payment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payable_id INTEGER,
        amount REAL,
        date TEXT,
        note TEXT,
        idempotency_key TEXT,
        created_at TEXT,
        FOREIGN KEY (payable_id) REFERENCES payable (id)
      )
    ''');

    // Balance assets
    await db.execute('''
      CREATE TABLE balance_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        cash_on_hand REAL,
        cash_in_bank REAL,
        accounts_receivable REAL,
        inventory REAL,
        fixed_assets REAL,
        FOREIGN KEY (account_id) REFERENCES account (id)
      )
    ''');

    // Expenses
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        amount REAL,
        category TEXT,
        description TEXT,
        receipt TEXT,
        created_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE owner_installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        item TEXT NOT NULL,          -- e.g., "Freezer"
        downpayment REAL NOT NULL,   -- DP amount
        total_amount REAL,           -- full installment price
        installment_months INTEGER,  -- optional
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES account(id)
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
