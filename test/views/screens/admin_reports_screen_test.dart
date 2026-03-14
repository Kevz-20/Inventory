import 'package:dswd_slp/models/admin_organization_summary.dart';
import 'package:dswd_slp/models/admin_financial_summary.dart';
import 'package:dswd_slp/models/app_organization.dart';
import 'package:dswd_slp/models/app_session_state.dart';
import 'package:dswd_slp/providers/admin_monitoring_provider.dart';
import 'package:dswd_slp/providers/app_session_provider.dart';
import 'package:dswd_slp/providers/sync_provider.dart';
import 'package:dswd_slp/services/sync_service.dart';
import 'package:dswd_slp/views/screens/admin_reports_screen.dart';
import 'package:dswd_slp/views/screens/sync_diagnostics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminReportsScreen', () {
    testWidgets('renders reporting snapshot and recent backend activity', (
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
              return {
                'org-1': AdminOrganizationSummary(
                  organizationId: 'org-1',
                  memberCount: 4,
                  auditCount: 9,
                  latestAuditAt: DateTime.parse('2026-03-14T16:00:00.000Z'),
                  latestAuditAction: 'sync',
                  latestAuditEntityType: 'sale',
                ),
              };
            }),
            adminFinancialSummaryProvider.overrideWith(
              (ref, organizationId) async => const AdminFinancialSummary(
                organizationId: 'org-1',
                totalSales: 2500,
                outstandingReceivables: 700,
                collectedPayments: 1800,
                salesCount: 12,
                unpaidReceivablesCount: 3,
              ),
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
                    'total_amount': 150.0,
                  },
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: AdminReportsScreen(organizationId: 'org-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Admin Reports'), findsOneWidget);
      expect(find.text('SLPA Demo'), findsOneWidget);
      expect(find.text('Reporting Snapshot'), findsOneWidget);
      expect(find.text('Members: 4'), findsOneWidget);
      expect(find.text('Audit Events: 9'), findsOneWidget);
      expect(find.text('Latest Action: SYNC'), findsOneWidget);
      expect(find.text('Financial Summary'), findsOneWidget);
      expect(find.text('Total Sales: ₱2500.00'), findsOneWidget);
      expect(find.text('Collected: ₱1800.00'), findsOneWidget);
      expect(find.text('Outstanding: ₱700.00'), findsOneWidget);
      expect(find.text('Sales records: 12\nOpen receivables: 3'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Copy Snapshot'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save CSV'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save PDF'), findsOneWidget);
      expect(find.text('Recent Backend Activity'), findsOneWidget);
      expect(find.text('SYNC • sale'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Diagnostics'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Queue'), findsOneWidget);
    });

    testWidgets('copy snapshot shows success status', (
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
                  memberCount: 1,
                  auditCount: 1,
                ),
              };
            }),
            adminFinancialSummaryProvider.overrideWith(
              (ref, organizationId) async => const AdminFinancialSummary(
                organizationId: 'org-1',
                totalSales: 1000,
                outstandingReceivables: 250,
                collectedPayments: 750,
                salesCount: 4,
                unpaidReceivablesCount: 1,
              ),
            ),
            auditLogEntriesByOrganizationProvider.overrideWith(
              (ref, organizationId) async => const <AuditLogEntry>[],
            ),
          ],
          child: const MaterialApp(
            home: AdminReportsScreen(organizationId: 'org-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.widgetWithText(FilledButton, 'Copy Snapshot');
      expect(copyButton, findsOneWidget);
      await tester.ensureVisible(copyButton);
      await tester.pumpAndSettle();
      await tester.tap(copyButton);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('admin_reports_copy_status')),
        findsOneWidget,
      );
      expect(find.text('Admin report snapshot copied'), findsOneWidget);
    });

    testWidgets('recent backend activity opens diagnostics for matching local uuid', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const AdminReportsScreen(organizationId: 'org-1'),
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
            adminFinancialSummaryProvider.overrideWith(
              (ref, organizationId) async => const AdminFinancialSummary(
                organizationId: 'org-1',
              ),
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

      final diagnosticsButton = find.widgetWithText(OutlinedButton, 'Diagnostics');
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
