import 'package:dswd_slp/providers/sync_provider.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:dswd_slp/views/screens/audit_log_screen.dart';
import 'package:dswd_slp/views/screens/sync_diagnostics_screen.dart';
import 'package:dswd_slp/views/screens/sync_history_screen.dart';
import 'package:dswd_slp/views/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncDiagnosticsScreen', () {
    testWidgets('renders record details and latest queue failure metadata', (
      WidgetTester tester,
    ) async {
      final records = [
        SyncRecordDiagnostics(
          entityType: 'product',
          localId: 7,
          localUuid: 'prod-7',
          serverId: 'srv-7',
          syncStatus: 'pending_upload',
          lastSyncedAt: '2026-03-14T10:00:00.000',
          updatedAt: '2026-03-14T10:05:00.000',
          title: 'Canned Goods',
          subtitle: 'Quantity: 12',
          lastQueueError: 'backend conflict detected',
          retryCount: 3,
          queueUpdatedAt: '2026-03-14T10:06:00.000',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'product'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async => records),
            syncControllerProvider.overrideWith(_FakeSyncController.new),
          ],
          child: const MaterialApp(home: SyncDiagnosticsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sync Diagnostics'), findsOneWidget);
      expect(find.text('Canned Goods'), findsOneWidget);
      expect(find.text('Quantity: 12'), findsOneWidget);
      expect(find.text('pending_upload'), findsOneWidget);
      expect(find.text('Latest Queue Failure'), findsOneWidget);
      expect(find.text('backend conflict detected'), findsOneWidget);
      expect(find.text('Retries: 3'), findsOneWidget);
      expect(find.text('Queue updated: 2026-03-14T10:06:00.000'), findsOneWidget);
      expect(find.text('Local UUID: '), findsNothing);
      expect(find.text('Resync'), findsOneWidget);
    });

    testWidgets('tapping resync shows success snackbar', (
      WidgetTester tester,
    ) async {
      final fakeController = _FakeSyncController();
      final records = [
        SyncRecordDiagnostics(
          entityType: 'payments',
          localId: 9,
          localUuid: 'pay-9',
          serverId: null,
          syncStatus: 'pending_upload',
          lastSyncedAt: null,
          updatedAt: '2026-03-14T11:00:00.000',
          title: 'Customer payment',
          subtitle: 'Amount: 175.0',
          lastQueueError: null,
          retryCount: 0,
          queueUpdatedAt: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'payments'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async => records),
            syncControllerProvider.overrideWith(() => fakeController),
          ],
          child: const MaterialApp(home: SyncDiagnosticsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Resync'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeController.lastEntityType, 'payments');
      expect(fakeController.lastLocalUuid, 'pay-9');
      expect(find.text('Record re-synced.'), findsOneWidget);
    });

    testWidgets('tapping resync shows failure snackbar when controller errors', (
      WidgetTester tester,
    ) async {
      final fakeController = _FakeSyncController(
        errorMessage: 'network timeout',
      );
      final records = [
        SyncRecordDiagnostics(
          entityType: 'product',
          localId: 11,
          localUuid: 'prod-11',
          serverId: null,
          syncStatus: 'pending_upload',
          lastSyncedAt: null,
          updatedAt: '2026-03-14T12:00:00.000',
          title: 'Soap',
          subtitle: 'Quantity: 4',
          lastQueueError: null,
          retryCount: 0,
          queueUpdatedAt: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'product'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async => records),
            syncControllerProvider.overrideWith(() => fakeController),
          ],
          child: const MaterialApp(home: SyncDiagnosticsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Resync'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeController.lastEntityType, 'product');
      expect(fakeController.lastLocalUuid, 'prod-11');
      expect(find.text('Resync failed: network timeout'), findsOneWidget);
    });

    testWidgets('view queue job opens filtered sync history for the record', (
      WidgetTester tester,
    ) async {
      final records = [
        SyncRecordDiagnostics(
          entityType: 'payments',
          localId: 15,
          localUuid: 'pay-15',
          serverId: null,
          syncStatus: 'pending_upload',
          lastSyncedAt: null,
          updatedAt: '2026-03-14T13:00:00.000',
          title: 'Customer payment',
          subtitle: 'Amount: 200.0',
          lastQueueError: 'payment sync failed',
          retryCount: 2,
          queueUpdatedAt: '2026-03-14T13:05:00.000',
        ),
      ];
      final jobs = [
        {
          'id': 1,
          'entity_type': 'customer_payment',
          'operation': 'upsert',
          'local_uuid': 'pay-15',
          'retry_count': 2,
          'status': 'failed',
          'last_error': 'payment sync failed',
          'updated_at': '2026-03-14T13:05:00.000',
        },
        {
          'id': 2,
          'entity_type': 'customer_payment',
          'operation': 'upsert',
          'local_uuid': 'pay-99',
          'retry_count': 1,
          'status': 'failed',
          'last_error': 'other payment failed',
          'updated_at': '2026-03-14T13:06:00.000',
        },
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SyncDiagnosticsScreen(),
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
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'payments'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async => records),
            syncQueueJobsProvider.overrideWith((ref) async => jobs),
            syncQueueSummaryProvider.overrideWith(
              (ref) async => const SyncQueueSummary(
                pendingCount: 0,
                failedCount: 2,
                completedCount: 0,
              ),
            ),
            syncControllerProvider.overrideWith(_FakeSyncController.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      final viewQueueJobButton = find.widgetWithText(
        FilledButton,
        'View queue job',
      );
      await tester.ensureVisible(viewQueueJobButton);
      await tester.pumpAndSettle();
      await tester.tap(viewQueueJobButton);
      await tester.pumpAndSettle();

      expect(find.text('Sync History'), findsOneWidget);
      expect(
        find.text('Filtered: customer_payment • pay-15'),
        findsOneWidget,
      );
      expect(find.text('payment sync failed'), findsOneWidget);
      expect(find.text('other payment failed'), findsNothing);
    });

    testWidgets('tapping sync badge opens filtered diagnostics for the record', (
      WidgetTester tester,
    ) async {
      final records = [
        SyncRecordDiagnostics(
          entityType: 'customer',
          localId: 21,
          localUuid: 'cust-21',
          serverId: 'srv-21',
          syncStatus: 'pending_upload',
          lastSyncedAt: '2026-03-14T14:00:00.000',
          updatedAt: '2026-03-14T14:02:00.000',
          title: 'Maria Santos',
          subtitle: '09171234567',
          lastQueueError: null,
          retryCount: 0,
          queueUpdatedAt: null,
        ),
        SyncRecordDiagnostics(
          entityType: 'customer',
          localId: 22,
          localUuid: 'cust-22',
          serverId: 'srv-22',
          syncStatus: 'synced',
          lastSyncedAt: '2026-03-14T14:05:00.000',
          updatedAt: '2026-03-14T14:06:00.000',
          title: 'Juan Dela Cruz',
          subtitle: '09999888777',
          lastQueueError: null,
          retryCount: 0,
          queueUpdatedAt: null,
        ),
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: SyncStatusBadge(
                  syncStatus: 'pending_upload',
                  lastSyncedAt: '2026-03-14T14:00:00.000',
                  onTap: () => context.push(
                    '/sync_diagnostics?entityType=customer&localUuid=cust-21',
                  ),
                ),
              ),
            ),
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
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'customer'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async => records),
            syncControllerProvider.overrideWith(_FakeSyncController.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(SyncStatusBadge));
      await tester.pumpAndSettle();

      expect(find.text('Sync Diagnostics'), findsOneWidget);
      expect(find.text('Filtered: customer • cust-21'), findsOneWidget);
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Juan Dela Cruz'), findsNothing);
    });

    testWidgets('view audit log opens filtered audit log for the record', (
      WidgetTester tester,
    ) async {
      final records = [
        SyncRecordDiagnostics(
          entityType: 'sales',
          localId: 30,
          localUuid: 'sale-local-30',
          serverId: 'sale-30',
          syncStatus: 'synced',
          lastSyncedAt: '2026-03-14T15:00:00.000',
          updatedAt: '2026-03-14T15:02:00.000',
          title: 'Cash sale',
          subtitle: 'Total: 350.0',
          lastQueueError: null,
          retryCount: 0,
          queueUpdatedAt: null,
        ),
      ];
      final auditEntries = [
        AuditLogEntry(
          id: 'log-1',
          entityType: 'sale',
          entityId: 'sale-30',
          action: 'sync',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T15:03:00.000Z'),
          oldValues: null,
          newValues: const {
            'external_local_uuid': 'sale-local-30',
            'total_amount': 350.0,
          },
        ),
        AuditLogEntry(
          id: 'log-2',
          entityType: 'sale',
          entityId: 'sale-99',
          action: 'sync',
          deviceId: 'mobile_sync',
          occurredAt: DateTime.parse('2026-03-14T15:04:00.000Z'),
          oldValues: null,
          newValues: const {
            'external_local_uuid': 'sale-local-99',
            'total_amount': 100.0,
          },
        ),
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SyncDiagnosticsScreen(),
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
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'sales'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async => records),
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
      expect(find.text('Sync Sale'), findsOneWidget);
      expect(find.text('Entity ID: sale-30'), findsOneWidget);
      expect(find.text('Entity ID: sale-99'), findsNothing);
    });
  });
}

class _FakeSyncController extends SyncController {
  _FakeSyncController({this.errorMessage});

  String? lastEntityType;
  String? lastLocalUuid;
  final String? errorMessage;

  @override
  Future<void> build() async {}

  @override
  Future<void> resyncRecord({
    required String entityType,
    required String localUuid,
  }) async {
    lastEntityType = entityType;
    lastLocalUuid = localUuid;
    if (errorMessage != null) {
      state = AsyncError(errorMessage!, StackTrace.empty);
      return;
    }
    state = const AsyncData(null);
  }
}
