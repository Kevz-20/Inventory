import '../services/db_service.dart';

class ChangePinRepository {
  final DBService _db = DBService.instance;

  /// Returns the account row joined with its security question text.
  /// The result map includes all account columns plus `security_question`
  /// (the text from the security_questions table).
  Future<Map<String, dynamic>> getAccountByMobile(String mobile) async {
    final db = await _db.database;

    // Raw query so we can join security_questions and surface the
    // question text in a single round-trip.
    final result = await db.rawQuery(
      '''
      SELECT a.*, sq.question AS security_question
      FROM   account a
      LEFT JOIN security_questions sq
             ON sq.id = a.security_question_id
      WHERE  a.mobile_number = ?
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
      'account',
      {'pin': newPin.trim()},
      where: 'id = ?',
      whereArgs: [account['id']],
    );
  }

  Future<void> updatePinById({
    required int accountId,
    required String newPin,
  }) async {
    final db = await _db.database;
    final updated = await db.update(
      'account',
      {'pin': newPin.trim()},
      where: 'id = ?',
      whereArgs: [accountId],
    );

    if (updated == 0) {
      throw Exception('Account not found');
    }
  }
}