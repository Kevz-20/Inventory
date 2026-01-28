import '../services/db_service.dart';

class ChangePinRepository {
  final DBService _db = DBService.instance;

  Future<Map<String, dynamic>> getAccountByMobile(String mobile) async {
    final db = await _db.database;

    final result = await db.query(
      'account',
      where: 'mobile_number = ?',
      whereArgs: [mobile.trim()],
      limit: 1,
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
}
 