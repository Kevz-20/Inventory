import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  final String? initialOrganizationId;
  final String? initialEntityType;
  final String? initialLocalUuid;

  const AuditLogScreen({
    super.key,
    this.initialOrganizationId,
    this.initialEntityType,
    this.initialLocalUuid,
  });

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _actionFilter = 'all';
  String _entityFilter = 'all';

  @override
  void initState() {
    super.initState();
    final initialEntityType = widget.initialEntityType;
    if (initialEntityType != null && initialEntityType.isNotEmpty) {
      _entityFilter = initialEntityType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = widget.initialOrganizationId != null &&
            widget.initialOrganizationId!.isNotEmpty
        ? ref.watch(
            auditLogEntriesByOrganizationProvider(widget.initialOrganizationId!),
          )
        : ref.watch(auditLogEntriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Audit Log',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(auditLogEntriesProvider);
        },
        child: logsAsync.when(
          data: (logs) {
            final filteredLogs = logs.where((entry) {
              final actionMatches =
                  _actionFilter == 'all' || entry.action == _actionFilter;
              final entityMatches =
                  _entityFilter == 'all' || entry.entityType == _entityFilter;
              final localUuidMatches =
                  widget.initialLocalUuid == null ||
                  widget.initialLocalUuid!.isEmpty ||
                  _entryLocalUuid(entry.newValues) ==
                      widget.initialLocalUuid ||
                  _entryLocalUuid(entry.oldValues) ==
                      widget.initialLocalUuid;
              return actionMatches && entityMatches && localUuidMatches;
            }).toList();

            if (logs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _InfoCard(
                    title: 'No audit events yet',
                    message:
                        'Recent synced backend changes will appear here for the selected organization.',
                  ),
                ],
              );
            }

            final availableActions = <String>{
              'all',
              _actionFilter,
              ...logs.map((entry) => entry.action),
            }.toList()
              ..sort();
            final availableEntities = <String>{
              'all',
              _entityFilter,
              ...logs.map((entry) => entry.entityType),
            }.toList()
              ..sort();

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredLogs.isEmpty ? 2 : filteredLogs.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AuditFilterCard(
                    actionFilter: _actionFilter,
                    entityFilter: _entityFilter,
                    availableActions: availableActions,
                    availableEntities: availableEntities,
                    onActionChanged: (value) {
                      setState(() {
                        _actionFilter = value;
                      });
                    },
                    onEntityChanged: (value) {
                      setState(() {
                        _entityFilter = value;
                      });
                    },
                  );
                }

                if (filteredLogs.isEmpty) {
                  return const _InfoCard(
                    title: 'No matching audit events',
                    message: 'Try changing the current filters.',
                  );
                }

                final log = filteredLogs[index - 1];
                return _AuditLogCard(entry: log);
              },
            );
          },
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _InfoCard(title: 'Loading audit events', message: 'Please wait...'),
            ],
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(
                title: 'Unable to load audit events',
                message: '$error',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _entryLocalUuid(Map<String, dynamic>? values) {
    if (values == null) {
      return null;
    }
    final raw = values['external_local_uuid'];
    if (raw == null) {
      return null;
    }
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }
}

class _AuditFilterCard extends StatelessWidget {
  final String actionFilter;
  final String entityFilter;
  final List<String> availableActions;
  final List<String> availableEntities;
  final ValueChanged<String> onActionChanged;
  final ValueChanged<String> onEntityChanged;

  const _AuditFilterCard({
    required this.actionFilter,
    required this.entityFilter,
    required this.availableActions,
    required this.availableEntities,
    required this.onActionChanged,
    required this.onEntityChanged,
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
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: actionFilter,
            decoration: const InputDecoration(
              labelText: 'Action',
              border: OutlineInputBorder(),
            ),
            items: availableActions
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_labelForFilter(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onActionChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: entityFilter,
            decoration: const InputDecoration(
              labelText: 'Entity',
              border: OutlineInputBorder(),
            ),
            items: availableEntities
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_labelForFilter(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onEntityChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }

  String _labelForFilter(String value) {
    if (value == 'all') {
      return 'All';
    }
    final normalized = value.replaceAll('_', ' ');
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditLogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final occurredAt = entry.occurredAt?.toLocal().toString() ?? 'Unknown time';
    final chipColor = _chipColor(entry.action);
    final diagnosticsEntityType = _diagnosticsEntityType(entry.entityType);
    final diagnosticsLocalUuid = _diagnosticsLocalUuid(entry);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _titleFor(entry),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.action.toUpperCase(),
                  style: TextStyle(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            occurredAt,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Entity ID: ${entry.entityId}',
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
          if (entry.deviceId != null && entry.deviceId!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Device: ${entry.deviceId}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
          if (entry.newValues != null && entry.newValues!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _JsonBlock(label: 'New values', value: entry.newValues!),
          ],
          if (entry.oldValues != null && entry.oldValues!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _JsonBlock(label: 'Previous values', value: entry.oldValues!),
          ],
          if (diagnosticsEntityType != null && diagnosticsLocalUuid != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(
                      '/sync_diagnostics?entityType=${Uri.encodeComponent(diagnosticsEntityType)}&localUuid=${Uri.encodeComponent(diagnosticsLocalUuid)}',
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Open sync diagnostics'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(
                      '/sync_history?entityType=${Uri.encodeComponent(_queueEntityType(entry.entityType))}&localUuid=${Uri.encodeComponent(diagnosticsLocalUuid)}',
                    ),
                    icon: const Icon(Icons.sync_alt_rounded),
                    label: const Text('Open queue history'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _titleFor(AuditLogEntry entry) {
    final entity = entry.entityType.replaceAll('_', ' ');
    return '${_capitalize(entry.action)} ${_capitalize(entity)}';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Color _chipColor(String action) {
    switch (action) {
      case 'create':
        return AppColors.success;
      case 'delete':
        return Colors.red;
      case 'sync':
        return AppColors.primary;
      default:
        return Colors.blueGrey;
    }
  }

  String? _diagnosticsLocalUuid(AuditLogEntry entry) {
    final newUuid = _extractExternalLocalUuid(entry.newValues);
    if (newUuid != null && newUuid.isNotEmpty) {
      return newUuid;
    }
    final oldUuid = _extractExternalLocalUuid(entry.oldValues);
    if (oldUuid != null && oldUuid.isNotEmpty) {
      return oldUuid;
    }
    return null;
  }

  String? _extractExternalLocalUuid(Map<String, dynamic>? values) {
    if (values == null) {
      return null;
    }
    final raw = values['external_local_uuid'];
    if (raw == null) {
      return null;
    }
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
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

class _JsonBlock extends StatelessWidget {
  final String label;
  final Map<String, dynamic> value;

  const _JsonBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfff7f7f7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            encoder.convert(value),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String message;

  const _InfoCard({required this.title, required this.message});

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
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
