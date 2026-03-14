import 'package:dswd_slp/providers/sync_provider.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:dswd_slp/views/screens/audit_log_screen.dart';
import 'package:dswd_slp/views/screens/sync_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SyncHistoryScreen opens filtered audit log for a queue job', (
    WidgetTester tester,
  ) async {
    final jobs = [
      {
        'id': 1,
        'entity_type': 'customer_payment',
        'operation': 'upsert',
        'local_uuid': 'payment-local-1',
        'retry_count': 1,
        'status': 'failed',
        'last_error': 'timeout',
        'updated_at': '2026-03-14T16:02:00.000',
      },
    ];
    final auditEntries = [
      AuditLogEntry(
        id: 'log-1',
        entityType: 'receivable_payment',
        entityId: 'payment-1',
        action: 'sync',
        deviceId: 'mobile_sync',
        occurredAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
        oldValues: null,
        newValues: const {
          'external_local_uuid': 'payment-local-1',
          'amount': 175.0,
        },
      ),
      AuditLogEntry(
        id: 'log-2',
        entityType: 'receivable_payment',
        entityId: 'payment-2',
        action: 'sync',
        deviceId: 'mobile_sync',
        occurredAt: DateTime.parse('2026-03-14T16:01:00.000Z'),
        oldValues: null,
        newValues: const {
          'external_local_uuid': 'payment-local-2',
          'amount': 90.0,
        },
      ),
    ];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SyncHistoryScreen(),
        ),
        GoRoute(
          path: '/audit_logs',
          builder: (context, state) => AuditLogScreen(
            initialEntityType: state.uri.queryParameters['entityType'],
            initialLocalUuid: state.uri.queryParameters['localUuid'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncQueueJobsProvider.overrideWith((ref) async => jobs),
          syncQueueSummaryProvider.overrideWith(
            (ref) async => const SyncQueueSummary(
              pendingCount: 0,
              failedCount: 1,
              completedCount: 0,
            ),
          ),
          auditLogEntriesProvider.overrideWith((ref) async => auditEntries),
          syncControllerProvider.overrideWith(_FakeSyncController.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'View audit log'));
    await tester.pumpAndSettle();

    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('Entity ID: payment-1'), findsOneWidget);
    expect(find.text('Entity ID: payment-2'), findsNothing);
  });
}

class _FakeSyncController extends SyncController {
  @override
  Future<void> build() async {}
}
