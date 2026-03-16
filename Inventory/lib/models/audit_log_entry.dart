import 'dart:convert';

class AuditLogEntry {
  final int id;
  final int? accountId;
  final int? memberId;
  final String? memberName;
  final String module;
  final String? tableName;
  final String? recordId;
  final String action;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    required this.accountId,
    required this.memberId,
    required this.memberName,
    required this.module,
    required this.tableName,
    required this.recordId,
    required this.action,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: (map['id'] as num).toInt(),
      accountId: (map['account_id'] as num?)?.toInt(),
      memberId: (map['member_id'] as num?)?.toInt(),
      memberName: map['member_name']?.toString(),
      module: map['module']?.toString() ?? '',
      tableName: map['table_name']?.toString(),
      recordId: map['record_id']?.toString(),
      action: map['action']?.toString() ?? '',
      oldValue: _decodeJsonMap(map['old_value']),
      newValue: _decodeJsonMap(map['new_value']),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static Map<String, dynamic>? _decodeJsonMap(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      return {'value': text};
    }

    return null;
  }
}
