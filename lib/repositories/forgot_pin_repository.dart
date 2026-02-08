import 'package:sqflite/sqflite.dart';
import '../models/forgot_pin_model.dart';
import 'account_repository.dart';

class ForgotPinRepository {
  final Database db;
  final AccountRepository accountRepository;

  ForgotPinRepository(this.db) : accountRepository = AccountRepository();

  /// Fetch account by mobile number for current account
  Future<ForgotPinModel?> getAccountByMobileNumber(String mobileNumber) async {
    final accountId = await accountRepository.getAccountId();

    final List<Map<String, dynamic>> maps = await db.query(
      'account',
      columns: [
        'mobile_number',
        'security_question_id',
        'security_answer',
        'pin',
      ],
      where: 'mobile_number = ? AND account_id = ?',
      whereArgs: [mobileNumber.trim(), accountId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ForgotPinModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Update PIN for the current account and mobile number
  Future<void> updatePin(String mobileNumber, String newPin) async {
    final accountId = await accountRepository.getAccountId();

    await db.update(
      'account',
      {'pin': newPin.trim()},
      where: 'mobile_number = ? AND account_id = ?',
      whereArgs: [mobileNumber.trim(), accountId],
    );
  }
}
