import '../services/db_service.dart';
import '../models/cashflow_model.dart';

class CashflowRepository {
  final _dbService = DBService.instance;

  Future<List<CashflowRecord>> getCashflows(int accountId) async {
    final db = await _dbService.database;

    // --------------------
    // Fetch starting cash from capital_management
    // --------------------
    double startingCash = 0;
    DateTime startingDate = DateTime(2000); // default very old date
    final capitalResult = await db.query(
      'capital_management',
      columns: ['cash_on_hand', 'created_at'],
      where: 'account_id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (capitalResult.isNotEmpty) {
      startingCash = (capitalResult.first['cash_on_hand'] as num?)?.toDouble() ?? 0;
      final dateStr = capitalResult.first['created_at'] as String?;
      if (dateStr != null) startingDate = DateTime.parse(dateStr);
    }

    // --------------------
    // Fetch all other transactions
    // --------------------
    final salesCash = await db.rawQuery('''
      SELECT created_at AS date, 'Cash Sale' AS item, amount AS cash_in, 0 AS cash_out
      FROM sales_cash
      WHERE account_id = ?
    ''', [accountId]);

    final creditPayments = await db.rawQuery('''
      SELECT paid_at AS date, 'Credit Payment' AS item, amount AS cash_in, 0 AS cash_out
      FROM sales_credit_payment
      WHERE account_id = ?
    ''', [accountId]);

    final capitalIn = await db.rawQuery('''
      SELECT date AS date, 'Capital Deposit' AS item, amount AS cash_in, 0 AS cash_out
      FROM capital_transaction
      WHERE account_id = ?
        AND transaction_type_id = (
          SELECT id FROM transaction_type_choices WHERE value = 'deposit'
        )
    ''', [accountId]);

    final expenses = await db.rawQuery('''
      SELECT created_at AS date, category AS item, 0 AS cash_in, amount AS cash_out
      FROM expenses
      WHERE account_id = ?
    ''', [accountId]);

    final payablePayments = await db.rawQuery('''
      SELECT date AS date, 'Payable Payment' AS item, 0 AS cash_in, amount AS cash_out
      FROM payable_payment
      WHERE payable_id IN (
        SELECT id FROM payable WHERE account_id = ?
      )
    ''', [accountId]);

    final capitalOut = await db.rawQuery('''
      SELECT date AS date, 'Capital Withdrawal' AS item, 0 AS cash_in, amount AS cash_out
      FROM capital_transaction
      WHERE account_id = ?
        AND transaction_type_id = (
          SELECT id FROM transaction_type_choices WHERE value = 'withdraw'
        )
    ''', [accountId]);

    final ownerInstallments = await db.rawQuery('''
      SELECT created_at AS date, item || ' Downpayment' AS item, 0 AS cash_in, downpayment AS cash_out
      FROM owner_installments
      WHERE account_id = ?
    ''', [accountId]);

    // --------------------
    // Merge all transactions
    // --------------------
    final allRows = [
      ...salesCash,
      ...creditPayments,
      ...capitalIn,
      ...expenses,
      ...payablePayments,
      ...capitalOut,
      ...ownerInstallments,
    ];

    // --------------------
    // Include Starting Cash as first transaction if > 0
    // Give it the earliest date so it stays at the bottom
    // --------------------
    if (startingCash > 0) {
      allRows.add({
        'date': startingDate.toIso8601String(),
        'item': 'Starting Cash',
        'cash_in': startingCash,
        'cash_out': 0,
      });
    }

    // --------------------
    // Sort chronologically for balance computation
    // --------------------
    allRows.sort((a, b) =>
        DateTime.parse(a['date'] as String).compareTo(DateTime.parse(b['date'] as String)));

    // --------------------
    // Compute running balance
    // --------------------
    double balance = 0;
    final List<CashflowRecord> records = [];
    for (final row in allRows) {
      final cashIn = (row['cash_in'] as num?)?.toDouble() ?? 0;
      final cashOut = (row['cash_out'] as num?)?.toDouble() ?? 0;
      balance += cashIn - cashOut;

      records.add(
        CashflowRecord(
          date: DateTime.parse(row['date'] as String),
          item: row['item'] as String,
          cashIn: cashIn,
          cashOut: cashOut,
          balance: balance,
        ),
      );
    }

    // --------------------
    // Reverse for display: newest transactions at top
    // --------------------
    return records.reversed.toList();
  }
}
