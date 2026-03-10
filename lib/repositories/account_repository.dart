import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../services/db_service.dart';

class AccountRepository {
  final dbService = DBService.instance;

  /// Get current logged-in mobile number from SharedPreferences
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    if (mobile == null) {
      throw Exception('No mobile number stored in SharedPreferences');
    }
    return mobile;
  }

  /// Get current account ID by mobile number
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

    final result = await db.rawQuery(
      '''
      SELECT a.*, sq.question AS security_question
      FROM   account a
      LEFT JOIN security_questions sq
             ON sq.id = a.security_question_id
      WHERE  a.id = ?
      LIMIT  1
      ''',
      [accountId],
    );

    if (result.isEmpty) {
      throw Exception('Account details not found for account ID $accountId');
    }
    return Account.fromMap(result.first);
  }

  /// Get the full name of the current user (First + Middle + Last)
  Future<String> getFullName() async {
    final account = await getAccountDetails();
    final middle = account.middleName != null && account.middleName!.isNotEmpty
        ? ' ${account.middleName}'
        : '';
    return '${account.firstName}$middle ${account.lastName}';
  }

  Future<Map<String, String>> getNameParts() async {
    final fullName = await getFullName();
    final parts = fullName.split(' ');
    return {
      'first': parts.isNotEmpty ? parts[0] : '',
      'middle': parts.length == 3 ? parts[1] : '',
      'last': parts.length >= 2 ? parts.last : '',
    };
  }

  /// Update account info and save mobile number + full name to SharedPreferences
  Future<void> updateAccount(Account updated) async {
    final db = await dbService.database;

    // Update account table (toMap() excludes security_question — safe to use)
    await db.update(
      'account',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );

    // Save current mobile number
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', updated.mobileNumber);

    // Save full name for creator tracking
    final fullNameParts = [
      updated.firstName,
      if ((updated.middleName ?? '').isNotEmpty) updated.middleName!,
      updated.lastName,
    ];
    await prefs.setString('fullName', fullNameParts.join(' '));
  }
}