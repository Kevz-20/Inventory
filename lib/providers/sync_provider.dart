import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

final syncQueueSummaryProvider = FutureProvider<SyncQueueSummary>((ref) async {
  final service = ref.watch(syncServiceProvider);
  return service.getQueueSummary();
});

final syncQueueJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(syncServiceProvider);
  return service.getQueueJobs(
    statuses: const ['pending', 'failed'],
    limit: 200,
  );
});

final auditLogEntriesProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final service = ref.watch(syncServiceProvider);
  return service.getAuditLogEntries(limit: 100);
});

final auditLogEntriesByOrganizationProvider =
    FutureProvider.family<List<AuditLogEntry>, String>((ref, organizationId) async {
      final service = ref.watch(syncServiceProvider);
      return service.getAuditLogEntries(
        limit: 100,
        organizationId: organizationId,
      );
    });

final syncDiagnosticsEntityProvider = StateProvider<String>((ref) => 'product');

final syncRecordDiagnosticsProvider =
    FutureProvider<List<SyncRecordDiagnostics>>((ref) async {
  final service = ref.watch(syncServiceProvider);
  final entityType = ref.watch(syncDiagnosticsEntityProvider);
  return service.getRecordDiagnostics(entityType, limit: 200);
});

class SyncController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> syncNow() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(syncServiceProvider).processPendingJobs();
      ref.invalidate(syncQueueSummaryProvider);
      ref.invalidate(syncQueueJobsProvider);
      ref.invalidate(syncRecordDiagnosticsProvider);
      ref.invalidate(auditLogEntriesProvider);
    });
  }

  Future<void> retryJob(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(syncServiceProvider);
      await service.requeueJob(id);
      await service.processPendingJobs();
      ref.invalidate(syncQueueSummaryProvider);
      ref.invalidate(syncQueueJobsProvider);
      ref.invalidate(syncRecordDiagnosticsProvider);
      ref.invalidate(auditLogEntriesProvider);
    });
  }

  Future<void> forceOverwriteJob(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(syncServiceProvider);
      await service.requeueJobWithForceOverwrite(id);
      await service.processPendingJobs();
      ref.invalidate(syncQueueSummaryProvider);
      ref.invalidate(syncQueueJobsProvider);
      ref.invalidate(syncRecordDiagnosticsProvider);
      ref.invalidate(auditLogEntriesProvider);
    });
  }

  Future<void> retryFailedJobs() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(syncServiceProvider);
      await service.retryFailedJobs();
      ref.invalidate(syncQueueSummaryProvider);
      ref.invalidate(syncQueueJobsProvider);
      ref.invalidate(syncRecordDiagnosticsProvider);
      ref.invalidate(auditLogEntriesProvider);
    });
  }

  Future<void> resyncRecord({
    required String entityType,
    required String localUuid,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(syncServiceProvider);
      await service.resyncRecord(
        entityType: entityType,
        localUuid: localUuid,
      );
      await service.processPendingJobs();
      ref.invalidate(syncQueueSummaryProvider);
      ref.invalidate(syncQueueJobsProvider);
      ref.invalidate(syncRecordDiagnosticsProvider);
      ref.invalidate(auditLogEntriesProvider);
    });
  }
}

final syncControllerProvider = AsyncNotifierProvider<SyncController, void>(
  SyncController.new,
);
