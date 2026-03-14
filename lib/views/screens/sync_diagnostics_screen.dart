import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';

class SyncDiagnosticsScreen extends ConsumerWidget {
  final String? initialEntityType;
  final String? initialLocalUuid;

  const SyncDiagnosticsScreen({
    super.key,
    this.initialEntityType,
    this.initialLocalUuid,
  });

  static const _entities = <({String key, String label})>[
    (key: 'product', label: 'Products'),
    (key: 'customer', label: 'Customers'),
    (key: 'sales', label: 'Sales'),
    (key: 'receivables', label: 'Receivables'),
    (key: 'payments', label: 'Payments'),
  ];

  Future<void> _resyncRecord(
    BuildContext context,
    WidgetRef ref,
    SyncRecordDiagnostics record,
  ) async {
    final localUuid = record.localUuid ?? '';
    if (localUuid.isEmpty) {
      return;
    }

    await ref.read(syncControllerProvider.notifier).resyncRecord(
          entityType: record.entityType,
          localUuid: localUuid,
        );
    if (!context.mounted) return;

    final state = ref.read(syncControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    state.whenOrNull(
      data: (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Record re-synced.')),
      ),
      error: (error, _) => messenger.showSnackBar(
        SnackBar(content: Text('Resync failed: $error')),
      ),
    );
  }

  String _queueEntityTypeForRecord(SyncRecordDiagnostics record) {
    return switch (record.entityType) {
      'receivables' => 'sales',
      'payments' => 'customer_payment',
      _ => record.entityType,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEntity = ref.watch(syncDiagnosticsEntityProvider);
    final recordsAsync = ref.watch(syncRecordDiagnosticsProvider);
    final controller = ref.watch(syncControllerProvider);
    final hasFilter =
        (initialEntityType?.isNotEmpty ?? false) ||
        (initialLocalUuid?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Sync Diagnostics',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(syncRecordDiagnosticsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Record State',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inspect local sync identity and backend linkage per entity.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (hasFilter) ...[
                    Text(
                      'Filtered: ${_buildFilterLabel()}',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _entities.map((entity) {
                      final isSelected = selectedEntity == entity.key;
                      return ChoiceChip(
                        label: Text(entity.label),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(syncDiagnosticsEntityProvider.notifier).state =
                              entity.key;
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            recordsAsync.when(
              data: (records) {
                final filteredRecords = records.where((record) {
                  if (initialEntityType != null &&
                      initialEntityType!.isNotEmpty &&
                      record.entityType != initialEntityType) {
                    return false;
                  }
                  if (initialLocalUuid != null &&
                      initialLocalUuid!.isNotEmpty &&
                      (record.localUuid ?? '') != initialLocalUuid) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filteredRecords.isEmpty) {
                  return const _EmptyDiagnosticsCard();
                }

                return Column(
                  children: filteredRecords
                      .map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DiagnosticsCard(
                            record: record,
                            isBusy: controller.isLoading,
                            onResync: (record.localUuid ?? '').isNotEmpty
                                ? () => _resyncRecord(context, ref, record)
                                : null,
                            onViewQueueJob:
                                (record.lastQueueError != null &&
                                        record.lastQueueError!.isNotEmpty &&
                                        (record.localUuid ?? '').isNotEmpty)
                                    ? () => context.push(
                                          '/sync_history?entityType=${Uri.encodeComponent(_queueEntityTypeForRecord(record))}&localUuid=${Uri.encodeComponent(record.localUuid!)}',
                                        )
                                    : null,
                            onViewAuditLog:
                                (record.localUuid ?? '').isNotEmpty
                                    ? () => context.push(
                                          '/audit_logs?entityType=${Uri.encodeComponent(_auditEntityTypeForRecord(record))}&localUuid=${Uri.encodeComponent(record.localUuid!)}',
                                        )
                                    : null,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const _LoadingDiagnosticsCard(),
              error: (error, _) => _ErrorDiagnosticsCard(message: '$error'),
            ),
          ],
        ),
      ),
    );
  }

  String _buildFilterLabel() {
    final parts = <String>[];
    if (initialEntityType != null && initialEntityType!.isNotEmpty) {
      parts.add(initialEntityType!);
    }
    if (initialLocalUuid != null && initialLocalUuid!.isNotEmpty) {
      parts.add(initialLocalUuid!);
    }
    return parts.join(' • ');
  }

  String _auditEntityTypeForRecord(SyncRecordDiagnostics record) {
    return switch (record.entityType) {
      'sales' => 'sale',
      'receivables' => 'receivable',
      'payments' => 'receivable_payment',
      _ => record.entityType,
    };
  }
}

class _DiagnosticsCard extends StatelessWidget {
  final SyncRecordDiagnostics record;
  final bool isBusy;
  final VoidCallback? onResync;
  final VoidCallback? onViewQueueJob;
  final VoidCallback? onViewAuditLog;

  const _DiagnosticsCard({
    required this.record,
    required this.isBusy,
    required this.onResync,
    required this.onViewQueueJob,
    required this.onViewAuditLog,
  });

  @override
  Widget build(BuildContext context) {
    final status = record.syncStatus.isEmpty ? 'local_only' : record.syncStatus;
    final isSynced = status == 'synced';
    final isPending = status == 'pending_upload';
    final hasQueueError =
        record.lastQueueError != null && record.lastQueueError!.isNotEmpty;
    final chipBg = isSynced
        ? const Color(0xFFEAF4EF)
        : isPending
            ? const Color(0xFFFFF4DB)
            : const Color(0xFFFCE8E6);
    final chipFg = isSynced
        ? const Color(0xFF1E6B3A)
        : isPending
            ? const Color(0xFF8A5A00)
            : const Color(0xFF9C2B1F);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: chipFg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (record.subtitle != null && record.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.subtitle!,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _MetaLine(label: 'Local row', value: '${record.localId}'),
          _MetaLine(label: 'Local UUID', value: record.localUuid ?? '—'),
          _MetaLine(label: 'Server ID', value: record.serverId ?? '—'),
          _MetaLine(
            label: 'Last synced',
            value: record.lastSyncedAt?.isNotEmpty == true
                ? record.lastSyncedAt!
                : '—',
          ),
          _MetaLine(
            label: 'Updated',
            value: record.updatedAt?.isNotEmpty == true ? record.updatedAt! : '—',
          ),
          if (hasQueueError) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Queue Failure',
                    style: TextStyle(
                      color: Color(0xFF9C2B1F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.lastQueueError!,
                    style: const TextStyle(
                      color: Color(0xFF9C2B1F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retries: ${record.retryCount}',
                    style: const TextStyle(
                      color: Color(0xFF9C2B1F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (record.queueUpdatedAt != null &&
                      record.queueUpdatedAt!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Queue updated: ${record.queueUpdatedAt!}',
                      style: const TextStyle(
                        color: Color(0xFF9C2B1F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (onResync != null || onViewQueueJob != null || onViewAuditLog != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (onViewAuditLog != null)
                    FilledButton.tonal(
                      onPressed: isBusy ? null : onViewAuditLog,
                      child: const Text('View audit log'),
                    ),
                  if (onViewQueueJob != null)
                    FilledButton.tonal(
                      onPressed: isBusy ? null : onViewQueueJob,
                      child: const Text('View queue job'),
                    ),
                  if (onResync != null)
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onResync,
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Resync'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.68),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDiagnosticsCard extends StatelessWidget {
  const _LoadingDiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorDiagnosticsCard extends StatelessWidget {
  final String message;

  const _ErrorDiagnosticsCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF9C2B1F),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyDiagnosticsCard extends StatelessWidget {
  const _EmptyDiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'No local records found for the selected entity.',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
