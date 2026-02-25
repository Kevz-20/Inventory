import '../services/db_service.dart';
import '../view_models/home_view_model.dart';

class HomeRepository {
  HomeRepository(this._dbService);

  final DBService _dbService;

  // ----------------------------
  // CASH ON HAND (CURRENT DB)
  // sales.total - expenses.amount
  // ----------------------------
  Future<double> getCashOnHand() async {
  final db = await _dbService.database;

  // ✅ detect correct column name in capital_management
  final info = await db.rawQuery("PRAGMA table_info(capital_management)");
  final cols = info.map((e) => e['name'].toString()).toList();

  String? cashCol;
  const candidates = [
    'cashOnHand',
    'cash_on_hand',
    'cashonhand',
    'cash',
    'cash_hand',
  ];

  for (final c in candidates) {
    if (cols.contains(c)) {
      cashCol = c;
      break;
    }
  }

  if (cashCol == null) {
    // ignore: avoid_print
    print("HOME CASH: No cash column found in capital_management. cols=$cols");
    return 0.0;
  }

  final cash = await _safeSum(db, table: 'capital_management', column: cashCol);

  // ignore: avoid_print
  print("HOME CASH (from capital_management.$cashCol) => $cash");

  return cash;
}

  Future<String?> getMobileNumber() async {
    final db = await _dbService.database;

    final rows = await db.rawQuery('''
      SELECT mobile_number
      FROM account
      ORDER BY id DESC
      LIMIT 1
    ''');

    if (rows.isEmpty) return null;
    return rows.first['mobile_number']?.toString();
  }

  Future<({List<CashflowPoint> income, List<CashflowPoint> expense})>
      getIncomeExpenseLast7Days() async {
    final db = await _dbService.database;

    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 6));

    final startStr = _fmt(start);
    final endStr = _fmt(end);

    final incomeRows = await db.rawQuery('''
      SELECT DATE(created_at) AS d,
             COALESCE(SUM(total), 0) AS total
      FROM sales
      WHERE DATE(created_at) BETWEEN ? AND ?
      GROUP BY DATE(created_at)
      ORDER BY DATE(created_at)
    ''', [startStr, endStr]);

    final expenseRows = await db.rawQuery('''
      SELECT DATE(created_at) AS d,
             COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE DATE(created_at) BETWEEN ? AND ?
      GROUP BY DATE(created_at)
      ORDER BY DATE(created_at)
    ''', [startStr, endStr]);

    final incomeMap = <String, double>{};
    for (final r in incomeRows) {
      incomeMap[r['d'].toString()] = _toDouble(r['total']);
    }

    final expenseMap = <String, double>{};
    for (final r in expenseRows) {
      expenseMap[r['d'].toString()] = _toDouble(r['total']);
    }

    final income = <CashflowPoint>[];
    final expense = <CashflowPoint>[];

    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final key = _fmt(day);
      income.add(CashflowPoint(day: day, net: incomeMap[key] ?? 0));
      expense.add(CashflowPoint(day: day, net: expenseMap[key] ?? 0));
    }

    return (income: income, expense: expense);
  }

  // helpers
  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static double _toDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Future<double> _safeSum(
    dynamic db, {
    required String table,
    required String column,
  }) async {
    try {
      final rows = await db.rawQuery('''
        SELECT COALESCE(SUM($column), 0) AS total
        FROM $table
      ''');
      return _toDouble(rows.first['total']);
    } catch (_) {
      return 0.0;
    }
  }
}