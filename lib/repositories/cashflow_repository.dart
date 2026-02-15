import '../services/db_service.dart';
import '../models/cashflow_model.dart';

class CashflowRepository {
  final _dbService = DBService.instance;

  Future<List<CashflowRecord>> getCashflows() async {
    final db = await _dbService.database;
    List<Map<String, dynamic>> allRows = [];

    // ---------------------------------------------------------
    // 1️⃣ FETCH CAPITAL (Treat as normal transaction)
    // ---------------------------------------------------------
    try {
      final capitalResult = await db.query(
        'capital_management',
        columns: ['capital', 'created_at'], 
      );

      for (var row in capitalResult) {
        final amount = (row['capital'] as num?)?.toDouble() ?? 0;
        final dateStr = row['created_at'] as String?;
        
        if (amount > 0) {
          allRows.add({
            'date': dateStr ?? DateTime.now().toIso8601String(),
            'item': 'Capital', // Renamed to just "Capital"
            'cash_in': amount,
            'cash_out': 0,
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching capital: $e");
    }

    // ---------------------------------------------------------
    // 2️⃣ FETCH ALL OTHER TRANSACTIONS
    // ---------------------------------------------------------
    try {
      // Cash Sales
      final salesCash = await db.rawQuery('''
        SELECT created_at AS date, 'Cash Sale' AS item, amount AS cash_in, 0 AS cash_out
        FROM sales_cash
      ''');

      // Credit Payments
      final creditPayments = await db.rawQuery('''
        SELECT paid_at AS date, 'Credit Payment' AS item, amount AS cash_in, 0 AS cash_out
        FROM sales_credit_payment
      ''');

      // Capital Deposits (Additional)
      final capitalIn = await db.rawQuery('''
        SELECT date AS date, 'Capital Deposit' AS item, amount AS cash_in, 0 AS cash_out
        FROM capital_transaction
        WHERE transaction_type_id = (
            SELECT id FROM transaction_type_choices WHERE value = 'deposit'
        )
      ''');

      // Expenses
      final expenses = await db.rawQuery('''
        SELECT created_at AS date, category AS item, 0 AS cash_in, amount AS cash_out
        FROM expenses
      ''');

      // Payable Payments
      final payablePayments = await db.rawQuery('''
        SELECT date AS date, 'Payable Payment' AS item, 0 AS cash_in, amount AS cash_out
        FROM payable_payment
      ''');

      // Capital Withdrawals
      final capitalOut = await db.rawQuery('''
        SELECT date AS date, 'Capital Withdrawal' AS item, 0 AS cash_in, amount AS cash_out
        FROM capital_transaction
        WHERE transaction_type_id = (
            SELECT id FROM transaction_type_choices WHERE value = 'withdraw'
        )
      ''');

      // Owner Installments
      final ownerInstallments = await db.rawQuery('''
        SELECT created_at AS date, item || ' Downpayment' AS item, 0 AS cash_in, downpayment AS cash_out
        FROM owner_installments
      ''');

      // Merge all lists
      allRows.addAll([
        ...salesCash,
        ...creditPayments,
        ...capitalIn,
        ...expenses,
        ...payablePayments,
        ...capitalOut,
        ...ownerInstallments,
      ]);

    } catch (e) {
      // ignore: avoid_print
      print("Error fetching transactions: $e");
    }

    // ---------------------------------------------------------
    // 3️⃣ SORT STRICTLY CHRONOLOGICAL (By Date Only)
    // ---------------------------------------------------------
    allRows.sort((a, b) {
      final dateA = DateTime.tryParse(a['date']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['date']?.toString() ?? '');

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      // Oldest First
      return dateA.compareTo(dateB);
    });

    // ---------------------------------------------------------
    // 4️⃣ CALCULATE RUNNING BALANCE
    // ---------------------------------------------------------
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

    return records;
  }
}