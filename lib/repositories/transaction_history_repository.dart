import '../services/db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionHistoryRepository {
  final DBService dbService;

  TransactionHistoryRepository({required this.dbService});

  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    if (mobile == null) {
      throw Exception('No mobile number stored in SharedPreferences');
    }
    return mobile;
  }

  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    final db = await dbService.database;
    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No account found for mobile number $mobileNumber');
    }
    return result.first['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getAllTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await dbService.database;
    final accountId = await getAccountId();

    // Fetch all relevant tables first
    final expenses = await db.query(
      'expenses',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );

    final salesCash = await db.query(
      'sales_cash',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );

    final salesCredit = await db.query(
      'sales_credit',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );

    final capitalTransactions = await db.query(
      'capital_transaction',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );

    // Combine all transactions
    List<Map<String, dynamic>> allTransactions = [
      ...expenses,
      ...salesCash,
      ...salesCredit,
      ...capitalTransactions,
    ];

    // Filter by start date
    if (startDate != null) {
      allTransactions = allTransactions.where((tx) {
        final txDate = DateTime.parse(tx['created_at'] ?? tx['date']);
        return !txDate.isBefore(startDate);
      }).toList();
    }

    // Filter by end date
    if (endDate != null) {
      allTransactions = allTransactions.where((tx) {
        final txDate = DateTime.parse(tx['created_at'] ?? tx['date']);
        return !txDate.isAfter(endDate);
      }).toList();
    }

    // Sort by date descending (optional)
    allTransactions.sort((a, b) {
      final dateA = DateTime.parse(a['created_at'] ?? a['date']);
      final dateB = DateTime.parse(b['created_at'] ?? b['date']);
      return dateB.compareTo(dateA);
    });

    return allTransactions;
  }
}
