import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account_model.dart';

class AccountRepository {
  final Database db;
  AccountRepository(this.db);

  // Get mobile number
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final mobileNumber = prefs.getString('mobileNumber');
    debugPrint('⭐ Stored mobile number: $mobileNumber');
    return mobileNumber;
  }

  // Get account ID
  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    debugPrint('⭐ Stored mobile number: $mobileNumber');
    if (mobileNumber == null) throw Exception('Account not found');
    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );
    if (result.isEmpty) throw Exception('Account not found');
    return result.first['id'] as int;
  }

  // Get account details
  Future<Account> getAccountDetails() async {
    final accountId = await getAccountId();
    final result = await db.query(
      'account',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (result.isEmpty) throw Exception('Account not found');
    return Account.fromMap(result.first);
  }
}
