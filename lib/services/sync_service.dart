import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class SyncTableConfig {
  const SyncTableConfig({
    required this.tableName,
    this.orderBy = 'id ASC',
  });

  final String tableName;
  final String orderBy;
}

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  static const List<SyncTableConfig> _tables = [
    SyncTableConfig(tableName: 'account'),
    SyncTableConfig(tableName: 'slpa_member'),
    SyncTableConfig(tableName: 'audit_log', orderBy: 'created_at ASC, id ASC'),
    SyncTableConfig(tableName: 'product'),
    SyncTableConfig(tableName: 'customer'),
    SyncTableConfig(tableName: 'expenses'),
    SyncTableConfig(tableName: 'payable'),
    SyncTableConfig(tableName: 'capital_management'),
    SyncTableConfig(tableName: 'fixed_asset'),
    SyncTableConfig(tableName: 'sales', orderBy: 'created_at ASC, id ASC'),
    SyncTableConfig(tableName: 'stock_in', orderBy: 'created_at ASC, id ASC'),
  ];

  Future<Map<String, dynamic>> buildPendingPayload() async {
    final db = await DBService.instance.database;
    final generatedAt = DateTime.now().toIso8601String();
    final payload = <String, dynamic>{
      'generated_at': generatedAt,
      'tables': <String, List<Map<String, dynamic>>>{},
      'counts': <String, int>{},
      'total_records': 0,
    };

    int totalRecords = 0;
    final tablePayload =
        payload['tables'] as Map<String, List<Map<String, dynamic>>>;
    final counts = payload['counts'] as Map<String, int>;

    for (final config in _tables) {
      final rows = await _loadPendingRows(db, config);
      final normalized = rows.map(_normalizeRow).toList();
      tablePayload[config.tableName] = normalized;
      counts[config.tableName] = normalized.length;
      totalRecords += normalized.length;
    }

    payload['total_records'] = totalRecords;
    return payload;
  }

  Future<Map<String, int>> getPendingCounts() async {
    final db = await DBService.instance.database;
    final result = <String, int>{};

    for (final config in _tables) {
      final rows = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM ${config.tableName}
        WHERE sync_status = ?
        ''',
        ['pending'],
      );
      result[config.tableName] = (rows.first['count'] as num?)?.toInt() ?? 0;
    }

    return result;
  }

  Future<void> markRowsSynced(
    String tableName,
    List<int> localIds, {
    Map<int, String>? serverIds,
  }) async {
    if (localIds.isEmpty) return;

    final db = await DBService.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final localId in localIds) {
        final data = <String, Object?>{
          'sync_status': 'synced',
          'last_synced_at': now,
        };

        final serverId = serverIds?[localId];
        if (serverId != null && serverId.trim().isNotEmpty) {
          data['server_id'] = serverId.trim();
        }

        await txn.update(
          tableName,
          data,
          where: 'id = ?',
          whereArgs: [localId],
        );
      }
    });
  }

  Future<void> markPayloadSynced(
    Map<String, List<int>> syncedIdsByTable, {
    Map<String, Map<int, String>>? serverIdsByTable,
  }) async {
    for (final entry in syncedIdsByTable.entries) {
      await markRowsSynced(
        entry.key,
        entry.value,
        serverIds: serverIdsByTable?[entry.key],
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadPendingRows(
    Database db,
    SyncTableConfig config,
  ) async {
    final rows = await db.query(
      config.tableName,
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: config.orderBy,
    );

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value is Uint8List) {
        return MapEntry(key, value.toList());
      }
      return MapEntry(key, value);
    });
  }
}
