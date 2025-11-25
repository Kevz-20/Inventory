import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account_model.dart';

class AccountRepository {
  final Database database;
  AccountRepository(this.database);

  // Get mobile number
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    debugPrint('⭐ [AccountRepository] getMobileNumber -> $mobile');
    if (mobile == null) {
      throw Exception('No mobile number stored in SharedPreferences');
    }
    return mobile;
  }

  // Get account ID
  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    debugPrint(
      '⭐ [AccountRepository] getAccountId -> mobileNumber: $mobileNumber',
    );

    final result = await database.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );
    debugPrint('⭐ [AccountRepository] getAccountId -> query result: $result');

    if (result.isEmpty) {
      throw Exception('No account found for mobile number $mobileNumber');
    }
    return result.first['id'] as int;
  }

  // Get account details
  Future<Account> getAccountDetails() async {
    final accountId = await getAccountId();
    debugPrint(
      '⭐ [AccountRepository] getAccountDetails -> accountId: $accountId',
    );

    final result = await database.query(
      'account',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    debugPrint(
      '⭐ [AccountRepository] getAccountDetails -> query result: $result',
    );

    if (result.isEmpty) {
      throw Exception('Account details not found for account ID $accountId');
    }
    final account = Account.fromMap(result.first);
    debugPrint(
      '⭐ [AccountRepository] getAccountDetails -> loaded account: ${account.toMap()}',
    );
    return account;
  }
}
