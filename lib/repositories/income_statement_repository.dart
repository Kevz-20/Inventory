import '../services/db_service.dart';
import '../models/income_statement_model.dart';

class IncomeStatementRepository {
  IncomeStatementRepository();

  Future<IncomeStatementModel> fetchIncomeStatement({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBService.instance.database;

    // Convert to start/end of day
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    double valueOf(List<Map<String, Object?>> r) =>
        (r.first['total'] as num?)?.toDouble() ?? 0;

    final categoryMap = {
      'kompra': ['Kumpra'], 
      'electricity': ['Tubig / Kuryente'],
      'transportation': ['Transportasyon'],
      'rent': ['Mga Bayronon'],
      'misc': ['Uban pa'],
    };

    // ---------------- EXPENSES ----------------
    Future<double> fetchExpenseByCategory(String key) async {
      final categories = categoryMap[key] ?? [key];
      final placeholders = List.filled(categories.length, '?').join(',');
      final result = await db.rawQuery(
        '''
        SELECT SUM(amount) AS total
        FROM expenses
        WHERE category IN ($placeholders) AND created_at BETWEEN ? AND ?
        ''',
        [...categories, startStr, endStr],
      );
      return valueOf(result);
    }

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

    // ---------------- EXPENSES ----------------
    final kompra = await fetchExpenseByCategory('kompra');
    final electricity = await fetchExpenseByCategory('electricity');
    final rentPayment = await fetchExpenseByCategory('rent');
    final miscExpenses = await fetchExpenseByCategory('misc');
    final transportation = await fetchExpenseByCategory('transportation');

    // ---------------- NET INCOME ----------------
    final totalExpenses = kompra + electricity + rentPayment + miscExpenses + transportation;
    final netIncome = sales - totalExpenses;

    return IncomeStatementModel(
      merchandiseSales: merchandiseSales,
      sales: sales,
      kompra: kompra,
      electricity: electricity,
      transportation: transportation,
      rentPayment: rentPayment,
      miscExpenses: miscExpenses,
      netIncome: netIncome,
    );
  }
}
