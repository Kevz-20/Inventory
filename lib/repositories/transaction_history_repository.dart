import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_history_model.dart';
import '../services/db_service.dart';

class TransactionHistoryRepository {
  final dbService = DBService.instance;

  Future<Map<String, String>> _currentUserNameParts() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    final fullName = (prefs.getString('fullName') ?? '').trim();
    if (mobile == null || mobile.trim().isEmpty) {
      if (fullName.isEmpty) {
        return const {'first': '', 'middle': '', 'last': ''};
      }
      final parts = fullName.split(RegExp(r'\s+'));
      return {
        'first': parts.isNotEmpty ? parts.first : '',
        'middle': parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : '',
        'last': parts.length > 1 ? parts.last : '',
      };
    }

    final db = await dbService.database;
    final rows = await db.query(
      'account',
      columns: ['first_name', 'middle_name', 'last_name'],
      where: 'mobile_number = ?',
      whereArgs: [mobile.trim()],
      limit: 1,
    );

    if (rows.isEmpty) {
      if (fullName.isEmpty) {
        return const {'first': '', 'middle': '', 'last': ''};
      }
      final parts = fullName.split(RegExp(r'\s+'));
      return {
        'first': parts.isNotEmpty ? parts.first : '',
        'middle': parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : '',
        'last': parts.length > 1 ? parts.last : '',
      };
    }

    final row = rows.first;
    return {
      'first': (row['first_name'] ?? '').toString(),
      'middle': (row['middle_name'] ?? '').toString(),
      'last': (row['last_name'] ?? '').toString(),
    };
  }

  List<Map<String, dynamic>> _applyCreatorFallback(
    List<Map<String, dynamic>> rows,
    Map<String, String> fallback,
  ) {
    final first = fallback['first'] ?? '';
    final middle = fallback['middle'] ?? '';
    final last = fallback['last'] ?? '';

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final hasCreator = ((map['created_by_first_name'] ?? '').toString().trim().isNotEmpty) ||
          ((map['created_by_middle_name'] ?? '').toString().trim().isNotEmpty) ||
          ((map['created_by_last_name'] ?? '').toString().trim().isNotEmpty);
      if (!hasCreator) {
        map['created_by_first_name'] = first;
        map['created_by_middle_name'] = middle;
        map['created_by_last_name'] = last;
      }
      return map;
    }).toList();
  }

  /// Load all transaction history without filtering by account
  Future<TransactionHistoryModel> loadHistory() async {
    final db = await dbService.database;
    final currentUserName = await _currentUserNameParts();

    // Expenses (all users)
    final expenses = await db.rawQuery('''
      SELECT 
        e.id,
        e.amount,
        e.description,
        e.created_at,
        e.category,
        e.receipt AS receipt_image_path,
        e.created_by_first_name,
        e.created_by_middle_name,
        e.created_by_last_name
      FROM expenses e
      ORDER BY e.created_at DESC
    ''');

    // Sales Cash (all users)
    final salesCash = await db.rawQuery('''
      SELECT 
        sc.id,
        sc.amount,
        sc.quantity,
        sc.created_at,
        sc.created_by_first_name,
        sc.created_by_middle_name,
        sc.created_by_last_name,
        p.name AS product_name
      FROM sales_cash sc
      JOIN product p ON p.id = sc.product_id
      ORDER BY sc.created_at DESC
    ''');

    // Sales Credit (all users)
    final salesCredit = await db.rawQuery('''
      SELECT 
        sc.id,
        sc.amount,
        sc.quantity,
        sc.created_at,
        sc.created_by_first_name,
        sc.created_by_middle_name,
        sc.created_by_last_name,
        p.name AS product_name
      FROM sales_credit sc
      JOIN product p ON p.id = sc.product_id
      ORDER BY sc.created_at DESC
    ''');

    // Capital Management (all users)
    final capitalManagement = await db.rawQuery('''
      SELECT 
        cm.id,
        cm.capital,
        cm.bank_cash,
        cm.created_at,
        cm.remarks,
        COALESCE(NULLIF(cm.created_by_first_name, ''), a.first_name, '') AS created_by_first_name,
        COALESCE(NULLIF(cm.created_by_middle_name, ''), a.middle_name, '') AS created_by_middle_name,
        COALESCE(NULLIF(cm.created_by_last_name, ''), a.last_name, '') AS created_by_last_name
      FROM capital_management cm
      LEFT JOIN account a ON a.id = cm.account_id
      ORDER BY cm.created_at DESC
    ''');

    // Customer Payments (all customers, all accounts)
    final customerPaymentsRaw = await db.rawQuery('''
      SELECT 
        cp.amount,
        cp.paid_at AS created_at,
        'in' AS direction,
        NULLIF(cp.created_by_first_name, '') AS created_by_first_name,
        NULLIF(cp.created_by_middle_name, '') AS created_by_middle_name,
        NULLIF(cp.created_by_last_name, '') AS created_by_last_name,
        TRIM(
          COALESCE(c.first_name, '') || ' ' ||
          COALESCE(c.middle_name, '') || ' ' ||
          COALESCE(c.last_name, '')
        ) AS description
      FROM customer_payment cp
      JOIN customer c ON c.id = cp.customer_id
      ORDER BY cp.paid_at DESC
    ''');
    final customerPayments = _applyCreatorFallback(
      customerPaymentsRaw,
      currentUserName,
    );

    // Utang Payments (payable payments)
    final utangPaymentsRaw = await db.rawQuery('''
      SELECT 
        pp.amount,
        pp.date AS created_at,
        'out' AS direction,
        COALESCE(p.item, '') AS description
      FROM payable_payment pp
      JOIN payable p ON p.id = pp.payable_id
      ORDER BY pp.date DESC
    ''');
    final utangPayments = _applyCreatorFallback(utangPaymentsRaw, currentUserName);

    // Owner Payments (owner installments/downpayments)
    final ownerPaymentsRaw = await db.rawQuery('''
      SELECT
        oi.downpayment AS amount,
        oi.created_at AS created_at,
        'Downpayment' AS type,
        'out' AS direction,
        NULLIF(oi.created_by_first_name, '') AS created_by_first_name,
        NULLIF(oi.created_by_middle_name, '') AS created_by_middle_name,
        NULLIF(oi.created_by_last_name, '') AS created_by_last_name,
        COALESCE(oi.item, '') AS description
      FROM owner_installments oi
      ORDER BY oi.created_at DESC
    ''');
    final ownerPayments = _applyCreatorFallback(ownerPaymentsRaw, currentUserName);

    return TransactionHistoryModel(
      expenses: expenses,
      salesCash: salesCash,
      salesCredit: salesCredit,
      capitalManagement: capitalManagement,
      customerPayments: customerPayments,
      utangPayments: utangPayments,
      ownerPayments: ownerPayments,
    );
  }

  /// Pagination for any table without filtering by account
  Future<List<Map<String, dynamic>>> getTransactions(
    String table, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await dbService.database;

    return await db.query(
      table,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get mobile number of the current user (optional)
  Future<String> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber') ??
        (throw Exception('No mobile number stored'));
  }
}
