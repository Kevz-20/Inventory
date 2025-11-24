import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account_model.dart';

class AccountRepository {
  final Database db;
  AccountRepository(this.db);

  int? cachedAccountId;
  int? cachedMobileNumber;

  // Get mobile number
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber');
  }

  // Get account id
  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    if (mobileNumber == null) throw Exception('Account not found');

    if (cachedAccountId != null &&
        cachedMobileNumber != mobileNumber.hashCode) {
      cachedAccountId = null;
    }

    if (cachedAccountId != null) return cachedAccountId!;

    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (result.isEmpty) throw Exception('Account not found');

    cachedAccountId = result.first['id'] as int;
    cachedMobileNumber = mobileNumber.hashCode;
    return cachedAccountId!;
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
