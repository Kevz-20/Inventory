import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account_model.dart';

class AccountRepository {
  final Database db;
  AccountRepository(this.db);

  // Turn on/off debug prints
  static bool debug = true;

  // Helper for conditional debug
  void _log(String message) {
    if (debug) debugPrint(message);
  }

  // Get mobile number from SharedPreferences
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final mobileNumber = prefs.getString('mobileNumber');
    _log('⭐ [AccountRepository] Stored mobileNumber: $mobileNumber');
    return mobileNumber;
  }

  // Get account ID from DB using mobile number
  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    if (mobileNumber == null) {
      _log(
        '⭐ [AccountRepository] No mobile number found in SharedPreferences!',
      );
      throw Exception('Account not found');
    }

    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    _log(
      '⭐ [AccountRepository] DB query result for mobileNumber $mobileNumber: $result',
    );

    if (result.isEmpty) {
      _log(
        '⭐ [AccountRepository] No account found in DB for mobileNumber $mobileNumber',
      );
      throw Exception('Account not found');
    }

    final accountId = result.first['id'] as int;
    _log('⭐ [AccountRepository] Found accountId: $accountId');
    return accountId;
  }

  // Get full account details
  Future<Account> getAccountDetails() async {
    final accountId = await getAccountId();

    final result = await db.query(
      'account',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    _log(
      '⭐ [AccountRepository] DB query result for accountId $accountId: $result',
    );

    if (result.isEmpty) {
      _log(
        '⭐ [AccountRepository] No account details found for accountId $accountId',
      );
      throw Exception('Account not found');
    }

    final account = Account.fromMap(result.first);
    _log('⭐ [AccountRepository] Fetched account details: ${account.toMap()}');
    return account;
  }
}
