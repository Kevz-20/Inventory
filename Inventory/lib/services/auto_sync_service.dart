import 'dart:async';
import 'dart:io';

import 'sync_backend_config.dart';
import 'sync_runner_service.dart';
import 'sync_service.dart';

class AutoSyncService {
  AutoSyncService._();

  static final AutoSyncService instance = AutoSyncService._();

  bool _isRunning = false;
  DateTime? _lastRunAt;

  Future<bool> tryAutoSync({bool force = false}) async {
    if (_isRunning) return false;
    if (!SyncBackendConfig.isConfigured) return false;

    if (!force && _lastRunAt != null) {
      final elapsed = DateTime.now().difference(_lastRunAt!);
      if (elapsed < const Duration(seconds: 15)) {
        return false;
      }
    }

    final counts = await SyncService.instance.getPendingCounts();
    final totalPending = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (totalPending == 0) {
      _lastRunAt = DateTime.now();
      return false;
    }

    final reachable = await _isBackendReachable();
    if (!reachable) return false;

    _isRunning = true;
    try {
      final result = await SyncRunnerService.instance.runBackendSync();
      _lastRunAt = DateTime.now();
      return result.totalSynced > 0;
    } finally {
      _isRunning = false;
    }
  }

  Future<bool> _isBackendReachable() async {
    final baseUrl = SyncBackendConfig.baseUrl.trim();
    if (baseUrl.isEmpty) return false;

    final uri = Uri.parse(
      '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/health',
    );

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 3);

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
