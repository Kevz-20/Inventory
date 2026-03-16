import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'db_service.dart';

class AuditLogService {
  AuditLogService._();

  static final AuditLogService instance = AuditLogService._();

  Future<void> log({
    int? accountId,
    int? memberId,
    String? memberName,
    required String module,
    String? tableName,
    String? recordId,
    required String action,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    final db = await DBService.instance.database;
    final actor = await _resolveActor();

    await db.insert('audit_log', {
      'account_id': accountId ?? actor.accountId,
      'member_id': memberId ?? actor.memberId,
      'member_name': memberName ?? actor.memberName,
      'module': module,
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'old_value': oldValue == null ? null : jsonEncode(_normalize(oldValue)),
      'new_value': newValue == null ? null : jsonEncode(_normalize(newValue)),
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
      'last_synced_at': null,
    });
  }

  Future<({int? accountId, int? memberId, String? memberName})>
      _resolveActor() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    if (mobile == null || mobile.trim().isEmpty) {
      return (
        accountId: null,
        memberId: null,
        memberName: prefs.getString('fullName'),
      );
    }

    final db = await DBService.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        m.id AS member_id,
        m.account_id,
        m.first_name,
        m.middle_name,
        m.last_name
      FROM slpa_member m
      WHERE m.mobile_number = ?
      LIMIT 1
      ''',
      [mobile.trim()],
    );

    if (rows.isEmpty) {
      return (
        accountId: null,
        memberId: null,
        memberName: prefs.getString('fullName'),
      );
    }

    final row = rows.first;
    final fullName = [
      (row['first_name'] ?? '').toString(),
      (row['middle_name'] ?? '').toString(),
      (row['last_name'] ?? '').toString(),
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return (
      accountId: (row['account_id'] as num?)?.toInt(),
      memberId: (row['member_id'] as num?)?.toInt(),
      memberName: fullName.isEmpty ? prefs.getString('fullName') : fullName,
    );
  }

  Object? _normalize(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _normalize(item)),
      );
    }
    if (value is Iterable) {
      return value.map(_normalize).toList();
    }
    return value.toString();
  }
}
