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
      version: 10,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        Future<void> addColumnIfMissing(
          String table,
          String column,
          String definition,
        ) async {
          final cols = await db.rawQuery('PRAGMA table_info($table)');
          final exists = cols.any((c) => c['name'] == column);
          if (!exists) {
            await db.execute(
              'ALTER TABLE $table ADD COLUMN $column $definition',
            );
          }
        }

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

        if (oldVersion < 6) {
          await addColumnIfMissing('customer_payment', 'account_id', 'INTEGER');
          await addColumnIfMissing(
            'customer_payment',
            'created_by_first_name',
            'TEXT',
          );
          await addColumnIfMissing(
            'customer_payment',
            'created_by_middle_name',
            'TEXT',
          );
          await addColumnIfMissing(
            'customer_payment',
            'created_by_last_name',
            'TEXT',
          );
        }

        if (oldVersion < 7) {
          await addColumnIfMissing(
            'owner_installments',
            'created_by_first_name',
            'TEXT',
          );
          await addColumnIfMissing(
            'owner_installments',
            'created_by_middle_name',
            'TEXT',
          );
          await addColumnIfMissing(
            'owner_installments',
            'created_by_last_name',
            'TEXT',
          );
        }

        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS product_category (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL
            )
          ''');

          await addColumnIfMissing('product', 'category_id', 'INTEGER');

          const defaultCats = [
            'Imnonon',
            'Alak',
            'Pagkaon',
            'Panglimpyo',
            'Gamit sa Panimalay',
            'Gamit sa Eskwelahan',
          ];

          for (final c in defaultCats) {
            await db.rawInsert(
              'INSERT OR IGNORE INTO product_category(name, created_at) VALUES(?, ?)',
              [c, DateTime.now().toIso8601String()],
            );
          }
        }

        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expense_category (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL
            )
          ''');

          const defaultExpenseCats = [
            'Kumpra',
            'Tubig / Kuryente',
            'Transportasyon',
          ];

          for (final c in defaultExpenseCats) {
            await db.rawInsert(
              'INSERT OR IGNORE INTO expense_category(name, created_at) VALUES(?, ?)',
              [c, DateTime.now().toIso8601String()],
            );
          }
        }

        if (oldVersion < 10) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notif_state (
            notif_id TEXT PRIMARY KEY,
            seen INTEGER NOT NULL DEFAULT 0,
            seen_at TEXT
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
    // Account table
    await db.execute('''
      CREATE TABLE account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        middle_name TEXT,
        last_name TEXT,
        mobile_number TEXT UNIQUE NOT NULL,
        pin TEXT NOT NULL,
        security_question_id INTEGER,
        security_answer TEXT,
        profile_image TEXT,
        UNIQUE(first_name, middle_name, last_name)
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
    CREATE TABLE product_category (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
  CREATE TABLE expense_category (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL
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
  CREATE TABLE notif_state (
    notif_id TEXT PRIMARY KEY,
    seen INTEGER NOT NULL DEFAULT 0,
    seen_at TEXT
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
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
        FOREIGN KEY (account_id) REFERENCES account(id)

      )
    ''');

    // Customer
    await db.execute('''
      CREATE TABLE customer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        middle_name TEXT,
        last_name TEXT NOT NULL,
        phone_number TEXT NOT NULL UNIQUE,
        municipality TEXT NOT NULL,
        barangay TEXT,
        landmark TEXT,
        credit_limit REAL DEFAULT 1000,
        available_credit REAL DEFAULT 1000,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(first_name, middle_name, last_name, municipality)
      )
    ''');

    // Product
    await db.execute('''
      CREATE TABLE product (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        category_id INTEGER,
        purchase_price REAL,
        selling_price REAL,
        quantity INTEGER,
        image TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES product_category(id)
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

    // Sales
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        sale_type TEXT NOT NULL,
        total INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
        FOREIGN KEY (customer_id) REFERENCES customer(id)
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
        FOREIGN KEY (sale_id) REFERENCES sales(id),
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_payment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        account_id INTEGER,
        amount REAL NOT NULL,
        paid_at TEXT NOT NULL,
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
        FOREIGN KEY (account_id) REFERENCES account(id),
        FOREIGN KEY (customer_id) REFERENCES customer(id)
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
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        created_by_first_name TEXT,   -- new
        created_by_middle_name TEXT,  -- new
        created_by_last_name TEXT,    -- new
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
          product_id INTEGER,
          amount REAL,
          quantity INTEGER,
          date TEXT,
          created_at TEXT,
          created_by_first_name TEXT,
          created_by_middle_name TEXT,
          created_by_last_name TEXT,
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
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
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
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
        created_at TEXT,
        updated_at TEXT
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
        amount REAL,
        category TEXT,
        description TEXT,
        receipt TEXT,
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
        created_at TEXT
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
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES account(id)
      )
    ''');

    // Insert predefined data
    await _insertDefaultData(db);

    // // for testing
    // const bool seedProducts = true; // set to false to disable seeding
    // if (seedProducts) await _seedProducts(db);
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
    const defaultProductCats = [
      'Imnonon',
      'Alak',
      'Pagkaon',
      'Panglimpyo',
      'Gamit sa Panimalay',
      'Gamit sa Eskwelahan',
    ];

    const defaultExpenseCats = [
        'Kumpra',
        'Tubig / Kuryente',
        'Transportasyon',
      ];

      for (final c in defaultExpenseCats) {
        await db.rawInsert(
          'INSERT OR IGNORE INTO expense_category(name, created_at) VALUES(?, ?)',
          [c, DateTime.now().toIso8601String()],
        );
      }

    for (final c in defaultProductCats) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO product_category(name, created_at) VALUES(?, ?)',
        [c, DateTime.now().toIso8601String()],
      );
    }

  }

  // for testing
  // Future<void> _seedProducts(Database db) async {
  //   final count = Sqflite.firstIntValue(
  //     await db.rawQuery('SELECT COUNT(*) FROM product'),
  //   );

  //   if (count == 0) {
  //     for (final product in productSeeds) {
  //       await db.insert('product', product.toMap());
  //     }
  //   }
  // }

  Future<void> clearData() async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete from child tables first to respect foreign keys
      final tablesToClear = [
        'transaction_history',
        'sales_credit_payment',
        'customer_payment',
        'sales_cash',
        'sales_credit',
        'sale_item',
        'sales',
        'capital_transaction',
        'bank_transaction',
        'payable_payment',
        'payable',
        'owner_installments',
        'fixed_asset',
        'stock_in',
        'balance_assets',
        'expenses',
        'capital_management',
        'customer',
        'product',
      ];

      for (final table in tablesToClear) {
        await txn.delete(table);
      }

      // Optionally reset AUTOINCREMENT counters
      for (final table in tablesToClear) {
        await txn.execute('DELETE FROM sqlite_sequence WHERE name="$table"');
      }
    });
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
