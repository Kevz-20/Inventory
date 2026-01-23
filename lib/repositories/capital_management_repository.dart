import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/capital_management_model.dart';
import 'account_repository.dart';

class CapitalManagementRepository {
  final Database database;
  final AccountRepository accountRepository;

  CapitalManagementRepository(this.database)
    : accountRepository = AccountRepository();

  // Insert new capital record
  Future<int> insertCapital(CapitalManagementModel model) async {
    final accountId = await accountRepository.getAccountId();
    final map = model.toMap();
    map['account_id'] = accountId;
    debugPrint('>> Inserting capital: $map');
    return await database.insert('capital_management', map);
  }

  // Get all capital records
  Future<List<CapitalManagementModel>> getAllCapital() async {
    final result = await database.query('capital_management');
    return result.map((e) => CapitalManagementModel.fromMap(e)).toList();
  }

  // Update capital record
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

  // Delete capital record
  Future<int> deleteCapital(int id) async {
    return await database.delete(
      'capital_management',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get capital by account
  Future<List<CapitalManagementModel>> getCapitalByAccount() async {
    final accountId = await accountRepository.getAccountId();
    final result = await database.query(
      'capital_management',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    return result.map((e) => CapitalManagementModel.fromMap(e)).toList();
  }

  // Get total balance for the account (cash_on_hand + bank_cash)
  Future<double> getTotalBalanceByAccount() async {
    final accountId = await accountRepository.getAccountId();
    final result = await database.rawQuery(
      '''
        SELECT SUM(cash_on_hand + bank_cash) as total_cash
        FROM capital_management
        WHERE account_id = ?
      ''',
      [accountId],
    );

    final total = result.first['total_cash'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  // Fetch only cash_on_hand for the current account
  Future<List<CapitalManagementModel>> getCashOnHandOnly() async {
    final accountId = await accountRepository.getAccountId();
    final result = await database.query(
      'capital_management',
      columns: ['cash_on_hand'], // only fetch cash_on_hand
      where: 'account_id = ?',
      whereArgs: [accountId],
    );

    return result
        .map(
          (e) => CapitalManagementModel(
            accountId: accountId,
            cashOnHand: (e['cash_on_hand'] as num).toDouble(),
            capital: 0, // default
            bankCash: 0, // default
          ),
        )
        .toList();
  }

  Future<void> deductCash({
    required int accountId,
    required double amount,
  }) async {
    // 1️⃣ Get TOTAL cash_on_hand
    final result = await database.rawQuery(
      '''
    SELECT SUM(cash_on_hand) AS total_cash
    FROM capital_management
    WHERE account_id = ?
    ''',
      [accountId],
    );

    final totalCash = (result.first['total_cash'] as num?)?.toDouble() ?? 0.0;

    if (totalCash < amount) {
      throw Exception('Insufficient cash on hand');
    }

    // 2️⃣ Deduct from the MOST RECENT capital record
    final latestRecord = await database.query(
      'capital_management',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (latestRecord.isEmpty) {
      throw Exception('No capital record found');
    }

    final recordId = latestRecord.first['id'] as int;
    final currentCash = (latestRecord.first['cash_on_hand'] as num).toDouble();

    final newCash = currentCash - amount;

    await database.update(
      'capital_management',
      {'cash_on_hand': newCash},
      where: 'id = ?',
      whereArgs: [recordId],
    );

    debugPrint(
      '>> Expense deducted: $amount | Remaining cash: ${totalCash - amount}',
    );
  }
}
