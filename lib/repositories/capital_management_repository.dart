import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/capital_management_model.dart';
import 'account_repository.dart';

class CapitalManagementRepository {
  final Database database;
  final AccountRepository accountRepository;

  CapitalManagementRepository(this.database)
      : accountRepository = AccountRepository();

  // ---------------- INSERT NEW CAPITAL ----------------
  Future<int> insertCapital(CapitalManagementModel model) async {
    final accountId = await accountRepository.getAccountId(); // for accountability
    final map = model.toMap();
    map['account_id'] = accountId;
    map['created_at'] = model.createdAt.toIso8601String();

    debugPrint('>> Inserting capital: $map');
    return await database.insert('capital_management', map);
  }

  // ---------------- GET ALL CAPITAL RECORDS ----------------
  Future<List<CapitalManagementModel>> getAllCapital() async {
    final result = await database.query(
      'capital_management',
      orderBy: 'id ASC',
    );

    return result.map((e) => CapitalManagementModel.fromMap(e)).toList();
  }

  // ---------------- GET LATEST CAPITAL RECORD ----------------
  Future<CapitalManagementModel?> getLatestCapital({int? accountId}) async {
    String? whereClause;
    List<dynamic>? whereArgs;

    if (accountId != null) {
      whereClause = 'account_id = ?';
      whereArgs = [accountId];
    }

    final result = await database.query(
      'capital_management',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return CapitalManagementModel.fromMap(result.first);
  }

  // ---------------- UPDATE CAPITAL RECORD ----------------
  Future<int> updateCapital(CapitalManagementModel model) async {
    if (model.id == null) {
      throw Exception('Cannot update a record without ID');
    }
    return await database.update(
      'capital_management',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  // ---------------- DELETE CAPITAL RECORD ----------------
  Future<int> deleteCapital(int id) async {
    return await database.delete(
      'capital_management',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- GET TOTAL BALANCE ----------------
  Future<double> getTotalBalance() async {
    final result = await database.rawQuery('''
      SELECT IFNULL(SUM(cash_on_hand + bank_cash), 0) as total_cash
      FROM capital_management
    ''');

    final total = result.first['total_cash'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  // ---------------- GET CASH ON HAND ONLY ----------------
  Future<double> getTotalCashOnHand({int? accountId}) async {
    if (accountId != null) {
      final result = await database.rawQuery('''
        SELECT IFNULL(SUM(cash_on_hand), 0) as total_cash
        FROM capital_management
        WHERE account_id = ?
      ''', [accountId]);

      final total = result.first['total_cash'];
      return total != null ? (total as num).toDouble() : 0.0;
    }

    // fallback: sum all accounts
    final result = await database.rawQuery('''
      SELECT IFNULL(SUM(cash_on_hand), 0) as total_cash
      FROM capital_management
    ''');

    final total = result.first['total_cash'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  // ---------------- DEDUCT CASH ----------------
  /// Deduct cash from the latest record for a specific account
  Future<void> deductCash({
  required double amount, // no accountId
  }) async {
    // Get the latest global capital record
    final latest = await getLatestCapital(); // ignore accountId
    if (latest == null || latest.id == null) {
      throw Exception('No capital record found');
    }

    final totalCash = latest.cashOnHand;

    if (totalCash < amount) {
      throw Exception('Insufficient cash on hand');
    }

    final newCash = (latest.cashOnHand - amount).clamp(0.0, double.infinity);

    final updated = latest.copyWith(cashOnHand: newCash);

    await updateCapital(updated);

    debugPrint('>> Expense deducted: $amount | Remaining cash: $newCash (global)');
  }
}
