import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/utang_customer_model.dart';

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
      version: 18,
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

        Future<void> addSyncColumns(
          String table, {
          bool includeUpdatedAt = true,
          bool includeSoftDelete = true,
        }) async {
          await addColumnIfMissing(table, 'server_id', 'TEXT');
          await addColumnIfMissing(
            table,
            'sync_status',
            "TEXT NOT NULL DEFAULT 'pending'",
          );
          await addColumnIfMissing(table, 'last_synced_at', 'TEXT');
          if (includeUpdatedAt) {
            await addColumnIfMissing(table, 'updated_at', 'TEXT');
          }
          if (includeSoftDelete) {
            await addColumnIfMissing(
              table,
              'is_deleted',
              'INTEGER NOT NULL DEFAULT 0',
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
            seen_at TEXT,
            created_at TEXT
          )
        ''');
        }

        if (oldVersion < 11) {
          await addColumnIfMissing('notif_state', 'created_at', 'TEXT');
        }

        if (oldVersion < 12) {
          // Add 'Uban Pa' in case it's missing
          await db.rawInsert(
            'INSERT OR IGNORE INTO product_category(name, created_at) VALUES(?, ?)',
            ['Uban Pa', DateTime.now().toIso8601String()],
          );

        }

        if (oldVersion < 13) {
          await addColumnIfMissing('account', 'slpa_name', 'TEXT');
          await db.execute('''
            UPDATE account
            SET slpa_name = TRIM(
              COALESCE(first_name, '') ||
              CASE
                WHEN middle_name IS NOT NULL AND TRIM(middle_name) <> '' THEN ' ' || middle_name
                ELSE ''
              END ||
              CASE
                WHEN last_name IS NOT NULL AND TRIM(last_name) <> '' THEN ' ' || last_name
                ELSE ''
              END
            )
            WHERE slpa_name IS NULL OR TRIM(slpa_name) = ''
          ''');
        }

        if (oldVersion < 14) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS slpa_member (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              account_id INTEGER NOT NULL,
              first_name TEXT NOT NULL,
              middle_name TEXT,
              last_name TEXT,
              mobile_number TEXT NOT NULL UNIQUE,
              pin TEXT NOT NULL,
              security_question_id INTEGER,
              security_answer TEXT,
              created_at TEXT,
              updated_at TEXT,
              FOREIGN KEY (account_id) REFERENCES account(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            INSERT OR IGNORE INTO slpa_member (
              account_id,
              first_name,
              middle_name,
              last_name,
              mobile_number,
              pin,
              security_question_id,
              security_answer,
              created_at,
              updated_at
            )
            SELECT
              id,
              COALESCE(NULLIF(first_name, ''), COALESCE(slpa_name, 'Member')),
              middle_name,
              last_name,
              mobile_number,
              pin,
              security_question_id,
              security_answer,
              DATETIME('now'),
              DATETIME('now')
            FROM account
            WHERE mobile_number IS NOT NULL AND TRIM(mobile_number) <> ''
          ''');
        }

        if (oldVersion < 15) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS audit_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              account_id INTEGER,
              member_id INTEGER,
              member_name TEXT,
              module TEXT NOT NULL,
              table_name TEXT,
              record_id TEXT,
              action TEXT NOT NULL,
              old_value TEXT,
              new_value TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (account_id) REFERENCES account(id),
              FOREIGN KEY (member_id) REFERENCES slpa_member(id)
            )
          ''');
        }

        if (oldVersion < 16) {
          await addSyncColumns('account');
          await addSyncColumns('slpa_member');
          await addSyncColumns(
            'audit_log',
            includeUpdatedAt: false,
            includeSoftDelete: false,
          );
          await addSyncColumns('product');
          await addSyncColumns('customer');
          await addSyncColumns('expenses');
          await addSyncColumns('payable');
          await addSyncColumns('capital_management');
          await addSyncColumns('fixed_asset');
          await addSyncColumns('sales', includeUpdatedAt: false);
          await addSyncColumns('stock_in');

          final now = DateTime.now().toIso8601String();
          const syncTables = [
            'account',
            'slpa_member',
            'audit_log',
            'product',
            'customer',
            'expenses',
            'payable',
            'capital_management',
            'fixed_asset',
            'sales',
            'stock_in',
          ];

          for (final table in syncTables) {
            await db.execute(
              "UPDATE $table SET sync_status = COALESCE(NULLIF(sync_status, ''), 'pending')",
            );
          }

          const updatedAtTables = [
            'account',
            'slpa_member',
            'product',
            'customer',
            'expenses',
            'payable',
            'capital_management',
            'fixed_asset',
            'stock_in',
          ];

          for (final table in updatedAtTables) {
            await addColumnIfMissing(table, 'created_at', 'TEXT');
            await db.execute('''
              UPDATE $table
              SET created_at = COALESCE(
                NULLIF(created_at, ''),
                '$now'
              )
            ''');
            await db.execute('''
              UPDATE $table
              SET updated_at = COALESCE(
                NULLIF(updated_at, ''),
                NULLIF(created_at, ''),
                '$now'
              )
            ''');
          }
        }

        if (oldVersion < 17) {
          await addColumnIfMissing(
            'product',
            'base_unit',
            "TEXT NOT NULL DEFAULT 'pcs'",
          );
          await addColumnIfMissing(
            'product',
            'cost_per_unit',
            'REAL NOT NULL DEFAULT 0',
          );
          await addColumnIfMissing(
            'product',
            'price_per_unit',
            'REAL NOT NULL DEFAULT 0',
          );

          await db.execute('''
            UPDATE product
            SET
              base_unit = COALESCE(NULLIF(base_unit, ''), 'pcs'),
              cost_per_unit = CASE
                WHEN COALESCE(cost_per_unit, 0) <= 0 THEN COALESCE(purchase_price, 0)
                ELSE cost_per_unit
              END,
              price_per_unit = CASE
                WHEN COALESCE(price_per_unit, 0) <= 0 THEN COALESCE(selling_price, 0)
                ELSE price_per_unit
              END
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS product_unit_conversion (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              product_id INTEGER NOT NULL,
              unit_name TEXT NOT NULL,
              base_quantity INTEGER NOT NULL,
              created_at TEXT,
              updated_at TEXT,
              UNIQUE(product_id, unit_name),
              FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS product_selling_option (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              product_id INTEGER NOT NULL,
              label TEXT NOT NULL,
              mode TEXT NOT NULL,
              unit_name TEXT,
              base_quantity INTEGER,
              price REAL NOT NULL DEFAULT 0,
              created_at TEXT,
              updated_at TEXT,
              UNIQUE(product_id, label),
              FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 18) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS base_unit_choice (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL
            )
          ''');

          const defaultBaseUnits = [
            'pcs',
            'Piece / pcs',
            'Pack / Sachet',
            'Gram / Kilogram',
            'mL',
          ];

          for (final unit in defaultBaseUnits) {
            await db.rawInsert(
              'INSERT OR IGNORE INTO base_unit_choice(name, created_at) VALUES(?, ?)',
              [unit, DateTime.now().toIso8601String()],
            );
          }
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
        slpa_name TEXT NOT NULL,
        first_name TEXT NOT NULL,
        middle_name TEXT,
        last_name TEXT,
        mobile_number TEXT UNIQUE NOT NULL,
        pin TEXT NOT NULL,
        security_question_id INTEGER,
        security_answer TEXT,
        profile_image TEXT,
        created_at TEXT,
        updated_at TEXT,
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        UNIQUE(first_name, middle_name, last_name)
      )
    ''');

    await db.execute('''
      CREATE TABLE slpa_member (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        first_name TEXT NOT NULL,
        middle_name TEXT,
        last_name TEXT,
        mobile_number TEXT NOT NULL UNIQUE,
        pin TEXT NOT NULL,
        security_question_id INTEGER,
        security_answer TEXT,
        created_at TEXT,
        updated_at TEXT,
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES account(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        member_id INTEGER,
        member_name TEXT,
        module TEXT NOT NULL,
        table_name TEXT,
        record_id TEXT,
        action TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        created_at TEXT NOT NULL,
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        FOREIGN KEY (account_id) REFERENCES account(id),
        FOREIGN KEY (member_id) REFERENCES slpa_member(id)
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
      CREATE TABLE base_unit_choice (
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
    seen_at TEXT,
    created_at TEXT
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
        updated_at TEXT,
        created_by_first_name TEXT,
        created_by_middle_name TEXT,
        created_by_last_name TEXT,
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
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
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
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
        base_unit TEXT NOT NULL DEFAULT 'pcs',
        cost_per_unit REAL NOT NULL DEFAULT 0,
        price_per_unit REAL NOT NULL DEFAULT 0,
        image TEXT,
        created_at TEXT,
        updated_at TEXT,
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
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
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
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
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
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
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES account (id),
        FOREIGN KEY (product_id) REFERENCES product (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE product_unit_conversion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        unit_name TEXT NOT NULL,
        base_quantity INTEGER NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(product_id, unit_name),
        FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE product_selling_option (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        mode TEXT NOT NULL,
        unit_name TEXT,
        base_quantity INTEGER,
        price REAL NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(product_id, label),
        FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE
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
        updated_at TEXT,
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
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
        created_at TEXT,
        updated_at TEXT,
        server_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
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

    const defaultExpenseCats = ['Kumpra', 'Tubig / Kuryente', 'Transportasyon'];

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

    const defaultBaseUnits = [
      'pcs',
      'Piece / pcs',
      'Pack / Sachet',
      'Gram / Kilogram',
      'mL',
    ];

    for (final unit in defaultBaseUnits) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO base_unit_choice(name, created_at) VALUES(?, ?)',
        [unit, DateTime.now().toIso8601String()],
      );
    }
  }

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
        'product_unit_conversion',
        'product_selling_option',
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

  Future<Map<String, dynamic>> fetchUtangReminder() async {
    final db = await database;

    final totalResult = await db.rawQuery('''
    SELECT SUM(sc.amount) AS totalUtang
    FROM sales_credit sc
    WHERE sc.status_id IN (
      SELECT id FROM credit_status WHERE code IN (0, 1)
    )
  ''');
    final totalUtang = totalResult.first['totalUtang'] as double? ?? 0.0;

    final customersResult = await db.rawQuery('''
    SELECT COUNT(DISTINCT customer_id) AS customers 
    FROM sales_credit
    WHERE status_id IN (
      SELECT id FROM credit_status WHERE code IN (0, 1)
    )
  ''');
    final customers = customersResult.first['customers'] as int? ?? 0;

    return {'totalUtang': totalUtang, 'customers': customers};
  }

  Future<List<Map<String, dynamic>>> fetchCustomerUtangList() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT 
      sc.customer_id,
      sc.due_date,
      c.first_name || ' ' || IFNULL(c.middle_name || ' ', '') || c.last_name AS customer_name,
      SUM(sc.amount) AS total_amount
    FROM sales_credit sc
    JOIN customer c ON sc.customer_id = c.id
    WHERE sc.status_id IN (
      SELECT id FROM credit_status WHERE code IN (0, 1)
    )
    GROUP BY sc.customer_id, sc.due_date
    ORDER BY sc.due_date ASC
  ''');

    return result.map((row) {
      return {
        'customer_id': row['customer_id'] as int? ?? 0,
        'customer_name': (row['customer_name'] as String).trim(),
        'total_amount': row['total_amount'] != null
            ? (row['total_amount'] as num).toDouble()
            : 0.0,
        'due_date': row['due_date'] as String? ?? '',
      };
    }).toList();
  }

  Future<UtangCustomer?> fetchUtangCustomerById(int customerId) async {
    final db = await database;

    const sql = '''
    SELECT
      c.id,
      c.first_name,
      c.middle_name,
      c.last_name,
      c.municipality,
      c.barangay,
      c.phone_number,
      COALESCE(sc.total_amount, 0) AS total_amount,
      COALESCE(cp.total_paid, 0) AS total_paid,
      sc.min_due_date AS due_date
    FROM customer c
    LEFT JOIN (
      SELECT
        customer_id,
        SUM(amount) AS total_amount,
        MIN(due_date) AS min_due_date
      FROM sales_credit
      WHERE status_id IN (
        SELECT id FROM credit_status WHERE code IN (0, 1)
      )
      GROUP BY customer_id
    ) sc ON sc.customer_id = c.id
    LEFT JOIN (
      SELECT
        customer_id,
        SUM(amount) AS total_paid
      FROM customer_payment
      GROUP BY customer_id
    ) cp ON cp.customer_id = c.id
    WHERE c.id = ?
    LIMIT 1
    ''';

    final rows = await db.rawQuery(sql, [customerId]);
    if (rows.isEmpty) return null;
    return UtangCustomer.fromMap(rows.first);
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
