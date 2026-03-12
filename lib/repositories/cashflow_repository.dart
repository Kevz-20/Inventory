import '../services/db_service.dart';
import '../models/cashflow_model.dart';

class CashflowRepository {
  final _dbService = DBService.instance;

  String? _buildRecordedBy(Map<String, dynamic> row) {
    final first = (row['created_by_first_name'] ?? '').toString().trim();
    final middle = (row['created_by_middle_name'] ?? '').toString().trim();
    final last = (row['created_by_last_name'] ?? '').toString().trim();

    final full = [first, middle, last]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    return full.isNotEmpty ? full : null;
  }

  Future<List<CashflowRecord>> getCashflows() async {
    final db = await _dbService.database;
    List<Map<String, dynamic>> allRows = [];

    // ---------------------------------------------------------
    // 1️⃣ FETCH CAPITAL (Treat as normal transaction)
    // ---------------------------------------------------------
    try {
      final capitalResult = await db.query(
        'capital_management',
        columns: [
          'capital',
          'created_at',
          'created_by_first_name',
          'created_by_middle_name',
          'created_by_last_name',
        ],
      );

      for (var row in capitalResult) {
        final amount = (row['capital'] as num?)?.toDouble() ?? 0;
        final dateStr = row['created_at'] as String?;

        if (amount > 0) {
          allRows.add({
            'date': dateStr ?? DateTime.now().toIso8601String(),
            'item': 'Capital',
            'cash_in': amount,
            'cash_out': 0.0,

            // ✅ added
            'created_by_first_name': row['created_by_first_name'],
            'created_by_middle_name': row['created_by_middle_name'],
            'created_by_last_name': row['created_by_last_name'],
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
      // Cash Sales (has created_by_* in your DB)
      final salesCash = await db.rawQuery('''
        SELECT 
          created_at AS date,
          'Cash Sale' AS item,
          amount AS cash_in,
          0 AS cash_out,
          created_by_first_name,
          created_by_middle_name,
          created_by_last_name
        FROM sales_cash
      ''');

      // Credit Payments (customer_payment has NO created_by columns in your DBService)
      final creditPayments = await db.rawQuery('''
        SELECT 
          paid_at AS date,
          'Customer Utang Payment' AS item,
          amount AS cash_in,
          0 AS cash_out,
          NULL AS created_by_first_name,
          NULL AS created_by_middle_name,
          NULL AS created_by_last_name
        FROM customer_payment
      ''');

      // Capital Deposits (capital_transaction has NO created_by columns in your DBService)
      final capitalIn = await db.rawQuery('''
        SELECT 
          date AS date,
          'Capital Deposit' AS item,
          amount AS cash_in,
          0 AS cash_out,
          NULL AS created_by_first_name,
          NULL AS created_by_middle_name,
          NULL AS created_by_last_name
        FROM capital_transaction
        WHERE transaction_type_id = (
            SELECT id FROM transaction_type_choices WHERE value = 'deposit'
        )
      ''');

      // Expenses (has created_by_* in your DB)
      final expenses = await db.rawQuery('''
        SELECT 
          created_at AS date,
          category AS item,
          0 AS cash_in,
          amount AS cash_out,
          created_by_first_name,
          created_by_middle_name,
          created_by_last_name
        FROM expenses
      ''');

      // Payable Payments (payable_payment has NO created_by columns in your DBService)
      final payablePayments = await db.rawQuery('''
        SELECT 
          date AS date,
          'Payable Payment' AS item,
          0 AS cash_in,
          amount AS cash_out,
          NULL AS created_by_first_name,
          NULL AS created_by_middle_name,
          NULL AS created_by_last_name
        FROM payable_payment
      ''');

      // Capital Withdrawals (capital_transaction has NO created_by columns in your DBService)
      final capitalOut = await db.rawQuery('''
        SELECT 
          date AS date,
          'Capital Withdrawal' AS item,
          0 AS cash_in,
          amount AS cash_out,
          NULL AS created_by_first_name,
          NULL AS created_by_middle_name,
          NULL AS created_by_last_name
        FROM capital_transaction
        WHERE transaction_type_id = (
            SELECT id FROM transaction_type_choices WHERE value = 'withdraw'
        )
      ''');

      // Owner Installments (you added created_by_* via upgrade v7)
      final ownerInstallments = await db.rawQuery('''
        SELECT 
          created_at AS date,
          item || ' Downpayment' AS item,
          0 AS cash_in,
          downpayment AS cash_out,
          created_by_first_name,
          created_by_middle_name,
          created_by_last_name
        FROM owner_installments
      ''');

      // Merge all lists (same as your original behavior)
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
    // 4️⃣ CALCULATE RUNNING BALANCE (same logic)
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

          // ✅ NEW: recordedBy derived from created_by_* fields
          recordedBy: _buildRecordedBy(row),
        ),
      );
    }

    return records;
  }
}
