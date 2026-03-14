import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../models/app_organization.dart';
import '../../models/organization_member_summary.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';
import '../../providers/admin_monitoring_provider.dart';
import '../../providers/app_session_provider.dart';

class AdminOrganizationDetailScreen extends ConsumerStatefulWidget {
  final String organizationId;

  const AdminOrganizationDetailScreen({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<AdminOrganizationDetailScreen> createState() =>
      _AdminOrganizationDetailScreenState();
}

class _AdminOrganizationDetailScreenState
    extends ConsumerState<AdminOrganizationDetailScreen> {
  String _memberQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(currentAppSessionProvider);
    final summariesAsync = ref.watch(adminOrganizationSummariesProvider);
    final membersAsync = ref.watch(
      organizationMembersProvider(widget.organizationId),
    );
    final auditEntriesAsync = ref.watch(
      auditLogEntriesByOrganizationProvider(widget.organizationId),
    );

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Organization Detail',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          sessionAsync.when(
            data: (session) {
              AppOrganization? organization;
              for (final item in session.organizations) {
                if (item.id == widget.organizationId) {
                  organization = item;
                  break;
                }
              }
              if (organization == null) {
                return const _InfoCard(
                  title: 'Organization not found',
                  message: 'This organization is not available in the current session.',
                );
              }
              final resolvedOrganization = organization;

              return summariesAsync.when(
                data: (summaries) {
                  final summary = summaries[widget.organizationId];
                  return Column(
                    children: [
                      _InfoCard(
                        title: resolvedOrganization.name,
                        message:
                            'Code: ${resolvedOrganization.code.isEmpty ? '—' : resolvedOrganization.code}\nStatus: ${resolvedOrganization.status}',
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Monitoring Summary',
                        message:
                            'Members: ${summary?.memberCount ?? 0}\nAudit events: ${summary?.auditCount ?? 0}\nLatest audit: ${summary?.latestAuditAt?.toLocal() ?? 'none'}',
                      ),
                      const SizedBox(height: 12),
                      membersAsync.when(
                        data: (members) => Column(
                          children: [
                            _MemberBreakdownCard(members: members),
                            const SizedBox(height: 12),
                            _MembersCard(
                              members: members,
                              query: _memberQuery,
                              roleFilter: _roleFilter,
                              statusFilter: _statusFilter,
                              onQueryChanged: (value) {
                                setState(() {
                                  _memberQuery = value;
                                });
                              },
                              onRoleChanged: (value) {
                                setState(() {
                                  _roleFilter = value;
                                });
                              },
                              onStatusChanged: (value) {
                                setState(() {
                                  _statusFilter = value;
                                });
                              },
                            ),
                          ],
                        ),
                        loading: () => const _InfoCard(
                          title: 'Members',
                          message: 'Loading organization members...',
                        ),
                        error: (error, _) => _InfoCard(
                          title: 'Members',
                          message: 'Unable to load members: $error',
                        ),
                      ),
                      const SizedBox(height: 12),
                      auditEntriesAsync.when(
                        data: (entries) => _RecentActivityCard(
                          organizationId: widget.organizationId,
                          entries: entries.take(5).toList(),
                        ),
                        loading: () => const _InfoCard(
                          title: 'Recent Activity',
                          message: 'Loading recent organization activity...',
                        ),
                        error: (error, _) => _InfoCard(
                          title: 'Recent Activity',
                          message: 'Unable to load recent activity: $error',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Actions',
                        message:
                            'Use the buttons below to open organization-specific monitoring views.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => context.push(
                              '/audit_logs?organizationId=${Uri.encodeComponent(widget.organizationId)}',
                            ),
                            icon: const Icon(Icons.history_edu_outlined),
                            label: const Text('Audit Log'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => context.push(
                              '/admin_reports?organizationId=${Uri.encodeComponent(widget.organizationId)}',
                            ),
                            icon: const Icon(Icons.assessment_outlined),
                            label: const Text('Reports'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => context.push(
                              '/admin_monitoring',
                            ),
                            icon: const Icon(Icons.monitor_outlined),
                            label: const Text('Back to Monitoring'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const _InfoCard(
                  title: 'Loading organization summary',
                  message: 'Please wait...',
                ),
                error: (error, _) => _InfoCard(
                  title: 'Unable to load organization summary',
                  message: '$error',
                ),
              );
            },
            loading: () => const _InfoCard(
              title: 'Loading organization',
              message: 'Please wait...',
            ),
            error: (error, _) => _InfoCard(
              title: 'Unable to load organization',
              message: '$error',
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBreakdownCard extends StatelessWidget {
  final List<OrganizationMemberSummary> members;

  const _MemberBreakdownCard({required this.members});

  @override
  Widget build(BuildContext context) {
    final roleCounts = <String, int>{};
    final statusCounts = <String, int>{};

    for (final member in members) {
      final role = member.roleCode.isEmpty ? 'unassigned' : member.roleCode;
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;

      final status = member.status.isEmpty ? 'unknown' : member.status;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Access Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roleCounts.entries
                .map(
                  (entry) => _BreakdownChip(
                    label: _labelFor(entry.key),
                    value: entry.value,
                    color: AppColors.primary,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusCounts.entries
                .map(
                  (entry) => _BreakdownChip(
                    label: _labelFor(entry.key),
                    value: entry.value,
                    color: entry.key == 'active'
                        ? AppColors.success
                        : Colors.orange,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _labelFor(String value) {
    final normalized = value.replaceAll('_', ' ');
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

class _BreakdownChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _BreakdownChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  final List<OrganizationMemberSummary> members;
  final String query;
  final String roleFilter;
  final String statusFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;

  const _MembersCard({
    required this.members,
    required this.query,
    required this.roleFilter,
    required this.statusFilter,
    required this.onQueryChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final roles = <String>{'all', ...members.map((member) => member.roleCode)}
      ..remove('');
    final statuses = <String>{'all', ...members.map((member) => member.status)};
    final filteredMembers = members.where((member) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          member.fullName.toLowerCase().contains(normalizedQuery) ||
          (member.mobileNumber ?? '').toLowerCase().contains(normalizedQuery);
      final matchesRole = roleFilter == 'all' || member.roleCode == roleFilter;
      final matchesStatus =
          statusFilter == 'all' || member.status == statusFilter;
      return matchesQuery && matchesRole && matchesStatus;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Members',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search members',
              hintText: 'Name or mobile number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: roleFilter,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: roles
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(_filterLabel(role)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onRoleChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_filterLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (members.isEmpty)
            const Text('No members found for this organization.')
          else if (filteredMembers.isEmpty)
            const Text('No members match the current filters.')
          else
            ...filteredMembers.take(8).map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemberRow(member: member),
              ),
            ),
          if (filteredMembers.length > 8) ...[
            const SizedBox(height: 4),
            Text(
              '${filteredMembers.length - 8} more member(s) not shown',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  String _filterLabel(String value) {
    if (value == 'all') {
      return 'All';
    }
    final normalized = value.replaceAll('_', ' ');
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

class _MemberRow extends StatelessWidget {
  final OrganizationMemberSummary member;

  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final statusColor = member.status == 'active'
        ? AppColors.success
        : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  member.mobileNumber ?? 'No mobile number',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${member.roleCode.isEmpty ? '—' : member.roleCode}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              member.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final String organizationId;
  final List<AuditLogEntry> entries;

  const _RecentActivityCard({
    required this.organizationId,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Text(
              'No recent activity found for this organization.',
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecentActivityItem(
                  organizationId: organizationId,
                  entry: entry,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final String organizationId;
  final AuditLogEntry entry;

  const _RecentActivityItem({
    required this.organizationId,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final occurredAt = entry.occurredAt?.toLocal().toString() ?? 'Unknown time';
    final localUuid = _extractExternalLocalUuid(entry);
    final diagnosticsEntityType = _diagnosticsEntityType(entry.entityType);
    final queueEntityType = _queueEntityType(entry.entityType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.action.toUpperCase()} ${entry.entityType.replaceAll('_', ' ')}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Entity ID: ${entry.entityId}'),
          const SizedBox(height: 4),
          Text(
            occurredAt,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => context.push(
                  '/audit_logs?organizationId=${Uri.encodeComponent(organizationId)}',
                ),
                child: const Text('Audit log'),
              ),
              if (localUuid != null &&
                  localUuid.isNotEmpty &&
                  diagnosticsEntityType != null)
                FilledButton.tonal(
                  onPressed: () => context.push(
                    '/sync_diagnostics?entityType=${Uri.encodeComponent(diagnosticsEntityType)}&localUuid=${Uri.encodeComponent(localUuid)}',
                  ),
                  child: const Text('Diagnostics'),
                ),
              if (localUuid != null && localUuid.isNotEmpty)
                FilledButton.tonal(
                  onPressed: () => context.push(
                    '/sync_history?entityType=${Uri.encodeComponent(queueEntityType)}&localUuid=${Uri.encodeComponent(localUuid)}',
                  ),
                  child: const Text('Queue history'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _extractExternalLocalUuid(AuditLogEntry entry) {
    final newRaw = entry.newValues?['external_local_uuid'];
    if (newRaw != null && newRaw.toString().trim().isNotEmpty) {
      return newRaw.toString().trim();
    }

    final oldRaw = entry.oldValues?['external_local_uuid'];
    if (oldRaw != null && oldRaw.toString().trim().isNotEmpty) {
      return oldRaw.toString().trim();
    }

    return null;
  }

  String? _diagnosticsEntityType(String entityType) {
    switch (entityType) {
      case 'product':
        return 'product';
      case 'customer':
        return 'customer';
      case 'sale':
        return 'sales';
      case 'receivable':
        return 'receivables';
      case 'receivable_payment':
        return 'payments';
      default:
        return null;
    }
  }

  String _queueEntityType(String entityType) {
    switch (entityType) {
      case 'receivable':
        return 'sales';
      case 'receivable_payment':
        return 'customer_payment';
      default:
        return entityType;
    }
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
      width: double.infinity,
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
