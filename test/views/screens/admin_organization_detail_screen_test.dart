import 'package:dswd_slp/models/admin_organization_summary.dart';
import 'package:dswd_slp/models/app_organization.dart';
import 'package:dswd_slp/models/app_session_state.dart';
import 'package:dswd_slp/models/organization_member_summary.dart';
import 'package:dswd_slp/providers/admin_monitoring_provider.dart';
import 'package:dswd_slp/providers/app_session_provider.dart';
import 'package:dswd_slp/providers/sync_provider.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:dswd_slp/views/screens/admin_organization_detail_screen.dart';
import 'package:dswd_slp/views/screens/audit_log_screen.dart';
import 'package:dswd_slp/views/screens/sync_diagnostics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminOrganizationDetailScreen', () {
    testWidgets('filters members by search and role', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAppSessionProvider.overrideWith((ref) async {
              return const AppSessionState(
                authenticatedSession: null,
                selectedOrganization: AppOrganization(
                  id: 'org-1',
                  code: 'SLPA-001',
                  name: 'SLPA Demo',
                  status: 'active',
                ),
                organizations: [
                  AppOrganization(
                    id: 'org-1',
                    code: 'SLPA-001',
                    name: 'SLPA Demo',
                    status: 'active',
                  ),
                ],
                isBackendMode: true,
              );
            }),
            adminOrganizationSummariesProvider.overrideWith((ref) async {
              return const {
                'org-1': AdminOrganizationSummary(
                  organizationId: 'org-1',
                  memberCount: 2,
                  auditCount: 1,
                ),
              };
            }),
            organizationMembersProvider.overrideWith((ref, organizationId) async {
              return const [
                OrganizationMemberSummary(
                  membershipId: 'm1',
                  userId: 'u1',
                  fullName: 'Maria Santos',
                  mobileNumber: '09171234567',
                  roleCode: 'pdo_consultant',
                  status: 'active',
                ),
                OrganizationMemberSummary(
                  membershipId: 'm2',
                  userId: 'u2',
                  fullName: 'Juan Dela Cruz',
                  mobileNumber: '09999888777',
                  roleCode: 'slpa_member',
                  status: 'inactive',
                ),
              ];
            }),
            auditLogEntriesByOrganizationProvider.overrideWith(
              (ref, organizationId) async => const <AuditLogEntry>[],
            ),
          ],
          child: const MaterialApp(
            home: AdminOrganizationDetailScreen(organizationId: 'org-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Juan Dela Cruz'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Maria');
      await tester.pumpAndSettle();
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Juan Dela Cruz'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      final roleDropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(roleDropdown);
      await tester.pumpAndSettle();
      await tester.tap(roleDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pdo consultant').last);
      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Juan Dela Cruz'), findsNothing);
    });

    testWidgets('recent activity opens diagnostics for matching local uuid', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const AdminOrganizationDetailScreen(organizationId: 'org-1'),
          ),
          GoRoute(
            path: '/sync_diagnostics',
            builder: (context, state) => SyncDiagnosticsScreen(
              initialEntityType: state.uri.queryParameters['entityType'],
              initialLocalUuid: state.uri.queryParameters['localUuid'],
            ),
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
            currentAppSessionProvider.overrideWith((ref) async {
              return const AppSessionState(
                authenticatedSession: null,
                selectedOrganization: AppOrganization(
                  id: 'org-1',
                  code: 'SLPA-001',
                  name: 'SLPA Demo',
                  status: 'active',
                ),
                organizations: [
                  AppOrganization(
                    id: 'org-1',
                    code: 'SLPA-001',
                    name: 'SLPA Demo',
                    status: 'active',
                  ),
                ],
                isBackendMode: true,
              );
            }),
            adminOrganizationSummariesProvider.overrideWith((ref) async {
              return const {
                'org-1': AdminOrganizationSummary(
                  organizationId: 'org-1',
                  memberCount: 1,
                  auditCount: 1,
                ),
              };
            }),
            organizationMembersProvider.overrideWith(
              (ref, organizationId) async => const <OrganizationMemberSummary>[],
            ),
            auditLogEntriesByOrganizationProvider.overrideWith(
              (ref, organizationId) async => [
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
                  },
                ),
              ],
            ),
            syncDiagnosticsEntityProvider.overrideWith((ref) => 'sales'),
            syncRecordDiagnosticsProvider.overrideWith((ref) async {
              return const [
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
            }),
            syncControllerProvider.overrideWith(_FakeSyncController.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      final diagnosticsButton = find.widgetWithText(FilledButton, 'Diagnostics');
      await tester.ensureVisible(diagnosticsButton);
      await tester.pumpAndSettle();
      await tester.tap(diagnosticsButton);
      await tester.pumpAndSettle();

      expect(find.text('Sync Diagnostics'), findsOneWidget);
      expect(find.text('Filtered: sales • sale-local-1'), findsOneWidget);
      expect(find.text('Cash sale'), findsOneWidget);
    });
  });
}

class _FakeSyncController extends SyncController {
  @override
  Future<void> build() async {}
}
