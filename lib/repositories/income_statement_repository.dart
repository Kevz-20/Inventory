import 'package:sqflite/sqflite.dart';
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
    final Database db = await DBService.instance.database;
    final accountId = await accountRepository.getAccountId();

    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();

    double getValue(List<Map<String, Object?>> r) {
      return (r.first["total"] as num?)?.toDouble() ?? 0;
    }

    // Sales revenue
    final salesResult = await db.rawQuery(
      '''
      SELECT SUM(si.unit_price * si.quantity) AS total
      FROM sale_item si
      JOIN sale s ON si.sale_id = s.id
      WHERE s.account_id = ?
        AND s.created_at BETWEEN ? AND ?
      ''',
      [accountId, start, end],
    );

    final merchandiseSalesResult = salesResult;

    // Kumpra (cost of goods sold)
    final kumpraResult = await db.rawQuery(
      '''
      SELECT SUM(p.purchase_price * si.quantity) AS total
      FROM sale_item si
      JOIN stock_in p ON si.stock_in_id = p.id
      JOIN sale s ON si.sale_id = s.id
      WHERE s.account_id = ?
        AND s.created_at BETWEEN ? AND ?
      ''',
      [accountId, start, end],
    );

    // Transportation expenses
    final transportationResult = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM expenses
      WHERE account_id = ?
        AND description = "Transportation"
        AND created_at BETWEEN ? AND ?
      ''',
      [accountId, start, end],
    );

    // Total expenses
    final expenseResult = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM expenses
      WHERE account_id = ?
        AND created_at BETWEEN ? AND ?
      ''',
      [accountId, start, end],
    );

    final sales = getValue(salesResult);
    final merchandiseSales = getValue(merchandiseSalesResult);
    final kumpra = getValue(kumpraResult);
    final transportation = getValue(transportationResult);
    final totalExpenses = getValue(expenseResult);

    final netIncome = sales - totalExpenses;

    return IncomeStatementModel(
      sales: sales,
      merchandiseSales: merchandiseSales,
      kumpra: kumpra,
      transportation: transportation,
      totalExpenses: totalExpenses,
      netIncome: netIncome,
    );
  }
}
