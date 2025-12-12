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
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON'); // enable Foreign Key
      },
    );
  }

  // Create all tables
  Future<void> _createDB(Database db, int version) async {
    // Account table
    await db.execute('''
      CREATE TABLE account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mobile_number TEXT UNIQUE NOT NULL,
        association_name TEXT,
        pin TEXT NOT NULL,
        security_question_id INTEGER,
        security_answer TEXT
      )
    ''');

    // Enum / choice tables
    await db.execute('''
      CREATE TABLE transaction_type_choices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE credit_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE type_choices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE source_choices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE category_choices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE security_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL
      )
    ''');

    // Capital Management
    await db.execute('''
      CREATE TABLE capital_management (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        cash_on_hand REAL,
        capital REAL,
        bank_cash REAL,
        remarks TEXT,
        created_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account(id)
      )
    ''');

    // Customer
    await db.execute('''
      CREATE TABLE customer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT,
        middle_name TEXT,
        last_name TEXT,
        address TEXT,
        phone_number INTEGER,
        credit_limit REAL
      )
    ''');

    // Product
    await db.execute('''
      CREATE TABLE product (
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

    // Capital transaction
    await db.execute('''
      CREATE TABLE capital_transaction (
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

    // Sale
    await db.execute('''
      CREATE TABLE sale (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        selling_price REAL,
        sale_type TEXT,
        customer_id INTEGER,
        account_id INTEGER,
        created_at TEXT,
        FOREIGN KEY (product_id) REFERENCES product (id),
        FOREIGN KEY (customer_id) REFERENCES customer (id),
        FOREIGN KEY (account_id) REFERENCES account (id)
      )
    ''');

    // Transaction History (Universal Ledger)
    await db.execute('''
      CREATE TABLE transaction_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        account_id INTEGER,
        type TEXT NOT NULL,

        product_id INTEGER,
        sale_id INTEGER,
        expense_id INTEGER,
        capital_transaction_id INTEGER,

        amount REAL,
        quantity INTEGER,
        description TEXT,

        created_at TEXT NOT NULL,

        FOREIGN KEY (account_id) REFERENCES account(id),
        FOREIGN KEY (product_id) REFERENCES product(id),
        FOREIGN KEY (sale_id) REFERENCES sale(id),
        FOREIGN KEY (expense_id) REFERENCES expenses(id),
        FOREIGN KEY (capital_transaction_id) REFERENCES capital_transaction(id)
      )
    ''');

    // Sales credit payment
    await db.execute('''
      CREATE TABLE sales_credit_payment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        customer_id INTEGER,
        amount REAL,
        paid_at TEXT,
        remarks TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id),
        FOREIGN KEY (customer_id) REFERENCES customer (id)
      )
    ''');

    // Fixed asset
    await db.execute('''
      CREATE TABLE fixed_asset (
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
        sale_id INTEGER,
        stock_in_id INTEGER,
        quantity INTEGER,
        unit_price REAL,
        FOREIGN KEY (sale_id) REFERENCES sale (id),
        FOREIGN KEY (stock_in_id) REFERENCES stock_in (id)
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
        sale_id INTEGER,
        product_id INTEGER,
        amount REAL,
        quantity INTEGER,
        date TEXT,
        created_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account (id),
        FOREIGN KEY (sale_id) REFERENCES sale (id),
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
        FOREIGN KEY (sale_id) REFERENCES sale (id),
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
        create_at TEXT,
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

    await db.insert('transaction_type_choices', {
      'name': 'Deposit',
      'value': 'deposit',
    });
    await db.insert('transaction_type_choices', {
      'name': 'Withdraw',
      'value': 'withdraw',
    });

    await db.insert('credit_status', {'name': 'unpaid', 'code': 0});
    await db.insert('credit_status', {'name': 'partial', 'code': 1});
    await db.insert('credit_status', {'name': 'paid', 'code': 2});

    const typeChoices = [
      'capital_deposit',
      'transfer_cash_out',
      'transfer_bank_in',
    ];
    for (final t in typeChoices) {
      await db.insert('type_choices', {'name': t});
    }

    const sourceChoices = ['cash', 'bank', 'capital'];
    for (final s in sourceChoices) {
      await db.insert('source_choices', {'name': s});
    }

    const categoryChoices = [
      'inventory_purchase',
      'rent',
      'utilities',
      'other',
    ];
    for (final c in categoryChoices) {
      await db.insert('category_choices', {'name': c});
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
