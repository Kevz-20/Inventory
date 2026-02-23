import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_history_model.dart';
import '../services/db_service.dart';

class TransactionHistoryRepository {
  final dbService = DBService.instance;

  /// Load all transaction history without filtering by account
  Future<TransactionHistoryModel> loadHistory() async {
    final db = await dbService.database;

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
    final customerPayments = await db.rawQuery('''
      SELECT 
        cp.amount,
        cp.paid_at AS created_at,
        'in' AS direction,
        TRIM(
          COALESCE(c.first_name, '') || ' ' ||
          COALESCE(c.middle_name, '') || ' ' ||
          COALESCE(c.last_name, '')
        ) AS description
      FROM customer_payment cp
      JOIN customer c ON c.id = cp.customer_id
      ORDER BY cp.paid_at DESC
    ''');

    // Utang Payments (payable payments)
    final utangPayments = await db.rawQuery('''
      SELECT 
        pp.amount,
        pp.date AS created_at,
        'out' AS direction,
        COALESCE(p.item, '') AS description
      FROM payable_payment pp
      JOIN payable p ON p.id = pp.payable_id
      ORDER BY pp.date DESC
    ''');

    // Owner Payments (owner installments/downpayments)
    final ownerPayments = await db.rawQuery('''
      SELECT
        oi.downpayment AS amount,
        oi.created_at AS created_at,
        'Downpayment' AS type,
        'out' AS direction,
        COALESCE(oi.item, '') AS description
      FROM owner_installments oi
      ORDER BY oi.created_at DESC
    ''');

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
