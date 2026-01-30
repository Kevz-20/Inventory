import 'package:flutter/material.dart';
import '../services/db_service.dart';

class BalanceSheetRepository {
  final dbService = DBService.instance;

  // ---------------- ASSETS ----------------
  /// Fetches Assets for given account(s)
  /// Returns a map with:
  /// - "Cash on Hand"
  /// - "Accounts Receivable"
  /// - "Assets" (Fixed Assets)
  Future<Map<String, double>> getAssets({List<int>? accountIds}) async {
    final db = await dbService.database;

    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (accountIds != null && accountIds.isNotEmpty) {
        final placeholders = List.filled(accountIds.length, '?').join(',');
        whereClause = 'AND account_id IN ($placeholders)';
        whereArgs = accountIds;
      }

      // ---------------- CASH ON HAND ----------------
      final capitalRes = await db.rawQuery('''
        SELECT IFNULL(SUM(cash_on_hand),0) AS cash
        FROM capital_management
        WHERE 1=1 $whereClause
      ''', whereArgs);
      double totalCashOnHand = (capitalRes.first['cash'] as num?)?.toDouble() ?? 0.0;

      // ---------------- FIXED ASSETS ----------------
      final assetRes = await db.rawQuery('''
        SELECT IFNULL(SUM(cost - accumulated_depreciation),0) AS fixed_assets
        FROM fixed_asset
        WHERE 1=1 $whereClause
      ''', whereArgs);
      double fixedAssets = (assetRes.first['fixed_assets'] as num?)?.toDouble() ?? 0.0;

      // ---------------- ACCOUNTS RECEIVABLE ----------------
      final arRes = await db.rawQuery('''
        SELECT IFNULL(SUM(amount),0) AS total_ar
        FROM sales_credit
        WHERE (status_id = 0 OR status_id = 1) $whereClause
      ''', whereArgs);
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
  Future<Map<String, double>> getLiabilities({List<int>? accountIds}) async {
    final db = await dbService.database;

    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (accountIds != null && accountIds.isNotEmpty) {
        final placeholders = List.filled(accountIds.length, '?').join(',');
        whereClause = 'AND account_id IN ($placeholders)';
        whereArgs = accountIds;
      }

      // Accounts Payable = sum of remaining_amount
      final payableRes = await db.rawQuery('''
        SELECT IFNULL(SUM(remaining_amount), 0) AS total_accounts_payable
        FROM payable
        WHERE (is_paid IS NULL OR is_paid = 0) $whereClause
      ''', whereArgs);

      double totalLiabilities = (payableRes.first['total_accounts_payable'] as num?)?.toDouble() ?? 0.0;

      return {"Accounts Payable": totalLiabilities};
    } catch (e) {
      debugPrint("Error in getLiabilities: $e");
      return {"Accounts Payable": 0.0};
    }
  }

  // ---------------- OWNER'S EQUITY ----------------
  /// Fetches Owner's Equity
  /// Returns a map with:
  /// - "Capital"
  /// - "Net Income (Loss)"
  Future<Map<String, double>> getEquity({List<int>? accountIds}) async {
    final db = await dbService.database;

    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (accountIds != null && accountIds.isNotEmpty) {
        final placeholders = List.filled(accountIds.length, '?').join(',');
        whereClause = 'WHERE 1=1 AND account_id IN ($placeholders)';
        whereArgs = accountIds;
      }

      // ---------------- CAPITAL ----------------
      final capitalRes = await db.rawQuery('''
        SELECT IFNULL(SUM(capital),0) AS total
        FROM capital_management
        $whereClause
      ''', whereArgs);
      double capital = (capitalRes.first['total'] as num?)?.toDouble() ?? 0.0;

      // ---------------- NET INCOME ----------------
      final salesRes = await db.rawQuery('''
        SELECT IFNULL(SUM(total),0) AS total
        FROM sales
        $whereClause
      ''', whereArgs);
      double totalSales = (salesRes.first['total'] as num?)?.toDouble() ?? 0.0;

      final expensesRes = await db.rawQuery('''
        SELECT IFNULL(SUM(amount),0) AS total
        FROM expenses
        $whereClause
      ''', whereArgs);
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
