import 'package:dswd_slp/models/admin_organization_summary.dart';
import 'package:dswd_slp/models/app_organization.dart';
import 'package:dswd_slp/models/app_session_state.dart';
import 'package:dswd_slp/models/app_user_profile.dart';
import 'package:dswd_slp/models/authenticated_session.dart';
import 'package:dswd_slp/models/organization_membership_model.dart';
import 'package:dswd_slp/providers/admin_monitoring_provider.dart';
import 'package:dswd_slp/providers/app_session_provider.dart';
import 'package:dswd_slp/providers/sync_provider.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:dswd_slp/views/screens/admin_monitoring_screen.dart';
import 'package:dswd_slp/views/screens/admin_organization_detail_screen.dart';
import 'package:dswd_slp/views/screens/audit_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminMonitoringScreen', () {
    testWidgets('renders organization cards with summary data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAppSessionProvider.overrideWith((ref) async => _session()),
            adminOrganizationSummariesProvider.overrideWith((ref) async {
              return {
                'org-1': AdminOrganizationSummary(
                  organizationId: 'org-1',
                  memberCount: 3,
                  auditCount: 5,
                  latestAuditAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
                  latestAuditAction: 'sync',
                  latestAuditEntityType: 'sale',
                ),
                'org-2': const AdminOrganizationSummary(
                  organizationId: 'org-2',
                  memberCount: 2,
                  auditCount: 1,
                ),
              };
            }),
            syncQueueSummaryProvider.overrideWith(
              (ref) async => const SyncQueueSummary(
                pendingCount: 2,
                failedCount: 1,
                completedCount: 7,
              ),
            ),
            auditLogEntriesProvider.overrideWith((ref) async => [
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
            ]),
            selectedOrganizationProvider.overrideWith(_FakeSelectedOrganization.new),
          ],
          child: const MaterialApp(home: AdminMonitoringScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Admin Monitoring'), findsOneWidget);
      expect(find.text('SLPA Demo'), findsWidgets);
      expect(find.text('Members: 3 • Audit events: 5'), findsOneWidget);
      expect(find.text('Members: 2 • Audit events: 1'), findsOneWidget);
      expect(find.textContaining('Latest audit: SYNC sale'), findsOneWidget);
    });

    testWidgets('organization card opens audit and detail routes', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AdminMonitoringScreen(),
          ),
          GoRoute(
            path: '/audit_logs',
            builder: (context, state) => AuditLogScreen(
              initialOrganizationId: state.uri.queryParameters['organizationId'],
            ),
          ),
          GoRoute(
            path: '/admin_org_detail',
            builder: (context, state) => AdminOrganizationDetailScreen(
              organizationId: state.uri.queryParameters['organizationId'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAppSessionProvider.overrideWith((ref) async => _session()),
            adminOrganizationSummariesProvider.overrideWith((ref) async {
              return const {
                'org-1': AdminOrganizationSummary(
                  organizationId: 'org-1',
                  memberCount: 3,
                  auditCount: 5,
                ),
                'org-2': AdminOrganizationSummary(
                  organizationId: 'org-2',
                  memberCount: 2,
                  auditCount: 1,
                ),
              };
            }),
            syncQueueSummaryProvider.overrideWith(
              (ref) async => const SyncQueueSummary(),
            ),
            auditLogEntriesProvider.overrideWith((ref) async => const []),
            auditLogEntriesByOrganizationProvider.overrideWith(
              (ref, organizationId) async => const [],
            ),
            organizationMembersProvider.overrideWith(
              (ref, organizationId) async => const [],
            ),
            selectedOrganizationProvider.overrideWith(_FakeSelectedOrganization.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Audit').first);
      await tester.pumpAndSettle();
      expect(find.byType(AuditLogScreen), findsOneWidget);

      router.go('/');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Details').first);
      await tester.pumpAndSettle();
      expect(find.byType(AdminOrganizationDetailScreen), findsOneWidget);
    });
  });
}

AppSessionState _session() {
  return AppSessionState(
    authenticatedSession: AuthenticatedSession(
      userId: 'user-1',
      email: 'pdo@example.com',
      profile: const AppUserProfile(
        id: 'user-1',
        mobileNumber: '09171234567',
        firstName: 'PDO',
        middleName: null,
        lastName: 'User',
        status: 'active',
      ),
      memberships: const [
        OrganizationMembershipModel(
          id: 'm1',
          organizationId: 'org-1',
          userId: 'user-1',
          roleCode: 'pdo_consultant',
          status: 'active',
        ),
        OrganizationMembershipModel(
          id: 'm2',
          organizationId: 'org-2',
          userId: 'user-1',
          roleCode: 'pdo_consultant',
          status: 'active',
        ),
      ],
    ),
    selectedOrganization: const AppOrganization(
      id: 'org-1',
      code: 'SLPA-001',
      name: 'SLPA Demo',
      status: 'active',
    ),
    organizations: const [
      AppOrganization(
        id: 'org-1',
        code: 'SLPA-001',
        name: 'SLPA Demo',
        status: 'active',
      ),
      AppOrganization(
        id: 'org-2',
        code: 'SLPA-002',
        name: 'SLPA North',
        status: 'active',
      ),
    ],
    isBackendMode: true,
  );
}

class _FakeSelectedOrganization extends SelectedOrganizationNotifier {
  @override
  Future<AppOrganization?> build() async {
    return const AppOrganization(
      id: 'org-1',
      code: 'SLPA-001',
      name: 'SLPA Demo',
      status: 'active',
    );
  }
}
