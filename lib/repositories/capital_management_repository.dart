import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/capital_management_model.dart';

class CapitalManagementRepository {
  final Database database;

  CapitalManagementRepository(this.database);

  // ---------------- INSERT NEW CAPITAL ----------------
  Future<int> insertCapital(CapitalManagementModel model) async {
    final map = model.toMap();
    map['created_at'] = model.createdAt.toIso8601String();
    await _attachCreatorInfo(map);

    debugPrint('>> Inserting capital globally: $map');
    return await database.insert('capital_management', map);
  }

  Future<void> _attachCreatorInfo(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    final mobileNumber = prefs.getString('mobileNumber');
    if (mobileNumber == null || mobileNumber.trim().isEmpty) return;

    final userRows = await database.query(
      'account',
      columns: ['id', 'first_name', 'middle_name', 'last_name'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber.trim()],
      limit: 1,
    );
    if (userRows.isEmpty) return;

    final user = userRows.first;
    map['account_id'] = user['id'];
    map['created_by_first_name'] = user['first_name'] ?? '';
    map['created_by_middle_name'] = user['middle_name'] ?? '';
    map['created_by_last_name'] = user['last_name'] ?? '';
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
  Future<CapitalManagementModel?> getLatestCapital() async {
    final result = await database.query(
      'capital_management',
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
    final data = model.toMap()..remove('created_at');
    return await database.update(
      'capital_management',
      data,
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
  Future<double> getTotalCashOnHand() async {
    final result = await database.rawQuery('''
      SELECT IFNULL(SUM(cash_on_hand), 0) as total_cash
      FROM capital_management
    ''');

    final total = result.first['total_cash'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  // ---------------- DEDUCT CASH ----------------
  Future<void> deductCash({required double amount}) async {
    if (amount <= 0) return;

    await database.transaction((txn) async {
      final totalRes = await txn.rawQuery('''
        SELECT IFNULL(SUM(cash_on_hand), 0) AS total_cash
        FROM capital_management
      ''');
      final totalCash = (totalRes.first['total_cash'] as num?)?.toDouble() ?? 0.0;

      if (totalCash < amount) {
        throw Exception('Insufficient cash on hand');
      }

      var remainingToDeduct = amount;
      final rows = await txn.query(
        'capital_management',
        columns: ['id', 'cash_on_hand'],
        orderBy: 'id DESC',
      );

      for (final row in rows) {
        if (remainingToDeduct <= 0) break;

        final id = row['id'] as int;
        final currentCash = (row['cash_on_hand'] as num?)?.toDouble() ?? 0.0;
        if (currentCash <= 0) continue;

        final deduct = math.min(currentCash, remainingToDeduct);
        final newCash = currentCash - deduct;

        await txn.update(
          'capital_management',
          {'cash_on_hand': newCash},
          where: 'id = ?',
          whereArgs: [id],
        );

        remainingToDeduct -= deduct;
      }

      if (remainingToDeduct > 0) {
        throw Exception('Insufficient cash on hand');
      }
    });

    final updatedTotal = await getTotalCashOnHand();
    debugPrint(
      '>> Expense deducted: $amount | Remaining cash (global): $updatedTotal',
    );
  }

  // ---------------- ADD CASH ----------------
  Future<void> addCash({required double amount}) async {
    final model = CapitalManagementModel(
      id: null,
      cashOnHand: amount,
      capital: amount,
      bankCash: 0,
      createdAt: DateTime.now(),
    );

    await insertCapital(model);

    debugPrint('>> Cash added globally: $amount');
  }

  Future<void> addCashOnHand(double amount) async {
  final latest = await getLatestCapital(); // get latest global record
  if (latest == null) {
    // if no record exists, insert a new one
    final newRecord = CapitalManagementModel(
      cashOnHand: amount,
      capital: 0,
      bankCash: 0,
    );
    await insertCapital(newRecord);
    debugPrint('>> New capital record created with cash: $amount');
    return;
  }

  // update existing record
  final updated = latest.copyWith(
    cashOnHand: latest.cashOnHand + amount,
    capital: latest.capital + amount,
  );

  await updateCapital(updated);
  debugPrint('>> Added cash on hand: $amount | Total: ${updated.cashOnHand}');
}

Future<void> addCustomerPaymentCash(double amount) async {
  final latest = await getLatestCapital();
  if (latest == null) {
    final newRecord = CapitalManagementModel(
      cashOnHand: amount,
      capital: 0,
      bankCash: 0,
      createdAt: DateTime.now(),
    );
    await insertCapital(newRecord);
    debugPrint('>> New record with customer payment cash: $amount');
    return;
  }

  final updated = latest.copyWith(
    cashOnHand: latest.cashOnHand + amount, // only update cash on hand
  );

  await updateCapital(updated);
  debugPrint('>> Customer payment added to cash on hand: $amount | Total cash: ${updated.cashOnHand}');
}


}
