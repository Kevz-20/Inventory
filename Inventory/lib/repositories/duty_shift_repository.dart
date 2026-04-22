import 'package:sqflite/sqflite.dart';

import '../models/duty_shift_model.dart';

class DutyShiftRepository {
  final Database db;
  DutyShiftRepository(this.db);

  Future<DutyShift?> getActiveShift(int accountId) async {
    final rows = await db.rawQuery('''
      SELECT * FROM member_duty_log
      WHERE account_id = ? AND ended_at IS NULL AND is_deleted = 0
      ORDER BY started_at DESC LIMIT 1
    ''', [accountId]);
    if (rows.isEmpty) return null;
    return DutyShift.fromMap(rows.first);
  }

  Future<int> startShift({
    required int memberId,
    required int accountId,
    required String memberName,
  }) async {
    final now = DateTime.now().toIso8601String();
    // Close any currently open shift for this account
    await db.rawUpdate('''
      UPDATE member_duty_log
      SET ended_at = ?, updated_at = ?, sync_status = 'pending'
      WHERE account_id = ? AND ended_at IS NULL AND is_deleted = 0
    ''', [now, now, accountId]);

    return await db.insert('member_duty_log', {
      'account_id': accountId,
      'member_id': memberId,
      'member_name': memberName,
      'started_at': now,
      'ended_at': null,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
      'is_deleted': 0,
    });
  }

  Future<void> endShift(int shiftId) async {
    final now = DateTime.now().toIso8601String();
    await db.update(
      'member_duty_log',
      {'ended_at': now, 'updated_at': now, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }

  Future<List<DutyShift>> getHistory(int accountId, {int limit = 60}) async {
    final rows = await db.rawQuery('''
      SELECT * FROM member_duty_log
      WHERE account_id = ? AND is_deleted = 0
      ORDER BY started_at DESC
      LIMIT ?
    ''', [accountId, limit]);
    return rows.map(DutyShift.fromMap).toList();
  }
}
