import 'package:flutter/material.dart';
import '../services/db_service.dart';

class BalanceSheetRepository {
  final dbService = DBService.instance;

  // ---------------- ASSETS ----------------
  /// Fetches Assets (Cash, Accounts Receivable, Fixed Assets)
  /// Sums across all accounts (no account filter)
  Future<Map<String, double>> getAssets() async {
    final db = await dbService.database;

    try {
      // ---------------- CASH ON HAND ----------------
      final capitalRes = await db.rawQuery('''
        SELECT IFNULL(SUM(cash_on_hand),0) AS cash
        FROM capital_management
      ''');
      double totalCashOnHand = (capitalRes.first['cash'] as num?)?.toDouble() ?? 0.0;

      // ---------------- FIXED ASSETS ----------------
      final assetRes = await db.rawQuery('''
        SELECT IFNULL(SUM(cost - accumulated_depreciation),0) AS fixed_assets
        FROM fixed_asset
      ''');
      double fixedAssets = (assetRes.first['fixed_assets'] as num?)?.toDouble() ?? 0.0;

      // ---------------- ACCOUNTS RECEIVABLE ----------------
      final arRes = await db.rawQuery('''
        SELECT IFNULL(SUM(amount),0) AS total_ar
        FROM sales_credit
        WHERE status_id IN (0, 1)
      ''');
      double totalAR = (arRes.first['total_ar'] as num?)?.toDouble() ?? 0.0;

      return {
        "Cash on Hand": totalCashOnHand,
        "Accounts Receivable": totalAR,
        "Assets": fixedAssets,
      };
    } catch (e) {
      debugPrint("Error in getAssets: $e");
      return {
        "Cash on Hand": 0.0,
        "Accounts Receivable": 0.0,
        "Assets": 0.0,
      };
    }
  }

  // ---------------- LIABILITIES ----------------
  /// Fetches total liabilities (Accounts Payable)
  Future<Map<String, double>> getLiabilities() async {
    final db = await dbService.database;

    try {
      final payableRes = await db.rawQuery('''
        SELECT IFNULL(SUM(remaining_amount), 0) AS total_accounts_payable
        FROM payable
        WHERE is_paid IS NULL OR is_paid = 0
      ''');

      double totalLiabilities = (payableRes.first['total_accounts_payable'] as num?)?.toDouble() ?? 0.0;

      return {"Accounts Payable": totalLiabilities};
    } catch (e) {
      debugPrint("Error in getLiabilities: $e");
      return {"Accounts Payable": 0.0};
    }
  }

  // ---------------- OWNER'S EQUITY ----------------
  /// Fetches Owner's Equity (Capital + Net Income)
  Future<Map<String, double>> getEquity() async {
    final db = await dbService.database;

    try {
      // ---------------- CAPITAL ----------------
      final capitalRes = await db.rawQuery('''
        SELECT IFNULL(SUM(capital),0) AS total
        FROM capital_management
      ''');
      double capital = (capitalRes.first['total'] as num?)?.toDouble() ?? 0.0;

      // ---------------- NET INCOME ----------------
      final salesRes = await db.rawQuery('''
        SELECT IFNULL(SUM(total),0) AS total
        FROM sales
      ''');
      double totalSales = (salesRes.first['total'] as num?)?.toDouble() ?? 0.0;

      final expensesRes = await db.rawQuery('''
        SELECT IFNULL(SUM(amount),0) AS total
        FROM expenses
      ''');
      double totalExpenses = (expensesRes.first['total'] as num?)?.toDouble() ?? 0.0;

      double netIncome = totalSales - totalExpenses;

      return {
        "Capital": capital,
        "Net Income (Loss)": netIncome,
      };
    } catch (e) {
      debugPrint("Error in getEquity: $e");
      return {
        "Capital": 0.0,
        "Net Income (Loss)": 0.0,
      };
    }
  }
}
