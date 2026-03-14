import '../services/db_service.dart';
import '../view_models/home_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber');
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

  Future<List<TopSellingProduct>> getTopSellingProducts({int limit = 5}) async {
    final db = await _dbService.database;

    final rows = await db.rawQuery('''
      SELECT
        p.id AS product_id,
        p.name AS product_name,
        p.image AS product_image,
        COALESCE(SUM(si.quantity), 0) AS units_sold,
        COALESCE(SUM(si.subtotal), 0) AS total_sales
      FROM sale_item si
      INNER JOIN product p ON p.id = si.product_id
      GROUP BY p.id, p.name, p.image
      ORDER BY units_sold DESC, total_sales DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((row) {
      return TopSellingProduct(
        productId: (row['product_id'] as num?)?.toInt() ?? 0,
        name: row['product_name']?.toString() ?? 'Unknown Product',
        imagePath: row['product_image']?.toString(),
        unitsSold: (row['units_sold'] as num?)?.toInt() ?? 0,
        totalSales: _toDouble(row['total_sales']),
      );
    }).toList();
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
