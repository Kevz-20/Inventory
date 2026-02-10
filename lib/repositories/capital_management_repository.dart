import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/capital_management_model.dart';

class CapitalManagementRepository {
  final Database database;

  CapitalManagementRepository(this.database);

  // ---------------- INSERT NEW CAPITAL ----------------
  Future<int> insertCapital(CapitalManagementModel model) async {
    final map = model.toMap();
    map['created_at'] = model.createdAt.toIso8601String();

    debugPrint('>> Inserting capital globally: $map');
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
    final latest = await getLatestCapital();
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
