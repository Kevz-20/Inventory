import 'package:dswd_slp/models/app_organization.dart';
import 'package:dswd_slp/models/app_session_state.dart';
import 'package:dswd_slp/providers/app_session_provider.dart';
import 'package:dswd_slp/providers/sync_provider.dart';
import 'package:dswd_slp/repositories/home_repository.dart';
import 'package:dswd_slp/services/db_service.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:dswd_slp/view_models/home_view_model.dart';
import 'package:dswd_slp/views/screens/audit_log_screen.dart';
import 'package:dswd_slp/views/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeScreen shows audit preview and opens audit log', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/audit_logs',
          builder: (context, state) => const AuditLogScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWith((ref) {
            return _FakeHomeViewModel()
              ..state = const HomeState(
                cashOnHand: 1200,
                mobileNumber: '09171234567',
                organizationName: 'SLPA Demo',
              );
          }),
          currentAppSessionProvider.overrideWith((ref) async {
            return const AppSessionState(
              authenticatedSession: null,
              selectedOrganization: AppOrganization(
                id: 'org-1',
                code: 'SLPA-001',
                name: 'SLPA Demo',
                status: 'active',
              ),
              isBackendMode: true,
            );
          }),
          syncQueueSummaryProvider.overrideWith(
            (ref) async => const SyncQueueSummary(
              pendingCount: 1,
              failedCount: 0,
              completedCount: 2,
            ),
          ),
          auditLogEntriesProvider.overrideWith((ref) async {
            return [
              AuditLogEntry(
                id: 'log-1',
                entityType: 'sale',
                entityId: 'sale-1',
                action: 'sync',
                deviceId: 'mobile_sync',
                occurredAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
                oldValues: null,
                newValues: const {'external_local_uuid': 'sale-local-1'},
              ),
            ];
          }),
          syncControllerProvider.overrideWith(_FakeSyncController.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Queue: 1 pending, 0 failed'), findsOneWidget);
    expect(find.textContaining('Audit: sync sale'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Audit Log'));
    await tester.pumpAndSettle();

    expect(find.byType(AuditLogScreen), findsOneWidget);
  });
}

class _FakeHomeViewModel extends HomeViewModel {
  _FakeHomeViewModel()
      : super(
          HomeRepository(DBService.instance),
        );

  @override
  Future<void> fetchHomeData() async {}
}

class _FakeSyncController extends SyncController {
  @override
  Future<void> build() async {}
}
