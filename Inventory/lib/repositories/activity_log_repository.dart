import 'package:shared_preferences/shared_preferences.dart';

import '../models/audit_log_entry.dart';
import '../services/db_service.dart';

class ActivityLogRepository {
  Future<List<AuditLogEntry>> getLogs({String? module}) async {
    final db = await DBService.instance.database;
    final accountId = await _resolveCurrentAccountId();

    final where = <String>[];
    final args = <Object?>[];

    if (accountId != null) {
      where.add('account_id = ?');
      args.add(accountId);
    }

    if (module != null && module.isNotEmpty) {
      where.add('module = ?');
      args.add(module);
    }

    final rows = await db.query(
      'audit_log',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC, id DESC',
    );

    return rows.map(AuditLogEntry.fromMap).toList();
  }

  Future<int?> _resolveCurrentAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    if (mobile == null || mobile.trim().isEmpty) return null;

    final db = await DBService.instance.database;
    final rows = await db.query(
      'slpa_member',
      columns: ['account_id'],
      where: 'mobile_number = ?',
      whereArgs: [mobile.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return (rows.first['account_id'] as num?)?.toInt();
  }
}
