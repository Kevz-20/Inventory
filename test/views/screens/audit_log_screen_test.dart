import 'package:dswd_slp/providers/sync_provider.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:dswd_slp/views/screens/audit_log_screen.dart';
import 'package:dswd_slp/views/screens/sync_diagnostics_screen.dart';
import 'package:dswd_slp/views/screens/sync_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuditLogScreen', () {
    testWidgets('renders audit log entries with values', (
      WidgetTester tester,
    ) async {
      final entries = [
        AuditLogEntry(
          id: 'log-1',
          entityType: 'sale',
          entityId: 'sale-1',
          action: 'sync',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
          oldValues: const {
            'total_amount': 100.0,
          },
          newValues: const {
            'total_amount': 150.0,
            'sale_type': 'cash',
          },
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogEntriesProvider.overrideWith((ref) async => entries),
          ],
          child: const MaterialApp(home: AuditLogScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Audit Log'), findsOneWidget);
      expect(find.text('Sync Sale'), findsOneWidget);
      expect(find.text('SYNC'), findsOneWidget);
      expect(find.text('Entity ID: sale-1'), findsOneWidget);
      expect(find.text('Device: mobile_sync'), findsOneWidget);
      expect(find.text('New values'), findsOneWidget);
      expect(find.text('Previous values'), findsOneWidget);
      expect(find.textContaining('"sale_type": "cash"'), findsOneWidget);
      expect(find.textContaining('"total_amount": 100.0'), findsOneWidget);
    });

    testWidgets('renders empty state when there are no audit events', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogEntriesProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: AuditLogScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No audit events yet'), findsOneWidget);
      expect(
        find.text(
          'Recent synced backend changes will appear here for the selected organization.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('filters audit events by action', (WidgetTester tester) async {
      final entries = [
        AuditLogEntry(
          id: 'log-1',
          entityType: 'sale',
          entityId: 'sale-1',
          action: 'sync',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
          oldValues: null,
          newValues: const {'total_amount': 150.0},
        ),
        AuditLogEntry(
          id: 'log-2',
          entityType: 'customer',
          entityId: 'customer-1',
          action: 'create',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T16:05:00.000Z'),
          oldValues: null,
          newValues: const {'first_name': 'Maria'},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogEntriesProvider.overrideWith((ref) async => entries),
          ],
          child: const MaterialApp(home: AuditLogScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sync Sale'), findsOneWidget);
      expect(find.text('Create Customer'), findsOneWidget);

      await tester.tap(find.text('All').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sync').last);
      await tester.pumpAndSettle();

      expect(find.text('Sync Sale'), findsOneWidget);
      expect(find.text('Create Customer'), findsNothing);
    });

    testWidgets('filters audit events by entity type', (
      WidgetTester tester,
    ) async {
      final entries = [
        AuditLogEntry(
          id: 'log-1',
          entityType: 'sale',
          entityId: 'sale-1',
          action: 'sync',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
          oldValues: null,
          newValues: const {'total_amount': 150.0},
        ),
        AuditLogEntry(
          id: 'log-2',
          entityType: 'customer',
          entityId: 'customer-1',
          action: 'create',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T16:05:00.000Z'),
          oldValues: null,
          newValues: const {'first_name': 'Maria'},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogEntriesProvider.overrideWith((ref) async => entries),
          ],
          child: const MaterialApp(home: AuditLogScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sync Sale'), findsOneWidget);
      expect(find.text('Create Customer'), findsOneWidget);

      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer').last);
      await tester.pumpAndSettle();

      expect(find.text('Sync Sale'), findsNothing);
      expect(find.text('Create Customer'), findsOneWidget);
    });

    testWidgets('shows empty filtered state when no audit events match', (
      WidgetTester tester,
    ) async {
      final entries = [
        AuditLogEntry(
          id: 'log-1',
          entityType: 'sale',
          entityId: 'sale-1',
          action: 'sync',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
          oldValues: null,
          newValues: const {'total_amount': 150.0},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogEntriesProvider.overrideWith((ref) async => entries),
          ],
          child: const MaterialApp(
            home: AuditLogScreen(initialEntityType: 'customer'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No matching audit events'), findsOneWidget);
      expect(find.text('Try changing the current filters.'), findsOneWidget);
      expect(find.text('Sync Sale'), findsNothing);
    });

    testWidgets('audit entry opens filtered sync diagnostics when local uuid exists', (
      WidgetTester tester,
    ) async {
      final entries = [
        AuditLogEntry(
          id: 'log-1',
          entityType: 'sale',
          entityId: 'sale-1',
          action: 'sync',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
          oldValues: null,
          newValues: const {
            'external_local_uuid': 'sale-local-1',
            'total_amount': 150.0,
          },
        ),
      ];
      final records = [
        SyncRecordDiagnostics(
          entityType: 'sales',
          localId: 1,
          localUuid: 'sale-local-1',
          serverId: 'sale-1',
          syncStatus: 'synced',
          lastSyncedAt: '2026-03-14T16:01:00.000',
          updatedAt: '2026-03-14T16:00:00.000',
          title: 'Cash sale',
          subtitle: 'Total: 150.0',
          lastQueueError: null,
          retryCount: 0,
          queueUpdatedAt: null,
        ),
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AuditLogScreen(),
          ),
          GoRoute(
            path: '/sync_diagnostics',
            builder: (context, state) => SyncDiagnosticsScreen(
              initialEntityType: state.uri.queryParameters['entityType'],
              initialLocalUuid: state.uri.queryParameters['localUuid'],
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogEntriesProvider.overrideWith((ref) async => entries),
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'sales'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async => records),
            syncControllerProvider.overrideWith(_FakeSyncController.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Open sync diagnostics'));
      await tester.pumpAndSettle();

      expect(find.text('Sync Diagnostics'), findsOneWidget);
      expect(find.text('Filtered: sales • sale-local-1'), findsOneWidget);
      expect(find.text('Cash sale'), findsOneWidget);
    });

    testWidgets('audit entry opens filtered queue history when local uuid exists', (
      WidgetTester tester,
    ) async {
      final entries = [
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
      ];
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
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AuditLogScreen(),
          ),
          GoRoute(
            path: '/sync_history',
            builder: (context, state) => SyncHistoryScreen(
              initialEntityType: state.uri.queryParameters['entityType'],
              initialLocalUuid: state.uri.queryParameters['localUuid'],
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogEntriesProvider.overrideWith((ref) async => entries),
            syncQueueJobsProvider.overrideWith((ref) async => jobs),
            syncQueueSummaryProvider.overrideWith(
              (ref) async => const SyncQueueSummary(
                pendingCount: 0,
                failedCount: 1,
                completedCount: 0,
              ),
            ),
            syncControllerProvider.overrideWith(_FakeSyncController.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Open queue history'));
      await tester.pumpAndSettle();

      expect(find.text('Sync History'), findsOneWidget);
      expect(
        find.text('Filtered: customer_payment • payment-local-1'),
        findsOneWidget,
      );
      expect(find.text('timeout'), findsOneWidget);
    });
  });
}

class _FakeSyncController extends SyncController {
  @override
  Future<void> build() async {}
}
