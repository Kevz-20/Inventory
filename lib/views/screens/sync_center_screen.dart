import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/sync_runner_service.dart';
import '../../services/sync_backend_config.dart';
import '../../services/sync_service.dart';
import '../widgets/header.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  late Future<({Map<String, int> counts, Map<String, dynamic> payload})> _data;
  bool _isRunningMockSync = false;
  bool _isRunningBackendSync = false;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<({Map<String, int> counts, Map<String, dynamic> payload})>
      _loadData() async {
    final counts = await SyncService.instance.getPendingCounts();
    final payload = await SyncService.instance.buildPendingPayload();
    return (counts: counts, payload: payload);
  }

  Future<void> _refresh() async {
    final future = _loadData();
    setState(() {
      _data = future;
    });
    await future;
  }

  Future<void> _runMockSync() async {
    if (_isRunningMockSync) return;

    setState(() {
      _isRunningMockSync = true;
    });

    try {
      final result = await SyncRunnerService.instance.runMockSync();
      await _refresh();
      if (!mounted) return;

      final summary = result.totalSynced == 0
          ? 'No pending rows to sync.'
          : 'Mock sync completed. ${result.totalSynced} row(s) marked synced.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summary),
          backgroundColor:
              result.totalSynced == 0 ? AppColors.warning : AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mock sync failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunningMockSync = false;
        });
      }
    }
  }

  Future<void> _runBackendSync() async {
    if (_isRunningBackendSync) return;

    setState(() {
      _isRunningBackendSync = true;
    });

    try {
      final result = await SyncRunnerService.instance.runBackendSync();
      await _refresh();
      if (!mounted) return;

      final summary = result.totalSynced == 0
          ? 'No pending rows to sync.'
          : 'Backend sync completed. ${result.totalSynced} row(s) marked synced.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summary),
          backgroundColor:
              result.totalSynced == 0 ? AppColors.warning : AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backend sync failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunningBackendSync = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const AppHeader(title: 'Sync Center', showBackButton: true),
      body: FutureBuilder<({Map<String, int> counts, Map<String, dynamic> payload})>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading sync data: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;
          final counts = data.counts;
          final payload = data.payload;
          final totalRecords = payload['total_records'] as int? ?? 0;
          final generatedAt = payload['generated_at']?.toString() ?? '-';
          final payloadTables = Map<String, dynamic>.from(
            payload['tables'] as Map? ?? const {},
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _summaryCard(totalRecords, generatedAt),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRunningMockSync ? null : _runMockSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isRunningMockSync
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _isRunningMockSync ? 'Running Mock Sync...' : 'Run Mock Sync',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: !SyncBackendConfig.isConfigured ||
                            _isRunningBackendSync
                        ? null
                        : _runBackendSync,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isRunningBackendSync
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_done_outlined),
                    label: Text(
                      SyncBackendConfig.isConfigured
                          ? (_isRunningBackendSync
                              ? 'Running Backend Sync...'
                              : 'Run Backend Sync')
                          : 'Configure Backend URL First',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pending Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...counts.entries.map(_countTile),
                const SizedBox(height: 20),
                const Text(
                  'Payload Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...payloadTables.entries.map(
                  (entry) => _payloadSection(
                    MapEntry(
                      entry.key,
                      (entry.value as List<dynamic>)
                          .map((row) => Map<String, dynamic>.from(row as Map))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(int totalRecords, String generatedAt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local Sync Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pending rows: $totalRecords',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generated at: $generatedAt',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countTile(MapEntry<String, int> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Text(
            '${entry.value}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          _tableLabel(entry.key),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          entry.value == 1 ? '1 pending row' : '${entry.value} pending rows',
        ),
      ),
    );
  }

  Widget _payloadSection(MapEntry<String, List<Map<String, dynamic>>> entry) {
    final records = entry.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          _tableLabel(entry.key),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          records.isEmpty ? 'No pending rows' : '${records.length} pending rows',
        ),
        children: [
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nothing to sync.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...records.take(5).map((record) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatRecord(record),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )),
          if (records.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${records.length - 5} more row(s) not shown.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _tableLabel(String table) {
    return table
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _formatRecord(Map<String, dynamic> record) {
    return record.entries
        .map((entry) => '${entry.key}: ${_stringify(entry.value)}')
        .join('\n');
  }

  String _stringify(Object? value) {
    if (value == null) return '-';
    if (value is List) return value.join(', ');
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}=${_stringify(entry.value)}')
          .join(', ');
    }
    return value.toString();
  }
}
