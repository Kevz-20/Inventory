import '../services/db_service.dart';
import '../models/cashflow_model.dart';
import 'capital_management_repository.dart';

class CashflowRepository {
  final _dbService = DBService.instance;

  /// Fetch all cashflow records (no account filter)
  Future<List<CashflowRecord>> getCashflows() async {
    final db = await _dbService.database;

    // --------------------
    // Fetch starting cash from capital_management (latest record)
    // --------------------
    double startingCash = 0;
    DateTime startingDate = DateTime.now();

    final capitalRepo = CapitalManagementRepository(db);
    final latestCapital = await capitalRepo.getLatestCapital();

    if (latestCapital != null) {
      startingCash = latestCapital.cashOnHand;
      startingDate = latestCapital.createdAt;
    }

    // --------------------
    // Fetch all transactions (global, no account filter)
    // --------------------
    final salesCash = await db.rawQuery('''
      SELECT created_at AS date, 'Cash Sale' AS item, amount AS cash_in, 0 AS cash_out
      FROM sales_cash
    ''');

    final creditPayments = await db.rawQuery('''
      SELECT paid_at AS date, 'Credit Payment' AS item, amount AS cash_in, 0 AS cash_out
      FROM sales_credit_payment
    ''');

    final capitalIn = await db.rawQuery('''
      SELECT date AS date, 'Capital Deposit' AS item, amount AS cash_in, 0 AS cash_out
      FROM capital_transaction
      WHERE transaction_type_id = (
        SELECT id FROM transaction_type_choices WHERE value = 'deposit'
      )
    ''');

    final expenses = await db.rawQuery('''
      SELECT created_at AS date, category AS item, 0 AS cash_in, amount AS cash_out
      FROM expenses
    ''');

    final payablePayments = await db.rawQuery('''
      SELECT date AS date, 'Payable Payment' AS item, 0 AS cash_in, amount AS cash_out
      FROM payable_payment
    ''');

    final capitalOut = await db.rawQuery('''
      SELECT date AS date, 'Capital Withdrawal' AS item, 0 AS cash_in, amount AS cash_out
      FROM capital_transaction
      WHERE transaction_type_id = (
        SELECT id FROM transaction_type_choices WHERE value = 'withdraw'
      )
    ''');

    final ownerInstallments = await db.rawQuery('''
      SELECT created_at AS date, item || ' Downpayment' AS item, 0 AS cash_in, downpayment AS cash_out
      FROM owner_installments
    ''');

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
    // Sort chronologically
    // --------------------
    allRows.sort((a, b) =>
        DateTime.parse(a['date'] as String)
            .compareTo(DateTime.parse(b['date'] as String)));

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
    // Reverse for display: newest first
    // --------------------
    return records.reversed.toList();
  }
}
