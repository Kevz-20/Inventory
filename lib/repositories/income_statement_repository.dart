import '../services/db_service.dart';
import '../models/income_statement_model.dart';

class IncomeStatementRepository {
  IncomeStatementRepository();

  Future<IncomeStatementModel> fetchIncomeStatement({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBService.instance.database;

    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      0,
      0,
      0,
    );
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    double valueOf(List<Map<String, Object?>> r) =>
        (r.first['total'] as num?)?.toDouble() ?? 0;

    // ---------------- SALES ----------------
    final salesResult = await db.rawQuery(
      '''
      SELECT SUM(si.unit_price * si.quantity) AS total
      FROM sale_item si
      JOIN sales s ON si.sale_id = s.id
      WHERE s.created_at BETWEEN ? AND ?
      ''',
      [startStr, endStr],
    );

    final sales = valueOf(salesResult);
    final merchandiseSales = sales;

    // ---------------- EXPENSES (DYNAMIC) ----------------
    final expenseRows = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM expenses
      WHERE created_at BETWEEN ? AND ?
      GROUP BY category
      ORDER BY category COLLATE NOCASE ASC
      ''',
      [startStr, endStr],
    );

    final Map<String, double> expenseCategories = {};

    for (final row in expenseRows) {
      final rawCategory = (row['category'] ?? '').toString().trim();
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;

      if (rawCategory.isEmpty) continue;

      expenseCategories[rawCategory] = total;
    }

    final totalExpenses = expenseCategories.values.fold(
      0.0,
      (sum, value) => sum + value,
    );

    final netIncome = sales - totalExpenses;

    return IncomeStatementModel(
      merchandiseSales: merchandiseSales,
      sales: sales,
      expenseCategories: expenseCategories,
      netIncome: netIncome,
    );
  }
}