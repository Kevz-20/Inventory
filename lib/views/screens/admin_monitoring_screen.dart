import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../models/admin_organization_summary.dart';
import '../../models/app_organization.dart';
import '../../models/app_session_state.dart';
import '../../providers/app_session_provider.dart';
import '../../providers/admin_monitoring_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';

class AdminMonitoringScreen extends ConsumerWidget {
  const AdminMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(currentAppSessionProvider);
    final organizationSummariesAsync = ref.watch(
      adminOrganizationSummariesProvider,
    );
    final syncSummaryAsync = ref.watch(syncQueueSummaryProvider);
    final auditEntriesAsync = ref.watch(auditLogEntriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Admin Monitoring',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentAppSessionProvider);
          ref.invalidate(syncQueueSummaryProvider);
          ref.invalidate(auditLogEntriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sessionAsync.when(
              data: (session) => _SessionCard(
                session: session,
                onOrganizationSelected: (organization) => ref
                    .read(selectedOrganizationProvider.notifier)
                    .setSelectedOrganization(organization),
              ),
              loading: () => const _InfoCard(
                title: 'Loading session',
                message: 'Please wait...',
              ),
              error: (error, _) => _InfoCard(
                title: 'Unable to load session',
                message: '$error',
              ),
            ),
            const SizedBox(height: 12),
            sessionAsync.when(
              data: (session) => _OrganizationOverviewCard(
                session: session,
                organizationSummariesAsync: organizationSummariesAsync,
                syncSummaryAsync: syncSummaryAsync,
                auditEntriesAsync: auditEntriesAsync,
              ),
              loading: () => const _InfoCard(
                title: 'Loading organization overview',
                message: 'Please wait...',
              ),
              error: (error, _) => _InfoCard(
                title: 'Unable to load organization overview',
                message: '$error',
              ),
            ),
            const SizedBox(height: 12),
            syncSummaryAsync.when(
              data: (summary) => _InfoCard(
                title: 'Sync Overview',
                message:
                    'Pending: ${summary.pendingCount} • Failed: ${summary.failedCount} • Completed: ${summary.completedCount}',
              ),
              loading: () => const _InfoCard(
                title: 'Loading sync overview',
                message: 'Please wait...',
              ),
              error: (error, _) => _InfoCard(
                title: 'Unable to load sync overview',
                message: '$error',
              ),
            ),
            const SizedBox(height: 12),
            auditEntriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const _InfoCard(
                    title: 'Recent Audit',
                    message: 'No audit events found for the selected organization.',
                  );
                }

                final latest = entries.first;
                return _InfoCard(
                  title: 'Recent Audit',
                  message:
                      '${latest.action.toUpperCase()} ${latest.entityType} • ${latest.entityId}',
                );
              },
              loading: () => const _InfoCard(
                title: 'Loading audit preview',
                message: 'Please wait...',
              ),
              error: (error, _) => _InfoCard(
                title: 'Unable to load audit preview',
                message: '$error',
              ),
            ),
            const SizedBox(height: 12),
            _QuickLinks(
              onQueue: () => context.push('/sync_history'),
              onDiagnostics: () => context.push('/sync_diagnostics'),
              onAudit: () => context.push('/audit_logs'),
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Next Build Phase',
              message:
                  'This screen is the first PDO/admin monitoring shell. The next step is cross-organization monitoring and role-managed web/dashboard workflows.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AppSessionState session;
  final ValueChanged<AppOrganization> onOrganizationSelected;

  const _SessionCard({
    required this.session,
    required this.onOrganizationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = session.authenticatedSession;
    final org = session.selectedOrganization;

    if (auth == null) {
      return const _InfoCard(
        title: 'No backend session',
        message: 'Sign in with a backend account to use admin monitoring.',
      );
    }

    final activeRoles = auth.memberships
        .where((membership) => membership.status == 'active')
        .map((membership) => membership.roleCode)
        .where((role) => role.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

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
            'Monitoring Context',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('User: ${auth.email ?? auth.userId}'),
          const SizedBox(height: 6),
          Text('Organization: ${org?.name ?? 'No organization selected'}'),
          const SizedBox(height: 6),
          Text(
            'Roles: ${activeRoles.isEmpty ? 'None' : activeRoles.join(', ')}',
          ),
          if (session.organizations.length > 1) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: org?.id,
              decoration: const InputDecoration(
                labelText: 'Active organization',
                border: OutlineInputBorder(),
              ),
              items: session.organizations
                  .map(
                    (organization) => DropdownMenuItem(
                      value: organization.id,
                      child: Text(organization.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                for (final organization in session.organizations) {
                  if (organization.id == value) {
                    onOrganizationSelected(organization);
                    return;
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _OrganizationOverviewCard extends StatelessWidget {
  final AppSessionState session;
  final AsyncValue<Map<String, AdminOrganizationSummary>>
  organizationSummariesAsync;
  final AsyncValue<SyncQueueSummary> syncSummaryAsync;
  final AsyncValue<List<AuditLogEntry>> auditEntriesAsync;

  const _OrganizationOverviewCard({
    required this.session,
    required this.organizationSummariesAsync,
    required this.syncSummaryAsync,
    required this.auditEntriesAsync,
  });

  @override
  Widget build(BuildContext context) {
    final organizations = session.organizations;
    if (organizations.isEmpty) {
      return const _InfoCard(
        title: 'Organizations',
        message: 'No organizations available for this account.',
      );
    }

    final selectedOrgId = session.selectedOrganization?.id;
    final summaries = organizationSummariesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => const <String, AdminOrganizationSummary>{},
    );
    final queueLabel = syncSummaryAsync.maybeWhen<String>(
      data: (summary) =>
          '${summary.pendingCount} pending • ${summary.failedCount} failed',
      orElse: () => 'Queue unavailable',
    );
    final auditLabel = auditEntriesAsync.maybeWhen<String>(
      data: (entries) => entries.isEmpty
          ? 'No recent audit events'
          : '${entries.first.action.toUpperCase()} ${entries.first.entityType}',
      orElse: () => 'Audit unavailable',
    );

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
            'Organizations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...organizations.map((organization) {
            final isSelected = organization.id == selectedOrgId;
            final summary = summaries[organization.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OrganizationStatusCard(
                organization: organization,
                isSelected: isSelected,
                queueLabel: isSelected ? queueLabel : 'Switch to inspect queue',
                auditLabel: isSelected ? auditLabel : 'Switch to inspect audit',
                memberCount: summary?.memberCount ?? 0,
                auditCount: summary?.auditCount ?? 0,
                latestAuditAt: summary?.latestAuditAt,
                latestAuditAction: summary?.latestAuditAction,
                latestAuditEntityType: summary?.latestAuditEntityType,
                onOpenAudit: () => context.push(
                  '/audit_logs?organizationId=${Uri.encodeComponent(organization.id)}',
                ),
                onOpenDetail: () => context.push(
                  '/admin_org_detail?organizationId=${Uri.encodeComponent(organization.id)}',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OrganizationStatusCard extends StatelessWidget {
  final AppOrganization organization;
  final bool isSelected;
  final String queueLabel;
  final String auditLabel;
  final int memberCount;
  final int auditCount;
  final DateTime? latestAuditAt;
  final String? latestAuditAction;
  final String? latestAuditEntityType;
  final VoidCallback onOpenAudit;
  final VoidCallback onOpenDetail;

  const _OrganizationStatusCard({
    required this.organization,
    required this.isSelected,
    required this.queueLabel,
    required this.auditLabel,
    required this.memberCount,
    required this.auditCount,
    required this.latestAuditAt,
    required this.latestAuditAction,
    required this.latestAuditEntityType,
    required this.onOpenAudit,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.35)
        : const Color(0xFFE5E7EB);
    final background = isSelected
        ? const Color(0xFFF2FAF6)
        : const Color(0xFFFBFBFB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  organization.name,
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
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSelected ? 'active' : organization.status,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.black54,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Code: ${organization.code.isEmpty ? '—' : organization.code}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            'Members: $memberCount • Audit events: $auditCount',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            latestAuditAt == null
                ? 'Latest audit: none'
                : 'Latest audit: ${(latestAuditAction ?? 'unknown').toUpperCase()} ${(latestAuditEntityType ?? '').replaceAll('_', ' ')} • ${latestAuditAt!.toLocal()}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Queue: $queueLabel',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Audit: $auditLabel',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onOpenAudit,
                icon: const Icon(Icons.history_edu_outlined),
                label: const Text('Audit'),
              ),
              FilledButton.tonalIcon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  final VoidCallback onQueue;
  final VoidCallback onDiagnostics;
  final VoidCallback onAudit;

  const _QuickLinks({
    required this.onQueue,
    required this.onDiagnostics,
    required this.onAudit,
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
            'Quick Links',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onQueue,
                icon: const Icon(Icons.sync_alt_rounded),
                label: const Text('Queue'),
              ),
              FilledButton.tonalIcon(
                onPressed: onDiagnostics,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Diagnostics'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAudit,
                icon: const Icon(Icons.history_edu_outlined),
                label: const Text('Audit Log'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String message;

  const _InfoCard({
    required this.title,
    required this.message,
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
