import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_history_model.dart';
import '../services/db_service.dart';

class TransactionHistoryRepository {
  final dbService = DBService.instance;

  Future<TransactionHistoryModel> loadHistory() async {
    final db = await dbService.database;
    final accountId = await getAccountId();

    // Get expenses
    final expenses = await db.query(
      'expenses',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );

    // Get sales cash
    final salesCash = await db.query(
      'sales_cash',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );

    // Get sales credit
    final salesCredit = await db.query(
      'sales_credit',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );

    // Get capital management
    final capitalManagement = await db.query(
      'capital_management',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
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
    String table,
    int accountId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await dbService.database;

    return await db.query(
      table,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Get mobile number
  Future<String> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber') ??
        (throw Exception('No mobile number stored'));
  }

  // Get account id
  Future<int> getAccountId() async {
    final db = await dbService.database;
    final mobile = await getMobileNumber();

    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobile],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No account found for mobile $mobile');
    }

    return result.first['id'] as int;
  }
}
