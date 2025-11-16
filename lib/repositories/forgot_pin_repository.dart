import 'package:sqflite/sqflite.dart';
import '../models/forgot_pin_model.dart';

class ForgotPinRepository {
  final Database db;

  ForgotPinRepository(this.db);

  Future<ForgotPinModel?> getAccountByMobileNumber(String mobileNumber) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'account',
      columns: [
        'mobile_number',
        'security_question_id',
        'security_answer',
        'pin',
      ],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
    );

    if (maps.isNotEmpty) {
      return ForgotPinModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> updatePin(String mobileNumber, String newPin) async {
    await db.update(
      'account',
      {'pin': newPin},
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
    );
  }
}
