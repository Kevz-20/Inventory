import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../services/db_service.dart';

class AccountRepository {
  final dbService = DBService.instance;

  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    if (mobile == null) {
      throw Exception('No mobile number stored in SharedPreferences');
    }
    return mobile;
  }

  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    final db = await dbService.database;
    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No account found for mobile number $mobileNumber');
    }
    return result.first['id'] as int;
  }

  Future<Account> getAccountDetails() async {
    final accountId = await getAccountId();
    final db = await dbService.database;
    final result = await db.query(
      'account',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('Account details not found for account ID $accountId');
    }
    return Account.fromMap(result.first);
  }

  Future<String?> getAssociationName() async {
    final mobileNumber = await getMobileNumber();
    final db = await dbService.database;
    final result = await db.query(
      'account',
      columns: ['association_name'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['association_name'] as String?;
    }
    return null;
  }

  Future<void> updateAccount(Account updated) async {
    final db = await dbService.database;

    // Correct SQLite update
    await db.update(
      'account',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );

    // Optional: save mobile number to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', updated.mobileNumber);

    if (updated.associationName != null) {
      await prefs.setString('associationName', updated.associationName!);
    }
    if (updated.securityAnswer != null) {
      await prefs.setString('securityAnswer', updated.securityAnswer!);
    }
  }
}
