import '../models/transaction_history_model.dart';
import '../services/db_service.dart';

class TransactionHistoryRepository {
  final dbService = DBService.instance;

  Future<TransactionHistoryModel> loadHistory() async {
    final db = await dbService.database;

    // Expenses
    final expenses = await db.rawQuery(
        '''
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
      '''
    );
    // Sales Cash
    final salesCash = await db.rawQuery(
      '''
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
      '''
    );

    // Sales Credit
    final salesCredit = await db.rawQuery(
  '''
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
  '''
);

    // Capital Management (add creator info)
    final capitalManagement = await db.rawQuery(
      '''
      SELECT 
        cm.id,
        cm.capital,
        cm.bank_cash,
        cm.created_at,
        cm.remarks,
        cm.created_by_first_name,
        cm.created_by_middle_name,
        cm.created_by_last_name
      FROM capital_management cm
      ORDER BY cm.created_at DESC
      '''
    );

    return TransactionHistoryModel(
      expenses: expenses,
      salesCash: salesCash,
      salesCredit: salesCredit,
      capitalManagement: capitalManagement,
    );
  }

  // Pagination
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
}
