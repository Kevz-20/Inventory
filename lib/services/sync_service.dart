import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';
import 'supabase_service.dart';

class SyncQueueSummary {
  final int pendingCount;
  final int failedCount;
  final int completedCount;

  const SyncQueueSummary({
    this.pendingCount = 0,
    this.failedCount = 0,
    this.completedCount = 0,
  });
}

class SyncRecordDiagnostics {
  final String entityType;
  final int localId;
  final String? localUuid;
  final String? serverId;
  final String syncStatus;
  final String? lastSyncedAt;
  final String? updatedAt;
  final String title;
  final String? subtitle;
  final String? lastQueueError;
  final int retryCount;
  final String? queueUpdatedAt;

  const SyncRecordDiagnostics({
    required this.entityType,
    required this.localId,
    required this.localUuid,
    required this.serverId,
    required this.syncStatus,
    required this.lastSyncedAt,
    required this.updatedAt,
    required this.title,
    required this.subtitle,
    required this.lastQueueError,
    required this.retryCount,
    required this.queueUpdatedAt,
  });
}

class AuditLogEntry {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String? deviceId;
  final DateTime? occurredAt;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;

  const AuditLogEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.deviceId,
    required this.occurredAt,
    required this.oldValues,
    required this.newValues,
  });
}

class SyncConflictException implements Exception {
  final String message;

  const SyncConflictException(this.message);

  @override
  String toString() => message;
}

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();
  bool _isProcessing = false;

  Future<Database> get _db async => DBService.instance.database;

  Future<String?> _selectedOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedOrganizationId');
  }

  Future<String?> _currentBackendUserId() async {
    return SupabaseService.client.auth.currentUser?.id;
  }

  Future<int> enqueueUpsert({
    required String entityType,
    required String localUuid,
    Map<String, dynamic>? payload,
  }) async {
    return _enqueue(
      entityType: entityType,
      operation: 'upsert',
      localUuid: localUuid,
      organizationId: await _selectedOrganizationId(),
      payload: payload,
    );
  }

  Future<int> enqueueDelete({
    required String entityType,
    required String localUuid,
    Map<String, dynamic>? payload,
  }) async {
    return _enqueue(
      entityType: entityType,
      operation: 'delete',
      localUuid: localUuid,
      organizationId: await _selectedOrganizationId(),
      payload: payload,
    );
  }

  Future<int> _enqueue({
    required String entityType,
    required String operation,
    required String localUuid,
    required String? organizationId,
    Map<String, dynamic>? payload,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final payloadJson = payload == null ? null : jsonEncode(payload);

    final existing = await db.query(
      'sync_queue',
      columns: ['id', 'retry_count'],
      where:
          'entity_type = ? AND operation = ? AND local_uuid = ? AND '
          'COALESCE(organization_id, \'\') = COALESCE(?, \'\') AND status IN (?, ?)',
      whereArgs: [
        entityType,
        operation,
        localUuid,
        organizationId,
        'pending',
        'failed',
      ],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return db.update(
        'sync_queue',
        {
          'payload': payloadJson,
          'organization_id': organizationId,
          'status': 'pending',
          'scheduled_at': now,
          'updated_at': now,
          'last_error': null,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }

    return db.insert('sync_queue', {
      'organization_id': organizationId,
      'entity_type': entityType,
      'operation': operation,
      'local_uuid': localUuid,
      'payload': payloadJson,
      'status': 'pending',
      'retry_count': 0,
      'scheduled_at': now,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingJobs({int limit = 100}) async {
    final db = await _db;
    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) {
      return const [];
    }

    return db.query(
      'sync_queue',
      where: 'status = ? AND organization_id = ?',
      whereArgs: ['pending', organizationId],
      orderBy: 'scheduled_at ASC, id ASC',
      limit: limit,
    );
  }

  Future<SyncQueueSummary> getQueueSummary() async {
    final db = await _db;
    final organizationId = await _selectedOrganizationId();

    if (organizationId == null || organizationId.isEmpty) {
      return const SyncQueueSummary();
    }

    Future<int> countByStatus(String status) async {
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM sync_queue
        WHERE status = ? AND organization_id = ?
        ''',
        [status, organizationId],
      );
      return (result.first['count'] as num?)?.toInt() ?? 0;
    }

    final pendingCount = await countByStatus('pending');
    final failedCount = await countByStatus('failed');
    final completedCount = await countByStatus('completed');

    return SyncQueueSummary(
      pendingCount: pendingCount,
      failedCount: failedCount,
      completedCount: completedCount,
    );
  }

  Future<List<Map<String, dynamic>>> getQueueJobs({
    List<String>? statuses,
    int limit = 100,
  }) async {
    final db = await _db;
    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) {
      return const [];
    }

    if (statuses == null || statuses.isEmpty) {
      return db.query(
        'sync_queue',
        where: 'organization_id = ?',
        whereArgs: [organizationId],
        orderBy: 'updated_at DESC, id DESC',
        limit: limit,
      );
    }

    final placeholders = List.filled(statuses.length, '?').join(', ');
    return db.rawQuery(
      '''
      SELECT *
      FROM sync_queue
      WHERE organization_id = ? AND status IN ($placeholders)
      ORDER BY updated_at DESC, id DESC
      LIMIT ?
      ''',
      [organizationId, ...statuses, limit],
    );
  }

  Future<List<AuditLogEntry>> getAuditLogEntries({
    int limit = 100,
    String? organizationId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const [];
    }

    final resolvedOrganizationId =
        organizationId ?? await _selectedOrganizationId();
    if (resolvedOrganizationId == null || resolvedOrganizationId.isEmpty) {
      return const [];
    }

    final rows = await SupabaseService.client
        .from('audit_logs')
        .select(
          'id, entity_type, entity_id, action, device_id, occurred_at, '
          'old_values_json, new_values_json',
        )
        .eq('organization_id', resolvedOrganizationId)
        .order('occurred_at', ascending: false)
        .limit(limit);

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      return AuditLogEntry(
        id: _asText(map['id']),
        entityType: _asText(map['entity_type']),
        entityId: _asText(map['entity_id']),
        action: _asText(map['action']),
        deviceId: _asText(map['device_id']).isEmpty
            ? null
            : _asText(map['device_id']),
        occurredAt: _parseTimestamp(map['occurred_at']),
        oldValues: map['old_values_json'] is Map
            ? Map<String, dynamic>.from(map['old_values_json'] as Map)
            : null,
        newValues: map['new_values_json'] is Map
            ? Map<String, dynamic>.from(map['new_values_json'] as Map)
            : null,
      );
    }).toList();
  }

  Future<List<SyncRecordDiagnostics>> getRecordDiagnostics(
    String entityType, {
    int limit = 100,
  }) async {
    final db = await _db;
    final organizationId = await _selectedOrganizationId();

    Future<Map<String, dynamic>?> latestQueueFailure(
      String queueEntityType,
      String? localUuid,
    ) async {
      if (organizationId == null ||
          organizationId.isEmpty ||
          localUuid == null ||
          localUuid.isEmpty) {
        return null;
      }

      final rows = await db.query(
        'sync_queue',
        columns: ['last_error', 'retry_count', 'updated_at'],
        where:
            'organization_id = ? AND entity_type = ? AND local_uuid = ? AND status = ?',
        whereArgs: [organizationId, queueEntityType, localUuid, 'failed'],
        orderBy: 'updated_at DESC, id DESC',
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return rows.first;
    }

    switch (entityType) {
      case 'product':
        final rows = await db.query(
          'product',
          columns: [
            'id',
            'local_uuid',
            'server_id',
            'sync_status',
            'last_synced_at',
            'updated_at',
            'name',
            'quantity',
          ],
          orderBy: 'updated_at DESC, id DESC',
          limit: limit,
        );
        return Future.wait(
          rows.map((row) async {
            final failure = await latestQueueFailure(
              'product',
              row['local_uuid']?.toString(),
            );
            return SyncRecordDiagnostics(
                entityType: entityType,
                localId: (row['id'] as num?)?.toInt() ?? 0,
                localUuid: row['local_uuid']?.toString(),
                serverId: row['server_id']?.toString(),
                syncStatus: _asText(row['sync_status']).isEmpty
                    ? 'local_only'
                    : _asText(row['sync_status']),
                lastSyncedAt: row['last_synced_at']?.toString(),
                updatedAt: row['updated_at']?.toString(),
                title: _asText(row['name']).isEmpty
                    ? 'Unnamed product'
                    : _asText(row['name']),
                subtitle: 'Quantity: ${row['quantity'] ?? 0}',
                lastQueueError: failure?['last_error']?.toString(),
                retryCount: (failure?['retry_count'] as num?)?.toInt() ?? 0,
                queueUpdatedAt: failure?['updated_at']?.toString(),
              );
          }),
        );
      case 'customer':
        final rows = await db.query(
          'customer',
          columns: [
            'id',
            'local_uuid',
            'server_id',
            'sync_status',
            'last_synced_at',
            'updated_at',
            'first_name',
            'middle_name',
            'last_name',
            'phone_number',
          ],
          orderBy: 'updated_at DESC, id DESC',
          limit: limit,
        );
        return Future.wait(
          rows.map((row) async {
            final failure = await latestQueueFailure(
              'customer',
              row['local_uuid']?.toString(),
            );
            return SyncRecordDiagnostics(
                entityType: entityType,
                localId: (row['id'] as num?)?.toInt() ?? 0,
                localUuid: row['local_uuid']?.toString(),
                serverId: row['server_id']?.toString(),
                syncStatus: _asText(row['sync_status']).isEmpty
                    ? 'local_only'
                    : _asText(row['sync_status']),
                lastSyncedAt: row['last_synced_at']?.toString(),
                updatedAt: row['updated_at']?.toString(),
                title: [
                  _asText(row['first_name']),
                  _asText(row['middle_name']),
                  _asText(row['last_name']),
                ].where((part) => part.isNotEmpty).join(' '),
                subtitle: _asText(row['phone_number']).isEmpty
                    ? null
                    : _asText(row['phone_number']),
                lastQueueError: failure?['last_error']?.toString(),
                retryCount: (failure?['retry_count'] as num?)?.toInt() ?? 0,
                queueUpdatedAt: failure?['updated_at']?.toString(),
              );
          }),
        );
      case 'sales':
        final rows = await db.query(
          'sales',
          columns: [
            'id',
            'local_uuid',
            'server_id',
            'sync_status',
            'last_synced_at',
            'created_at',
            'sale_type',
            'total',
          ],
          orderBy: 'created_at DESC, id DESC',
          limit: limit,
        );
        return Future.wait(
          rows.map((row) async {
            final failure = await latestQueueFailure(
              'sales',
              row['local_uuid']?.toString(),
            );
            return SyncRecordDiagnostics(
                entityType: entityType,
                localId: (row['id'] as num?)?.toInt() ?? 0,
                localUuid: row['local_uuid']?.toString(),
                serverId: row['server_id']?.toString(),
                syncStatus: _asText(row['sync_status']).isEmpty
                    ? 'local_only'
                    : _asText(row['sync_status']),
                lastSyncedAt: row['last_synced_at']?.toString(),
                updatedAt: row['created_at']?.toString(),
                title:
                    '${_asText(row['sale_type']).isEmpty ? 'sale' : _asText(row['sale_type'])} sale',
                subtitle: 'Total: ${row['total'] ?? 0}',
                lastQueueError: failure?['last_error']?.toString(),
                retryCount: (failure?['retry_count'] as num?)?.toInt() ?? 0,
                queueUpdatedAt: failure?['updated_at']?.toString(),
              );
          }),
        );
      case 'receivables':
        final rows = await db.query(
          'sales_credit',
          columns: [
            'id',
            'local_uuid',
            'server_id',
            'sync_status',
            'last_synced_at',
            'created_at',
            'credit_date',
            'amount',
            'due_date',
          ],
          orderBy: 'created_at DESC, id DESC',
          limit: limit,
        );
        return Future.wait(
          rows.map((row) async {
            final failure = await latestQueueFailure(
              'sales',
              row['local_uuid']?.toString(),
            );
            return SyncRecordDiagnostics(
                entityType: entityType,
                localId: (row['id'] as num?)?.toInt() ?? 0,
                localUuid: row['local_uuid']?.toString(),
                serverId: row['server_id']?.toString(),
                syncStatus: _asText(row['sync_status']).isEmpty
                    ? 'local_only'
                    : _asText(row['sync_status']),
                lastSyncedAt: row['last_synced_at']?.toString(),
                updatedAt: row['credit_date']?.toString() ?? row['created_at']?.toString(),
                title: 'Receivable',
                subtitle:
                    'Amount: ${row['amount'] ?? 0} • Due: ${_asText(row['due_date']).isEmpty ? 'n/a' : _asText(row['due_date'])}',
                lastQueueError: failure?['last_error']?.toString(),
                retryCount: (failure?['retry_count'] as num?)?.toInt() ?? 0,
                queueUpdatedAt: failure?['updated_at']?.toString(),
              );
          }),
        );
      case 'payments':
        final rows = await db.query(
          'customer_payment',
          columns: [
            'id',
            'local_uuid',
            'server_id',
            'sync_status',
            'last_synced_at',
            'paid_at',
            'amount',
          ],
          orderBy: 'paid_at DESC, id DESC',
          limit: limit,
        );
        return Future.wait(
          rows.map((row) async {
            final failure = await latestQueueFailure(
              'customer_payment',
              row['local_uuid']?.toString(),
            );
            return SyncRecordDiagnostics(
                entityType: entityType,
                localId: (row['id'] as num?)?.toInt() ?? 0,
                localUuid: row['local_uuid']?.toString(),
                serverId: row['server_id']?.toString(),
                syncStatus: _asText(row['sync_status']).isEmpty
                    ? 'local_only'
                    : _asText(row['sync_status']),
                lastSyncedAt: row['last_synced_at']?.toString(),
                updatedAt: row['paid_at']?.toString(),
                title: 'Customer payment',
                subtitle: 'Amount: ${row['amount'] ?? 0}',
                lastQueueError: failure?['last_error']?.toString(),
                retryCount: (failure?['retry_count'] as num?)?.toInt() ?? 0,
                queueUpdatedAt: failure?['updated_at']?.toString(),
              );
          }),
        );
      default:
        return const [];
    }
  }

  Future<void> resyncRecord({
    required String entityType,
    required String localUuid,
  }) async {
    if (localUuid.isEmpty) {
      return;
    }

    final normalizedEntityType = switch (entityType) {
      'product' => 'product',
      'customer' => 'customer',
      'sales' => 'sales',
      'receivables' => 'sales',
      'payments' => 'customer_payment',
      _ => entityType,
    };

    await enqueueUpsert(
      entityType: normalizedEntityType,
      localUuid: localUuid,
    );
  }

  Future<void> requeueJob(int id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final organizationId = await _selectedOrganizationId();
    await db.update(
      'sync_queue',
      {
        'organization_id': organizationId,
        'status': 'pending',
        'scheduled_at': now,
        'updated_at': now,
        'last_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> requeueJobWithForceOverwrite(int id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final organizationId = await _selectedOrganizationId();
    final rows = await db.query(
      'sync_queue',
      columns: ['payload'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }

    final payload = _decodePayload(rows.first['payload']) ?? <String, dynamic>{};
    payload['force_overwrite'] = true;

    await db.update(
      'sync_queue',
      {
        'organization_id': organizationId,
        'payload': jsonEncode(payload),
        'status': 'pending',
        'scheduled_at': now,
        'updated_at': now,
        'last_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> retryFailedJobs() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) {
      return;
    }
    await db.rawUpdate(
      '''
      UPDATE sync_queue
      SET organization_id = COALESCE(organization_id, ?),
          status = ?,
          scheduled_at = ?,
          updated_at = ?,
          last_error = NULL
      WHERE status = ? AND COALESCE(organization_id, ?) = ?
      ''',
      [organizationId, 'pending', now, now, 'failed', organizationId, organizationId],
    );
    await processPendingJobs();
  }

  Future<void> markJobCompleted(int id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'sync_queue',
      {
        'status': 'completed',
        'processed_at': now,
        'updated_at': now,
        'last_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markJobFailed(int id, Object error) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate(
      '''
      UPDATE sync_queue
      SET status = ?,
          retry_count = retry_count + 1,
          last_error = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      ['failed', error.toString(), now, id],
    );
  }

  Future<void> processPendingJobs({int limit = 100}) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    final organizationId = await _selectedOrganizationId();
    final userId = await _currentBackendUserId();
    if (organizationId == null ||
        organizationId.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return;
    }

    final jobs = await getPendingJobs(limit: limit);
    for (final job in jobs) {
      final jobId = job['id'] as int;
      try {
        final jobOrganizationId = (job['organization_id'] ?? '').toString();
        if (jobOrganizationId.isEmpty || jobOrganizationId != organizationId) {
          throw StateError(
            'Sync job organization mismatch. Expected $organizationId, found $jobOrganizationId.',
          );
        }
        await _processJob(job, organizationId: organizationId, userId: userId);
        await markJobCompleted(jobId);
      } catch (error) {
        await markJobFailed(jobId, error);
      }
    }
  }

  Future<void> triggerBackgroundSync({int limit = 100}) async {
    if (!SupabaseService.isConfigured || _isProcessing) {
      return;
    }

    _isProcessing = true;
    try {
      await processPendingJobs(limit: limit);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processJob(
    Map<String, dynamic> job, {
    required String organizationId,
    required String userId,
  }) async {
    final entityType = (job['entity_type'] ?? '').toString();
    final operation = (job['operation'] ?? '').toString();
    final localUuid = (job['local_uuid'] ?? '').toString();
    final payload = _decodePayload(job['payload']);

    switch ('$entityType:$operation') {
      case 'product:upsert':
        await _processProductUpsert(
          localUuid,
          organizationId: organizationId,
          userId: userId,
          forceOverwrite: _forceOverwrite(payload),
        );
        return;
      case 'product:delete':
        await _processProductDelete(
          localUuid,
          payload: payload,
          organizationId: organizationId,
        );
        return;
      case 'customer:upsert':
        await _processCustomerUpsert(
          localUuid,
          organizationId: organizationId,
          userId: userId,
          forceOverwrite: _forceOverwrite(payload),
        );
        return;
      case 'customer:delete':
        await _processCustomerDelete(
          localUuid,
          payload: payload,
          organizationId: organizationId,
        );
        return;
      case 'sales:upsert':
        await _processSaleUpsert(
          localUuid,
          organizationId: organizationId,
          userId: userId,
          forceOverwrite: _forceOverwrite(payload),
        );
        return;
      case 'customer_payment:upsert':
        await _processCustomerPaymentUpsert(
          localUuid,
          organizationId: organizationId,
          userId: userId,
          forceOverwrite: _forceOverwrite(payload),
        );
        return;
      default:
        throw UnsupportedError(
          'Unsupported sync job: $entityType/$operation',
        );
    }
  }

  Map<String, dynamic>? _decodePayload(Object? rawPayload) {
    if (rawPayload == null) return null;
    if (rawPayload is Map<String, dynamic>) return rawPayload;
    if (rawPayload is String && rawPayload.isNotEmpty) {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }

  bool _forceOverwrite(Map<String, dynamic>? payload) {
    return payload?['force_overwrite'] == true;
  }

  DateTime? _parseTimestamp(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  String _asText(Object? raw) {
    return raw?.toString().trim() ?? '';
  }

  Future<Map<String, dynamic>?> _findByExternalLocalUuid({
    required String table,
    required String localUuid,
    String? organizationId,
    String columns = 'id, updated_at',
  }) async {
    if (localUuid.isEmpty) {
      return null;
    }

    dynamic query = SupabaseService.client
        .from(table)
        .select(columns)
        .eq('external_local_uuid', localUuid);

    if (organizationId != null && organizationId.isNotEmpty) {
      query = query.eq('organization_id', organizationId);
    }

    final row = await query.limit(1).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> _writeAuditLog({
    required String organizationId,
    required String actorUserId,
    required String entityType,
    required String entityId,
    required String action,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? deviceId,
  }) async {
    if (organizationId.isEmpty || actorUserId.isEmpty || entityId.isEmpty) {
      return;
    }

    await SupabaseService.client.from('audit_logs').insert({
      'organization_id': organizationId,
      'actor_user_id': actorUserId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'old_values_json': oldValues,
      'new_values_json': newValues,
      'device_id': deviceId ?? 'mobile_sync',
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _writeSyncAuditLog({
    required String organizationId,
    required String actorUserId,
    required String entityType,
    required String entityId,
    required bool isCreate,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? deviceId,
  }) async {
    await _writeAuditLog(
      organizationId: organizationId,
      actorUserId: actorUserId,
      entityType: entityType,
      entityId: entityId,
      action: isCreate ? 'create' : 'sync',
      oldValues: oldValues,
      newValues: newValues,
      deviceId: deviceId,
    );
  }

  void _throwIfServerIsNewer({
    required String entityType,
    required Map<String, dynamic> local,
    required Map<String, dynamic>? remote,
    List<String> localTimestampFields = const ['updated_at'],
  }) {
    if (remote == null) {
      return;
    }

    DateTime? localUpdatedAt;
    for (final field in localTimestampFields) {
      localUpdatedAt = _parseTimestamp(local[field]);
      if (localUpdatedAt != null) {
        break;
      }
    }
    final remoteUpdatedAt = _parseTimestamp(remote['updated_at']);
    if (localUpdatedAt == null || remoteUpdatedAt == null) {
      return;
    }

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      throw SyncConflictException(
        '$entityType conflict: backend record is newer than local data.',
      );
    }
  }

  Future<void> _processProductUpsert(
    String localUuid, {
    required String organizationId,
    required String userId,
    bool forceOverwrite = false,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'product',
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }

    final local = rows.first;
    final serverId = _asText(local['server_id']);
    final externalLocalUuid = _asText(local['local_uuid']);
    final name = _asText(local['name']);
    Map<String, dynamic>? existing;
    Map<String, dynamic>? remoteRecord;

    if (serverId.isNotEmpty) {
      existing = {'id': serverId};
      remoteRecord = await SupabaseService.client
          .from('products')
          .select('id, updated_at')
          .eq('id', serverId)
          .limit(1)
          .maybeSingle();
    } else if (externalLocalUuid.isNotEmpty) {
      existing = await _findByExternalLocalUuid(
        table: 'products',
        organizationId: organizationId,
        localUuid: externalLocalUuid,
      );
      remoteRecord = existing;
    } else if (name.isNotEmpty) {
      existing = await SupabaseService.client
          .from('products')
          .select('id, updated_at')
          .eq('organization_id', organizationId)
          .eq('name', name)
          .limit(1)
          .maybeSingle();
      remoteRecord = existing == null ? null : Map<String, dynamic>.from(existing);
    }

    if (!forceOverwrite) {
      _throwIfServerIsNewer(
        entityType: 'Product',
        local: local,
        remote: remoteRecord,
        localTimestampFields: const ['updated_at', 'last_synced_at', 'created_at'],
      );
    }

    final payload = {
      'organization_id': organizationId,
      'name': local['name'],
      'purchase_price': (local['purchase_price'] as num?)?.toDouble() ?? 0,
      'selling_price': (local['selling_price'] as num?)?.toDouble() ?? 0,
      'quantity': (local['quantity'] as num?)?.toInt() ?? 0,
      'image_path': local['image'],
      'external_local_uuid': externalLocalUuid.isEmpty ? null : externalLocalUuid,
      'updated_by_user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    String resolvedServerId;
    if (existing == null) {
      final created = await SupabaseService.client
          .from('products')
          .insert({
            ...payload,
            'created_by_user_id': userId,
          })
          .select('id')
          .single();
      resolvedServerId = created['id'] as String;
    } else {
      resolvedServerId = existing['id'] as String;
      await SupabaseService.client
          .from('products')
          .update(payload)
          .eq('id', resolvedServerId);
    }

    await db.update(
      'product',
      {
        'server_id': resolvedServerId,
        'sync_status': 'synced',
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
    );

    await _writeSyncAuditLog(
      organizationId: organizationId,
      actorUserId: userId,
      entityType: 'product',
      entityId: resolvedServerId,
      isCreate: existing == null,
      oldValues: remoteRecord,
      newValues: payload,
    );
  }

  Future<void> _processProductDelete(
    String localUuid, {
    Map<String, dynamic>? payload,
    required String organizationId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'product',
      columns: ['server_id', 'name'],
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );

    final local = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final serverId = _asText(payload?['server_id'] ?? local['server_id']);
    final externalLocalUuid =
        _asText(payload?['external_local_uuid'] ?? localUuid);
    final name = _asText(payload?['name'] ?? local['name']);

    final query = SupabaseService.client
        .from('products')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()});
    if (serverId.isNotEmpty) {
      await query.eq('id', serverId);
    } else if (externalLocalUuid.isNotEmpty) {
      await query
          .eq('organization_id', organizationId)
          .eq('external_local_uuid', externalLocalUuid);
    } else if (name.isNotEmpty) {
      await query.eq('organization_id', organizationId).eq('name', name);
    }

    if (serverId.isNotEmpty) {
      final actorUserId = await _currentBackendUserId();
      if (actorUserId != null && actorUserId.isNotEmpty) {
        await _writeAuditLog(
          organizationId: organizationId,
          actorUserId: actorUserId,
          entityType: 'product',
          entityId: serverId,
          action: 'delete',
          newValues: {
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
    }
  }

  Future<void> _processCustomerUpsert(
    String localUuid, {
    required String organizationId,
    required String userId,
    bool forceOverwrite = false,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'customer',
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }

    final local = rows.first;
    final serverId = _asText(local['server_id']);
    final externalLocalUuid = _asText(local['local_uuid']);
    final phoneNumber = _asText(local['phone_number']);
    Map<String, dynamic>? existing;
    Map<String, dynamic>? remoteRecord;

    if (serverId.isNotEmpty) {
      existing = {'id': serverId};
      remoteRecord = await SupabaseService.client
          .from('customers')
          .select('id, updated_at')
          .eq('id', serverId)
          .limit(1)
          .maybeSingle();
    } else if (externalLocalUuid.isNotEmpty) {
      existing = await _findByExternalLocalUuid(
        table: 'customers',
        organizationId: organizationId,
        localUuid: externalLocalUuid,
      );
      remoteRecord = existing;
    } else if (phoneNumber.isNotEmpty) {
      existing = await SupabaseService.client
          .from('customers')
          .select('id, updated_at')
          .eq('organization_id', organizationId)
          .eq('phone_number', phoneNumber)
          .limit(1)
          .maybeSingle();
      remoteRecord = existing == null ? null : Map<String, dynamic>.from(existing);
    }

    if (existing == null) {
      existing = await SupabaseService.client
          .from('customers')
          .select('id, updated_at')
          .eq('organization_id', organizationId)
          .eq('first_name', (local['first_name'] ?? '').toString())
          .eq('middle_name', (local['middle_name'] ?? '').toString())
          .eq('last_name', (local['last_name'] ?? '').toString())
          .eq('municipality', (local['municipality'] ?? '').toString())
          .limit(1)
          .maybeSingle();
      remoteRecord = existing == null ? null : Map<String, dynamic>.from(existing);
    }

    if (!forceOverwrite) {
      _throwIfServerIsNewer(
        entityType: 'Customer',
        local: local,
        remote: remoteRecord,
        localTimestampFields: const ['updated_at', 'last_synced_at', 'created_at'],
      );
    }

    final payload = {
      'organization_id': organizationId,
      'first_name': (local['first_name'] ?? '').toString().trim(),
      'middle_name': (local['middle_name'] ?? '').toString().trim(),
      'last_name': (local['last_name'] ?? '').toString().trim(),
      'phone_number': phoneNumber,
      'municipality': (local['municipality'] ?? '').toString().trim(),
      'barangay': (local['barangay'] ?? '').toString().trim(),
      'landmark': (local['landmark'] ?? '').toString().trim(),
      'credit_limit': (local['credit_limit'] as num?)?.toDouble() ?? 1000,
      'available_credit':
          (local['available_credit'] as num?)?.toDouble() ?? 1000,
      'external_local_uuid': externalLocalUuid.isEmpty ? null : externalLocalUuid,
      'updated_by_user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    String resolvedServerId;
    if (existing == null) {
      final created = await SupabaseService.client
          .from('customers')
          .insert({
            ...payload,
            'created_by_user_id': userId,
          })
          .select('id')
          .single();
      resolvedServerId = created['id'] as String;
    } else {
      resolvedServerId = existing['id'] as String;
      await SupabaseService.client
          .from('customers')
          .update(payload)
          .eq('id', resolvedServerId);
    }

    await db.update(
      'customer',
      {
        'server_id': resolvedServerId,
        'sync_status': 'synced',
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
    );

    await _writeSyncAuditLog(
      organizationId: organizationId,
      actorUserId: userId,
      entityType: 'customer',
      entityId: resolvedServerId,
      isCreate: existing == null,
      oldValues: remoteRecord,
      newValues: payload,
    );
  }

  Future<void> _processCustomerDelete(
    String localUuid, {
    Map<String, dynamic>? payload,
    required String organizationId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'customer',
      columns: [
        'server_id',
        'phone_number',
        'first_name',
        'middle_name',
        'last_name',
        'municipality',
      ],
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );

    final local = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final serverId = _asText(payload?['server_id'] ?? local['server_id']);
    final externalLocalUuid =
        _asText(payload?['external_local_uuid'] ?? localUuid);
    if (serverId.isNotEmpty) {
      await SupabaseService.client
          .from('customers')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', serverId);
      final actorUserId = await _currentBackendUserId();
      if (actorUserId != null && actorUserId.isNotEmpty) {
        await _writeAuditLog(
          organizationId: organizationId,
          actorUserId: actorUserId,
          entityType: 'customer',
          entityId: serverId,
          action: 'delete',
          newValues: {
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
      return;
    }

    if (externalLocalUuid.isNotEmpty) {
      await SupabaseService.client
          .from('customers')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('organization_id', organizationId)
          .eq('external_local_uuid', externalLocalUuid);
      return;
    }

    final phoneNumber = _asText(payload?['phone_number'] ?? local['phone_number']);
    if (phoneNumber.isNotEmpty) {
      await SupabaseService.client
          .from('customers')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('organization_id', organizationId)
          .eq('phone_number', phoneNumber);
      return;
    }

    final firstName =
        ((payload?['first_name'] ?? local['first_name']) ?? '').toString();
    final middleName =
        ((payload?['middle_name'] ?? local['middle_name']) ?? '').toString();
    final lastName =
        ((payload?['last_name'] ?? local['last_name']) ?? '').toString();
    final municipality =
        ((payload?['municipality'] ?? local['municipality']) ?? '').toString();

    if (firstName.isEmpty || lastName.isEmpty || municipality.isEmpty) {
      return;
    }

    await SupabaseService.client
        .from('customers')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('organization_id', organizationId)
        .eq('first_name', firstName)
        .eq('middle_name', middleName)
        .eq('last_name', lastName)
        .eq('municipality', municipality);
  }

  Future<String?> _resolveBackendProductId(
    Map<String, dynamic> localProduct, {
    required String organizationId,
  }) async {
    final serverId = _asText(localProduct['server_id']);
    if (serverId.isNotEmpty) {
      return serverId;
    }

    final externalLocalUuid = _asText(localProduct['local_uuid']);
    if (externalLocalUuid.isNotEmpty) {
      final existing = await _findByExternalLocalUuid(
        table: 'products',
        organizationId: organizationId,
        localUuid: externalLocalUuid,
        columns: 'id',
      );
      if (existing != null) {
        return existing['id'] as String;
      }
    }

    final name = _asText(localProduct['name']);
    if (name.isEmpty) {
      return null;
    }

    final existing = await SupabaseService.client
        .from('products')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('name', name)
        .limit(1)
        .maybeSingle();
    return existing == null ? null : existing['id'] as String;
  }

  Future<String?> _resolveBackendCustomerId(
    Map<String, dynamic> localCustomer, {
    required String organizationId,
  }) async {
    final serverId = _asText(localCustomer['server_id']);
    if (serverId.isNotEmpty) {
      return serverId;
    }

    final externalLocalUuid = _asText(localCustomer['local_uuid']);
    if (externalLocalUuid.isNotEmpty) {
      final existing = await _findByExternalLocalUuid(
        table: 'customers',
        organizationId: organizationId,
        localUuid: externalLocalUuid,
        columns: 'id',
      );
      if (existing != null) {
        return existing['id'] as String;
      }
    }

    final phoneNumber = _asText(localCustomer['phone_number']);
    if (phoneNumber.isNotEmpty) {
      final existing = await SupabaseService.client
          .from('customers')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('phone_number', phoneNumber)
          .limit(1)
          .maybeSingle();
      if (existing != null) {
        return existing['id'] as String;
      }
    }

    final existing = await SupabaseService.client
        .from('customers')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('first_name', (localCustomer['first_name'] ?? '').toString())
        .eq('middle_name', (localCustomer['middle_name'] ?? '').toString())
        .eq('last_name', (localCustomer['last_name'] ?? '').toString())
        .eq('municipality', (localCustomer['municipality'] ?? '').toString())
        .limit(1)
        .maybeSingle();
    return existing == null ? null : existing['id'] as String;
  }

  Future<Map<String, dynamic>?> _findExistingBackendSale({
    required String organizationId,
    required String? externalLocalUuid,
    required String saleType,
    required double totalAmount,
    required String? createdAt,
    required String? backendCustomerId,
  }) async {
    final normalizedLocalUuid = _asText(externalLocalUuid);
    if (normalizedLocalUuid.isNotEmpty) {
      final byExternalLocalUuid = await _findByExternalLocalUuid(
        table: 'sales',
        organizationId: organizationId,
        localUuid: normalizedLocalUuid,
        columns: 'id, updated_at',
      );
      if (byExternalLocalUuid != null) {
        return byExternalLocalUuid;
      }
    }

    dynamic query = SupabaseService.client
        .from('sales')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('sale_type', saleType)
        .eq('total_amount', totalAmount);

    if (createdAt != null && createdAt.isNotEmpty) {
      query = query.eq('created_at', createdAt);
    }

    if (backendCustomerId != null && backendCustomerId.isNotEmpty) {
      query = query.eq('customer_id', backendCustomerId);
    } else {
      query = query.isFilter('customer_id', null);
    }

    final row = await query.limit(1).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> _getBackendSaleById(String saleId) async {
    final row = await SupabaseService.client
        .from('sales')
        .select('id, updated_at')
        .eq('id', saleId)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> _getBackendReceivableById(String receivableId) async {
    final row = await SupabaseService.client
        .from('receivables')
        .select('id, updated_at, remaining_amount, status')
        .eq('id', receivableId)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> _findExistingReceivablePayment({
    required String organizationId,
    required String? externalLocalUuid,
    required String receivableId,
    required double amount,
    required String? paidAt,
    required String userId,
  }) async {
    final normalizedLocalUuid = _asText(externalLocalUuid);
    if (normalizedLocalUuid.isNotEmpty) {
      final byExternalLocalUuid = await _findByExternalLocalUuid(
        table: 'receivable_payments',
        organizationId: organizationId,
        localUuid: normalizedLocalUuid,
        columns: 'id',
      );
      if (byExternalLocalUuid != null) {
        return byExternalLocalUuid;
      }
    }

    dynamic query = SupabaseService.client
        .from('receivable_payments')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('receivable_id', receivableId)
        .eq('amount', amount)
        .eq('created_by_user_id', userId);

    if (paidAt != null && paidAt.isNotEmpty) {
      query = query.eq('paid_at', paidAt);
    }

    final row = await query.limit(1).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  String _receivablePaymentExternalLocalUuid(
    String paymentLocalUuid,
    String receivableId,
  ) {
    if (paymentLocalUuid.isEmpty) {
      return '';
    }
    return '$paymentLocalUuid:$receivableId';
  }

  Future<void> _processSaleUpsert(
    String localUuid, {
    required String organizationId,
    required String userId,
    bool forceOverwrite = false,
  }) async {
    final db = await _db;
    final saleRows = await db.query(
      'sales',
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );
    if (saleRows.isEmpty) {
      return;
    }

    final sale = saleRows.first;
    final saleId = sale['id'] as int;
    final saleType = (sale['sale_type'] ?? '').toString();
    final localServerId = _asText(sale['server_id']);
    final saleExternalLocalUuid = _asText(sale['local_uuid']);

    String? backendCustomerId;
    final customerId = sale['customer_id'] as int?;
    if (customerId != null) {
      final customerRows = await db.query(
        'customer',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (customerRows.isNotEmpty) {
        backendCustomerId = await _resolveBackendCustomerId(
          customerRows.first,
          organizationId: organizationId,
        );
      }
    }

    Map<String, dynamic>? existingSale;
    if (localServerId.isNotEmpty) {
      existingSale = {'id': localServerId};
    } else {
      existingSale = await _findExistingBackendSale(
        organizationId: organizationId,
        externalLocalUuid: saleExternalLocalUuid,
        saleType: saleType,
        totalAmount: (sale['total'] as num?)?.toDouble() ?? 0,
        createdAt: sale['created_at']?.toString(),
        backendCustomerId: backendCustomerId,
      );
    }

    if (!forceOverwrite && existingSale != null) {
      final remoteSale = localServerId.isNotEmpty
          ? await _getBackendSaleById(existingSale['id'] as String)
          : existingSale;
      _throwIfServerIsNewer(
        entityType: 'Sale',
        local: sale,
        remote: remoteSale,
        localTimestampFields: const ['last_synced_at', 'created_at'],
      );
    }

    final salePayload = {
      'organization_id': organizationId,
      'customer_id': backendCustomerId,
      'sale_type': saleType,
      'total_amount': (sale['total'] as num?)?.toDouble() ?? 0,
      'external_local_uuid':
          saleExternalLocalUuid.isEmpty ? null : saleExternalLocalUuid,
      'updated_by_user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    String backendSaleId;
    if (existingSale == null) {
      final createdSale = await SupabaseService.client
          .from('sales')
          .insert({
            ...salePayload,
            'created_by_user_id': userId,
            'created_at': sale['created_at'],
          })
          .select('id')
          .single();
      backendSaleId = createdSale['id'] as String;
    } else {
      backendSaleId = existingSale['id'] as String;
      await SupabaseService.client
          .from('sales')
          .update(salePayload)
          .eq('id', backendSaleId);
    }

    await _writeSyncAuditLog(
      organizationId: organizationId,
      actorUserId: userId,
      entityType: 'sale',
      entityId: backendSaleId,
      isCreate: existingSale == null,
      oldValues: existingSale,
      newValues: salePayload,
    );

    final itemRows = await db.query(
      'sale_item',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'id ASC',
    );

    for (final item in itemRows) {
      final localProductRows = await db.query(
        'product',
        where: 'id = ?',
        whereArgs: [item['product_id']],
        limit: 1,
      );
      if (localProductRows.isEmpty) {
        continue;
      }

      final backendProductId = await _resolveBackendProductId(
        localProductRows.first,
        organizationId: organizationId,
      );
      if (backendProductId == null) {
        continue;
      }

      final localSaleItemServerId = _asText(item['server_id']);
      final saleItemExternalLocalUuid = _asText(item['local_uuid']);
      Map<String, dynamic>? existingSaleItem;
      if (localSaleItemServerId.isNotEmpty) {
        existingSaleItem = {'id': localSaleItemServerId};
      } else if (saleItemExternalLocalUuid.isNotEmpty) {
        existingSaleItem = await _findByExternalLocalUuid(
          table: 'sale_items',
          localUuid: saleItemExternalLocalUuid,
          columns: 'id',
        );
      } else {
        existingSaleItem = await SupabaseService.client
            .from('sale_items')
            .select('id')
            .eq('sale_id', backendSaleId)
            .eq('product_id', backendProductId)
            .limit(1)
            .maybeSingle();
      }

      final saleItemPayload = {
        'sale_id': backendSaleId,
        'product_id': backendProductId,
        'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0,
        'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
        'subtotal': (item['subtotal'] as num?)?.toDouble() ?? 0,
        'external_local_uuid':
            saleItemExternalLocalUuid.isEmpty ? null : saleItemExternalLocalUuid,
      };

      String resolvedSaleItemId;
      if (existingSaleItem == null) {
        final createdSaleItem = await SupabaseService.client
            .from('sale_items')
            .insert(saleItemPayload)
            .select('id')
            .single();
        resolvedSaleItemId = createdSaleItem['id'] as String;
      } else {
        resolvedSaleItemId = existingSaleItem['id'] as String;
        await SupabaseService.client
            .from('sale_items')
            .update(saleItemPayload)
            .eq('id', resolvedSaleItemId);
      }

      await _writeSyncAuditLog(
        organizationId: organizationId,
        actorUserId: userId,
        entityType: 'sale_item',
        entityId: resolvedSaleItemId,
        isCreate: existingSaleItem == null,
        oldValues: existingSaleItem,
        newValues: saleItemPayload,
      );

      await db.update(
        'sale_item',
        {
          'server_id': resolvedSaleItemId,
          'sync_status': 'synced',
          'last_synced_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }

    await db.update(
      'sales',
      {
        'server_id': backendSaleId,
        'sync_status': 'synced',
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
    );

    if (saleType == 'credit' && backendCustomerId != null) {
      final receivableRows = await db.query(
        'sales_credit',
        where: 'sale_id = ?',
        whereArgs: [saleId],
        orderBy: 'id ASC',
      );

      if (receivableRows.isNotEmpty) {
        final localReceivableServerId =
            _asText(receivableRows.first['server_id']);
        final receivableExternalLocalUuid =
            _asText(receivableRows.first['local_uuid']);
        Map<String, dynamic>? existingReceivable;
        if (localReceivableServerId.isNotEmpty) {
          existingReceivable = {'id': localReceivableServerId};
        } else if (receivableExternalLocalUuid.isNotEmpty) {
          existingReceivable = await _findByExternalLocalUuid(
            table: 'receivables',
            organizationId: organizationId,
            localUuid: receivableExternalLocalUuid,
          );
        } else {
          existingReceivable = await SupabaseService.client
              .from('receivables')
              .select('id, updated_at')
              .eq('organization_id', organizationId)
              .eq('sale_id', backendSaleId)
              .limit(1)
              .maybeSingle();
        }

        if (!forceOverwrite && existingReceivable != null) {
          final remoteReceivable = localReceivableServerId.isNotEmpty
              ? await _getBackendReceivableById(
                  existingReceivable['id'] as String,
                )
              : existingReceivable;
          _throwIfServerIsNewer(
            entityType: 'Receivable',
            local: receivableRows.first,
            remote: remoteReceivable,
            localTimestampFields: const ['last_synced_at', 'created_at', 'credit_date'],
          );
        }

        final totalAmount = receivableRows.fold<double>(
          0,
          (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
        );
        final firstRow = receivableRows.first;
        final receivablePayload = {
          'organization_id': organizationId,
          'sale_id': backendSaleId,
          'customer_id': backendCustomerId,
          'original_amount': totalAmount,
          'remaining_amount': totalAmount,
          'status': 'unpaid',
          'due_date': firstRow['due_date'],
          'external_local_uuid': receivableExternalLocalUuid.isEmpty
              ? null
              : receivableExternalLocalUuid,
          'updated_by_user_id': userId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        String resolvedReceivableId;
        if (existingReceivable == null) {
          final createdReceivable = await SupabaseService.client
              .from('receivables')
              .insert({
                ...receivablePayload,
                'created_by_user_id': userId,
                'created_at': firstRow['created_at'],
              })
              .select('id')
              .single();
          resolvedReceivableId = createdReceivable['id'] as String;
        } else {
          resolvedReceivableId = existingReceivable['id'] as String;
          await SupabaseService.client
              .from('receivables')
              .update(receivablePayload)
              .eq('id', resolvedReceivableId);
        }

        await _writeSyncAuditLog(
          organizationId: organizationId,
          actorUserId: userId,
          entityType: 'receivable',
          entityId: resolvedReceivableId,
          isCreate: existingReceivable == null,
          oldValues: existingReceivable,
          newValues: receivablePayload,
        );

        await db.update(
          'sales_credit',
          {
            'server_id': resolvedReceivableId,
            'sync_status': 'synced',
            'last_synced_at': DateTime.now().toIso8601String(),
          },
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _findBackendReceivablesForCustomer(
    String organizationId,
    String backendCustomerId,
  ) async {
    final rows = await SupabaseService.client
        .from('receivables')
        .select('id, remaining_amount')
        .eq('organization_id', organizationId)
        .eq('customer_id', backendCustomerId)
        .inFilter('status', ['unpaid', 'partial'])
        .order('created_at', ascending: true);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> _processCustomerPaymentUpsert(
    String localUuid, {
    required String organizationId,
    required String userId,
    bool forceOverwrite = false,
  }) async {
    final db = await _db;
    final paymentRows = await db.query(
      'customer_payment',
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );
    if (paymentRows.isEmpty) {
      return;
    }

    final payment = paymentRows.first;
    final paymentExternalLocalUuid = _asText(payment['local_uuid']);
    final customerId = payment['customer_id'] as int?;
    if (customerId == null) {
      return;
    }

    final customerRows = await db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (customerRows.isEmpty) {
      return;
    }

    final backendCustomerId = await _resolveBackendCustomerId(
      customerRows.first,
      organizationId: organizationId,
    );
    if (backendCustomerId == null) {
      return;
    }

    double remainingPayment = (payment['amount'] as num?)?.toDouble() ?? 0;
    final paymentIds = <String>[];
    final receivables = await _findBackendReceivablesForCustomer(
      organizationId,
      backendCustomerId,
    );

    for (final receivable in receivables) {
      if (remainingPayment <= 0) {
        break;
      }

      final currentRemaining =
          (receivable['remaining_amount'] as num?)?.toDouble() ?? 0;
      if (currentRemaining <= 0) {
        continue;
      }

      final appliedAmount = remainingPayment > currentRemaining
          ? currentRemaining
          : remainingPayment;
      final updatedRemaining = currentRemaining - appliedAmount;
      final updatedStatus = updatedRemaining <= 0 ? 'paid' : 'partial';
      final paymentRowLocalUuid = _receivablePaymentExternalLocalUuid(
        paymentExternalLocalUuid,
        receivable['id'] as String,
      );

      final existingPayment = await _findExistingReceivablePayment(
        organizationId: organizationId,
        externalLocalUuid: paymentRowLocalUuid,
        receivableId: receivable['id'] as String,
        amount: appliedAmount,
        paidAt: payment['paid_at']?.toString(),
        userId: userId,
      );

      if (!forceOverwrite && existingPayment == null) {
        final remoteReceivable = await _getBackendReceivableById(
          receivable['id'] as String,
        );
        _throwIfServerIsNewer(
          entityType: 'Customer payment',
          local: payment,
          remote: remoteReceivable,
          localTimestampFields: const ['last_synced_at', 'paid_at'],
        );
      }

      final paymentRow = existingPayment ??
          await SupabaseService.client
              .from('receivable_payments')
              .insert({
                'organization_id': organizationId,
                'receivable_id': receivable['id'] as String,
                'amount': appliedAmount,
                'paid_at': payment['paid_at'],
                'external_local_uuid': paymentRowLocalUuid.isEmpty
                    ? null
                    : paymentRowLocalUuid,
                'created_by_user_id': userId,
              })
              .select('id')
              .single();
      paymentIds.add(paymentRow['id'] as String);

      await _writeSyncAuditLog(
        organizationId: organizationId,
        actorUserId: userId,
        entityType: 'receivable_payment',
        entityId: paymentRow['id'] as String,
        isCreate: existingPayment == null,
        oldValues: existingPayment,
        newValues: {
          'receivable_id': receivable['id'] as String,
          'amount': appliedAmount,
          'paid_at': payment['paid_at'],
        },
      );

      if (existingPayment == null) {
        await SupabaseService.client
            .from('receivables')
            .update({
              'remaining_amount': updatedRemaining,
              'status': updatedStatus,
              'updated_by_user_id': userId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', receivable['id'] as String);
      }

      remainingPayment -= appliedAmount;
    }

    await db.update(
      'customer_payment',
      {
        'server_id': paymentIds.length == 1 ? paymentIds.first : null,
        'sync_status': 'synced',
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
    );
  }
}
