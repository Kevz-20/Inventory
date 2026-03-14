import '../models/sync_contract_models.dart';
import 'backend_sync_service.dart';
import 'sync_backend_config.dart';
import 'sync_service.dart';

class MockSyncResult {
  const MockSyncResult({
    required this.totalSynced,
    required this.syncedByTable,
  });

  final int totalSynced;
  final Map<String, int> syncedByTable;
}

class SyncRunnerService {
  SyncRunnerService._();

  static final SyncRunnerService instance = SyncRunnerService._();

  Future<MockSyncResult> runMockSync() async {
    final payload = await SyncService.instance.buildPendingPayload();
    final tables = Map<String, dynamic>.from(
      payload['tables'] as Map? ?? const {},
    );

    final syncedIdsByTable = <String, List<int>>{};
    final serverIdsByTable = <String, Map<int, String>>{};
    final syncedByTable = <String, int>{};
    int totalSynced = 0;

    for (final entry in tables.entries) {
      final rows = (entry.value as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      final localIds = <int>[];
      final serverIds = <int, String>{};

      for (final row in rows) {
        final localId = (row['id'] as num?)?.toInt();
        if (localId == null) continue;

        localIds.add(localId);
        serverIds[localId] =
            row['server_id']?.toString().trim().isNotEmpty == true
                ? row['server_id'].toString().trim()
                : '${entry.key}_$localId';
      }

      if (localIds.isEmpty) continue;

      syncedIdsByTable[entry.key] = localIds;
      serverIdsByTable[entry.key] = serverIds;
      syncedByTable[entry.key] = localIds.length;
      totalSynced += localIds.length;
    }

    if (totalSynced == 0) {
      return const MockSyncResult(totalSynced: 0, syncedByTable: {});
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    await SyncService.instance.markPayloadSynced(
      syncedIdsByTable,
      serverIdsByTable: serverIdsByTable,
    );

    return MockSyncResult(
      totalSynced: totalSynced,
      syncedByTable: syncedByTable,
    );
  }

  Future<MockSyncResult> runBackendSync() async {
    if (!SyncBackendConfig.isConfigured) {
      throw StateError('Backend sync URL is not configured.');
    }

    final payload = await SyncService.instance.buildPendingPayload();
    final request = BackendSyncRequest.fromPayload(payload);

    if (request.totalRecords == 0) {
      return const MockSyncResult(totalSynced: 0, syncedByTable: {});
    }

    final backend = BackendSyncService(
      baseUrl: SyncBackendConfig.baseUrl,
      authToken: SyncBackendConfig.authToken,
    );
    final response = await backend.uploadPayload(request);

    await SyncService.instance.markPayloadSynced(
      response.syncedIdsByTable,
      serverIdsByTable: response.serverIdsByTable,
    );

    final syncedByTable = response.syncedIdsByTable.map(
      (table, ids) => MapEntry(table, ids.length),
    );
    final totalSynced = syncedByTable.values.fold<int>(0, (sum, count) => sum + count);

    return MockSyncResult(
      totalSynced: totalSynced,
      syncedByTable: syncedByTable,
    );
  }
}
