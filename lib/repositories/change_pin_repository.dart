import '../services/db_service.dart';
import '../services/audit_log_service.dart';

class ChangePinRepository {
  final DBService _db = DBService.instance;

  /// Returns the member row joined with its security question text.
  /// The result map includes all member columns plus `security_question`
  /// (the text from the security_questions table).
  Future<Map<String, dynamic>> getAccountByMobile(String mobile) async {
    final db = await _db.database;

    final result = await db.rawQuery(
      '''
      SELECT m.*, sq.question AS security_question
      FROM   slpa_member m
      LEFT JOIN security_questions sq
             ON sq.id = m.security_question_id
      WHERE  m.mobile_number = ?
      LIMIT  1
      ''',
      [mobile.trim()],
    );

    if (result.isEmpty) {
      throw Exception('Account not found');
    }

    return result.first;
  }

  Future<void> changePin({
    required String mobile,
    required String answer,
    required String oldPin,
    required String newPin,
  }) async {
    final db = await _db.database;
    final account = await getAccountByMobile(mobile);

    final storedAnswer = (account['security_answer'] ?? '').toString().trim();
    final storedPin = (account['pin'] ?? '').toString().trim();

    if (storedAnswer.toLowerCase() != answer.trim().toLowerCase()) {
      throw Exception('Incorrect security answer');
    }

    if (storedPin != oldPin.trim()) {
      throw Exception('Old PIN is incorrect');
    }

    if (oldPin.trim() == newPin.trim()) {
      throw Exception('New PIN must be different');
    }

    await db.update(
      'slpa_member',
      {'pin': newPin.trim()},
      where: 'id = ?',
      whereArgs: [account['id']],
    );

    await AuditLogService.instance.log(
      accountId: (account['account_id'] as num?)?.toInt(),
      memberId: (account['id'] as num?)?.toInt(),
      module: 'security',
      tableName: 'slpa_member',
      recordId: account['id']?.toString(),
      action: 'pin_change',
      oldValue: {'pin_changed': false},
      newValue: {'pin_changed': true},
    );
  }

  Future<void> updatePinById({
    required int memberId,
    required String newPin,
  }) async {
    final db = await _db.database;
    final updated = await db.update(
      'slpa_member',
      {'pin': newPin.trim()},
      where: 'id = ?',
      whereArgs: [memberId],
    );

    if (updated == 0) {
      throw Exception('Account not found');
    }

    await AuditLogService.instance.log(
      memberId: memberId,
      module: 'security',
      tableName: 'slpa_member',
      recordId: memberId.toString(),
      action: 'pin_change',
      oldValue: {'pin_changed': false},
      newValue: {'pin_changed': true},
    );
  }
}
