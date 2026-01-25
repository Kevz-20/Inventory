import '../services/db_service.dart';
import '../models/income_statement_model.dart';
import 'account_repository.dart';

class IncomeStatementRepository {
  final AccountRepository accountRepository;

  IncomeStatementRepository({required this.accountRepository});

  Future<IncomeStatementModel> fetchIncomeStatement({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBService.instance.database;
    final accountId = await accountRepository.getAccountId();

    // Convert startDate and endDate to the full day range
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      0,
      0,
      0,
    );
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Convert to ISO8601 string for sqflite
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    double valueOf(List<Map<String, Object?>> r) {
      return (r.first['total'] as num?)?.toDouble() ?? 0;
    }

    // --------------------------
    // CATEGORY MAP FOR EXPENSES
    // --------------------------
    final categoryMap = {
      'kompra': ['Kumpra / Stock in'],
      'electricity': ['Tubig / Kuryente'],
      'transportation': ['Transportasyon'],
      'rent': ['Mga Bayronon'],
      'misc': ['Uban pa'],
    };

    // Helper to get total expenses by category
    Future<double> fetchExpenseByCategory(String key) async {
      final categories = categoryMap[key] ?? [key];
      final placeholders = List.filled(categories.length, '?').join(',');
      final result = await db.rawQuery(
        '''
        SELECT SUM(amount) AS total
        FROM expenses
        WHERE account_id = ? AND category IN ($placeholders) AND created_at BETWEEN ? AND ?
        ''',
        [accountId, ...categories, startStr, endStr],
      );
      return valueOf(result);
    }

    // ----------------------
    // SALES
    // ----------------------
    final salesResult = await db.rawQuery(
      '''
      SELECT SUM(si.unit_price * si.quantity) AS total
      FROM sale_item si
      JOIN sales s ON si.sale_id = s.id
      WHERE s.account_id = ? AND s.created_at BETWEEN ? AND ?
      ''',
      [accountId, startStr, endStr],
    );

    final sales = valueOf(salesResult);
    final merchandiseSales = sales; // assuming all sales are merchandise

    // ----------------------
    // COST OF GOODS SOLD (KOMPRA)
    // ----------------------
    final kompraResult = await db.rawQuery(
      '''
      SELECT SUM(p.purchase_price * si.quantity) AS total
      FROM sale_item si
      JOIN product p ON si.product_id = p.id
      JOIN sales s ON si.sale_id = s.id
      WHERE s.account_id = ? AND s.created_at BETWEEN ? AND ?
      ''',
      [accountId, startStr, endStr],
    );

    final kompra = valueOf(kompraResult);

    // ----------------------
    // OTHER EXPENSES
    // ----------------------
    final electricity = await fetchExpenseByCategory('electricity');
    final rentPayment = await fetchExpenseByCategory('rent');
    final miscExpenses = await fetchExpenseByCategory('misc');
    final transportation = await fetchExpenseByCategory('transportation');

    // ----------------------
    // NET INCOME
    // ----------------------
    final totalExpenses =
        kompra + electricity + rentPayment + miscExpenses + transportation;
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
