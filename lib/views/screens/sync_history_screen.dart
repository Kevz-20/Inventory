import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../providers/sync_provider.dart';

class SyncHistoryScreen extends ConsumerWidget {
  final String? initialEntityType;
  final String? initialLocalUuid;

  const SyncHistoryScreen({
    super.key,
    this.initialEntityType,
    this.initialLocalUuid,
  });

  Future<void> _retryAll(BuildContext context, WidgetRef ref) async {
    await ref.read(syncControllerProvider.notifier).retryFailedJobs();
    if (!context.mounted) return;

    final state = ref.read(syncControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    state.whenOrNull(
      data: (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Retry completed.')),
      ),
      error: (error, _) => messenger.showSnackBar(
        SnackBar(content: Text('Retry failed: $error')),
      ),
    );
  }

  Future<void> _retryJob(BuildContext context, WidgetRef ref, int id) async {
    await ref.read(syncControllerProvider.notifier).retryJob(id);
    if (!context.mounted) return;

    final state = ref.read(syncControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    state.whenOrNull(
      data: (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Job retried.')),
      ),
      error: (error, _) => messenger.showSnackBar(
        SnackBar(content: Text('Retry failed: $error')),
      ),
    );
  }

  Future<void> _forceOverwrite(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    await ref.read(syncControllerProvider.notifier).forceOverwriteJob(id);
    if (!context.mounted) return;

    final state = ref.read(syncControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    state.whenOrNull(
      data: (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Force overwrite completed.')),
      ),
      error: (error, _) => messenger.showSnackBar(
        SnackBar(content: Text('Force overwrite failed: $error')),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(syncQueueSummaryProvider);
    final jobsAsync = ref.watch(syncQueueJobsProvider);
    final controller = ref.watch(syncControllerProvider);
    final hasFilter =
        (initialEntityType?.isNotEmpty ?? false) ||
        (initialLocalUuid?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Sync History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(syncQueueSummaryProvider);
          ref.invalidate(syncQueueJobsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summaryAsync.when(
              data: (summary) => _SummaryCard(
                pendingCount: summary.pendingCount,
                failedCount: summary.failedCount,
                completedCount: summary.completedCount,
                isBusy: controller.isLoading,
                filterLabel: hasFilter
                    ? _buildFilterLabel(
                        entityType: initialEntityType,
                        localUuid: initialLocalUuid,
                      )
                    : null,
                onRetryAll: summary.failedCount > 0
                    ? () => _retryAll(context, ref)
                    : null,
              ),
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(message: '$error'),
            ),
            const SizedBox(height: 16),
            jobsAsync.when(
              data: (jobs) {
                final filteredJobs = jobs.where((job) {
                  final entityType = (job['entity_type'] ?? '').toString();
                  final localUuid = (job['local_uuid'] ?? '').toString();
                  if (initialEntityType != null &&
                      initialEntityType!.isNotEmpty &&
                      entityType != initialEntityType) {
                    return false;
                  }
                  if (initialLocalUuid != null &&
                      initialLocalUuid!.isNotEmpty &&
                      localUuid != initialLocalUuid) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filteredJobs.isEmpty) {
                  return const _EmptyCard();
                }

                return Column(
                  children: filteredJobs.map((job) {
                    final id = (job['id'] as num?)?.toInt() ?? 0;
                    final entityType = (job['entity_type'] ?? '').toString();
                    final localUuid = (job['local_uuid'] ?? '').toString();
                    final lastError = (job['last_error'] ?? '').toString();
                    final isConflict = lastError.toLowerCase().contains(
                      'conflict',
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _JobCard(
                        job: job,
                        isBusy: controller.isLoading,
                        onRetry: (job['status'] ?? '') == 'failed' && id > 0
                            ? () => _retryJob(context, ref, id)
                            : null,
                        onForceOverwrite:
                            (job['status'] ?? '') == 'failed' &&
                                id > 0 &&
                                isConflict
                            ? () => _forceOverwrite(context, ref, id)
                            : null,
                        onViewAuditLog:
                            localUuid.isNotEmpty
                                ? () => context.push(
                                      '/audit_logs?entityType=${Uri.encodeComponent(_auditEntityTypeForJob(entityType))}&localUuid=${Uri.encodeComponent(localUuid)}',
                                    )
                                : null,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(message: '$error'),
            ),
          ],
        ),
      ),
    );
  }

  String _buildFilterLabel({
    String? entityType,
    String? localUuid,
  }) {
    final parts = <String>[];
    if (entityType != null && entityType.isNotEmpty) {
      parts.add(entityType);
    }
    if (localUuid != null && localUuid.isNotEmpty) {
      parts.add(localUuid);
    }
    return parts.join(' • ');
  }

  String _auditEntityTypeForJob(String queueEntityType) {
    return switch (queueEntityType) {
      'sales' => 'sale',
      'customer_payment' => 'receivable_payment',
      _ => queueEntityType,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final int pendingCount;
  final int failedCount;
  final int completedCount;
  final bool isBusy;
  final String? filterLabel;
  final VoidCallback? onRetryAll;

  const _SummaryCard({
    required this.pendingCount,
    required this.failedCount,
    required this.completedCount,
    required this.isBusy,
    required this.filterLabel,
    required this.onRetryAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Queue Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (filterLabel != null && filterLabel!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Filtered: $filterLabel',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountChip(label: 'Pending', value: pendingCount),
              _CountChip(label: 'Failed', value: failedCount, isError: true),
              _CountChip(label: 'Completed', value: completedCount),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onRetryAll,
              icon: isBusy
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_problem_rounded),
              label: const Text('Retry Failed'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final bool isError;

  const _CountChip({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError ? const Color(0xFFFCE8E6) : const Color(0xFFEAF4EF);
    final fg = isError ? const Color(0xFF9C2B1F) : const Color(0xFF1E6B3A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isBusy;
  final VoidCallback? onRetry;
  final VoidCallback? onForceOverwrite;
  final VoidCallback? onViewAuditLog;

  const _JobCard({
    required this.job,
    required this.isBusy,
    required this.onRetry,
    this.onForceOverwrite,
    this.onViewAuditLog,
  });

  @override
  Widget build(BuildContext context) {
    final status = (job['status'] ?? 'unknown').toString();
    final entityType = (job['entity_type'] ?? 'unknown').toString();
    final operation = (job['operation'] ?? 'unknown').toString();
    final retryCount = (job['retry_count'] as num?)?.toInt() ?? 0;
    final localUuid = (job['local_uuid'] ?? '').toString();
    final lastError = (job['last_error'] ?? '').toString();
    final updatedAt = (job['updated_at'] ?? '').toString();
    final isConflict = lastError.toLowerCase().contains('conflict');

    final statusBg = isConflict
        ? const Color(0xFFFDEBDA)
        : status == 'failed'
        ? const Color(0xFFFCE8E6)
        : const Color(0xFFFFF4DB);
    final statusFg = isConflict
        ? const Color(0xFF9A4E00)
        : status == 'failed'
        ? const Color(0xFF9C2B1F)
        : const Color(0xFF8A5A00);

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
                  '$entityType • $operation',
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isConflict ? 'conflict' : status,
                  style: TextStyle(
                    color: statusFg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Local ID: $localUuid',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Retries: $retryCount',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (updatedAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Updated: $updatedAt',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (lastError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                lastError,
                style: const TextStyle(
                  color: Color(0xFF9C2B1F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onRetry != null || onForceOverwrite != null || onViewAuditLog != null) ...[
            const SizedBox(height: 12),
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
                  if (onForceOverwrite != null)
                    FilledButton.tonal(
                      onPressed: isBusy ? null : onForceOverwrite,
                      child: const Text('Force overwrite'),
                    ),
                  if (onRetry != null)
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

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

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'No pending or failed sync jobs.',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
