import 'package:sqflite/sqflite.dart';
import '../models/forgot_pin_model.dart';
import '../services/audit_log_service.dart';

class ForgotPinRepository {
  final Database db;

  ForgotPinRepository(this.db);

  /// Fetch account by mobile number (mobile_number is UNIQUE)
  Future<ForgotPinModel?> getAccountByMobileNumber(String mobileNumber) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'slpa_member',
      columns: [
        'mobile_number',
        'security_question_id',
        'security_answer',
        'pin',
      ],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber.trim()],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ForgotPinModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Update PIN by mobile number
  Future<void> updatePin(String mobileNumber, String newPin) async {
    final updated = await db.update(
      'slpa_member',
      {'pin': newPin.trim()},
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber.trim()],
    );

    if (updated == 0) {
      throw Exception('Account not found');
    }

    await AuditLogService.instance.log(
      module: 'security',
      tableName: 'slpa_member',
      recordId: mobileNumber.trim(),
      action: 'pin_reset',
      oldValue: {'pin_changed': false},
      newValue: {'pin_changed': true},
    );
  }
}
