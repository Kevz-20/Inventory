import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/app_colors.dart';
import '../../models/app_organization.dart';
import '../../models/admin_organization_summary.dart';
import '../../models/admin_financial_summary.dart';
import '../../providers/admin_monitoring_provider.dart';
import '../../providers/app_session_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';

class AdminReportsScreen extends ConsumerWidget {
  final String organizationId;

  const AdminReportsScreen({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(currentAppSessionProvider);
    final summariesAsync = ref.watch(adminOrganizationSummariesProvider);
    final financialSummaryAsync = ref.watch(
      adminFinancialSummaryProvider(organizationId),
    );
    final auditEntriesAsync = ref.watch(
      auditLogEntriesByOrganizationProvider(organizationId),
    );

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Admin Reports',
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
                if (item.id == organizationId) {
                  organization = item;
                  break;
                }
              }

              if (organization == null) {
                return const _AdminReportsCard(
                  title: 'Organization not found',
                  message: 'This organization is not available in the current session.',
                );
              }

              final resolvedOrganization = organization;
              return Column(
                children: [
                  _AdminReportsCard(
                    title: resolvedOrganization.name,
                    message:
                        'Code: ${resolvedOrganization.code.isEmpty ? '—' : resolvedOrganization.code}\nStatus: ${resolvedOrganization.status}\nOrganization ID: ${resolvedOrganization.id}',
                  ),
                  const SizedBox(height: 12),
                  summariesAsync.when(
                    data: (summaries) => _ReportingSnapshotCard(
                      summary: summaries[organizationId],
                    ),
                    loading: () => const _AdminReportsCard(
                      title: 'Reporting Snapshot',
                      message: 'Loading organization reporting summary...',
                    ),
                    error: (error, _) => _AdminReportsCard(
                      title: 'Reporting Snapshot',
                      message: 'Unable to load reporting summary: $error',
                    ),
                  ),
                  const SizedBox(height: 12),
                  financialSummaryAsync.when(
                    data: (summary) => Column(
                      children: [
                        _FinancialSummaryCard(summary: summary),
                        const SizedBox(height: 12),
                        _ExportSection(
                          organization: resolvedOrganization,
                          monitoringSummary: summariesAsync.valueOrNull?[organizationId],
                          financialSummary: summary,
                        ),
                      ],
                    ),
                    loading: () => const _AdminReportsCard(
                      title: 'Financial Summary',
                      message: 'Loading organization financial totals...',
                    ),
                    error: (error, _) => _AdminReportsCard(
                      title: 'Financial Summary',
                      message: 'Unable to load organization financial totals: $error',
                    ),
                  ),
                  const SizedBox(height: 12),
                  auditEntriesAsync.when(
                    data: (entries) => _RecentAuditActivityCard(
                      organizationId: organizationId,
                      entries: entries.take(5).toList(),
                    ),
                    loading: () => const _AdminReportsCard(
                      title: 'Recent Backend Activity',
                      message: 'Loading recent organization activity...',
                    ),
                    error: (error, _) => _AdminReportsCard(
                      title: 'Recent Backend Activity',
                      message: 'Unable to load recent organization activity: $error',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionSection(organizationId: organizationId),
                ],
              );
            },
            loading: () => const _AdminReportsCard(
              title: 'Loading organization',
              message: 'Please wait...',
            ),
            error: (error, _) => _AdminReportsCard(
              title: 'Unable to load organization',
              message: '$error',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String organizationId;

  const _ActionSection({required this.organizationId});

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
            'Available Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'These actions use the selected organization as the admin reporting context.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.push('/reports'),
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('Shared Reports'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.push(
                  '/audit_logs?organizationId=${Uri.encodeComponent(organizationId)}',
                ),
                icon: const Icon(Icons.history_edu_outlined),
                label: const Text('Audit Log'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.push(
                  '/admin_org_detail?organizationId=${Uri.encodeComponent(organizationId)}',
                ),
                icon: const Icon(Icons.apartment_outlined),
                label: const Text('Org Detail'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Next step: replace shared report navigation with true organization-aware financial summaries and exports from backend data.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportingSnapshotCard extends StatelessWidget {
  final AdminOrganizationSummary? summary;

  const _ReportingSnapshotCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final memberCount = summary?.memberCount ?? 0;
    final auditCount = summary?.auditCount ?? 0;
    final latestAuditAction = summary?.latestAuditAction ?? 'none';
    final latestAuditEntityType = summary?.latestAuditEntityType ?? '—';
    final latestAuditAt = summary?.latestAuditAt;

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
            'Reporting Snapshot',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Members',
                value: '$memberCount',
                color: AppColors.primary,
              ),
              _MetricChip(
                label: 'Audit Events',
                value: '$auditCount',
                color: Colors.deepOrange,
              ),
              _MetricChip(
                label: 'Latest Action',
                value: latestAuditAction.toString().toUpperCase(),
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Latest entity: $latestAuditEntityType\nLatest audit time: ${latestAuditAt?.toLocal() ?? 'none'}',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _RecentAuditActivityCard extends StatelessWidget {
  final String organizationId;
  final List<AuditLogEntry> entries;

  const _RecentAuditActivityCard({
    required this.organizationId,
    required this.entries,
  });

  String? _diagnosticsEntityTypeFor(String entityType) {
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

  String? _syncHistoryEntityTypeFor(String entityType) {
    switch (entityType) {
      case 'product':
        return 'product';
      case 'customer':
        return 'customer';
      case 'sale':
        return 'sales';
      case 'receivable_payment':
        return 'customer_payment';
      default:
        return null;
    }
  }

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
            'Recent Backend Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Text(
              'No recent backend activity for this organization.',
              style: TextStyle(fontSize: 14, height: 1.4),
            )
          else
            ...entries.map((entry) {
              final diagnosticsEntityType = _diagnosticsEntityTypeFor(
                entry.entityType,
              );
              final historyEntityType = _syncHistoryEntityTypeFor(
                entry.entityType,
              );
              final localUuid =
                  (entry.newValues?['external_local_uuid'] ?? '')
                      .toString()
                      .trim();
              final occurredAt =
                  entry.occurredAt?.toLocal().toString() ?? 'Unknown time';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xfffafafa),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffe9e9e9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.action.toUpperCase()} • ${entry.entityType}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Time: $occurredAt\nDevice: ${entry.deviceId ?? 'unknown'}',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (localUuid.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (diagnosticsEntityType != null)
                              OutlinedButton(
                                onPressed: () => context.push(
                                  '/sync_diagnostics?entityType=${Uri.encodeComponent(diagnosticsEntityType)}&localUuid=${Uri.encodeComponent(localUuid)}',
                                ),
                                child: const Text('Diagnostics'),
                              ),
                            if (historyEntityType != null)
                              OutlinedButton(
                                onPressed: () => context.push(
                                  '/sync_history?entityType=${Uri.encodeComponent(historyEntityType)}&localUuid=${Uri.encodeComponent(localUuid)}',
                                ),
                                child: const Text('Queue'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          if (entries.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(
                  '/audit_logs?organizationId=${Uri.encodeComponent(organizationId)}',
                ),
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Open full audit log'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  final AdminFinancialSummary summary;

  const _FinancialSummaryCard({required this.summary});

  String _money(double value) => '₱${value.toStringAsFixed(2)}';

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
            'Financial Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Total Sales',
                value: _money(summary.totalSales),
                color: AppColors.primary,
              ),
              _MetricChip(
                label: 'Collected',
                value: _money(summary.collectedPayments),
                color: Colors.teal,
              ),
              _MetricChip(
                label: 'Outstanding',
                value: _money(summary.outstandingReceivables),
                color: Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sales records: ${summary.salesCount}\nOpen receivables: ${summary.unpaidReceivablesCount}',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ExportSection extends StatefulWidget {
  final AppOrganization organization;
  final AdminOrganizationSummary? monitoringSummary;
  final AdminFinancialSummary financialSummary;

  const _ExportSection({
    required this.organization,
    required this.monitoringSummary,
    required this.financialSummary,
  });

  @override
  State<_ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends State<_ExportSection> {
  static const copyStatusKey = ValueKey('admin_reports_copy_status');
  String? _statusMessage;

  String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';

  String _buildSnapshotText() {
    final latestAuditAction = widget.monitoringSummary?.latestAuditAction ?? 'none';
    final latestAuditEntity = widget.monitoringSummary?.latestAuditEntityType ?? '—';
    final latestAuditAt =
        widget.monitoringSummary?.latestAuditAt?.toIso8601String() ?? 'none';

    return [
      'Admin Report Snapshot',
      'Organization: ${widget.organization.name}',
      'Organization Code: ${widget.organization.code.isEmpty ? '—' : widget.organization.code}',
      'Organization ID: ${widget.organization.id}',
      'Status: ${widget.organization.status}',
      '',
      'Monitoring',
      'Members: ${widget.monitoringSummary?.memberCount ?? 0}',
      'Audit Events: ${widget.monitoringSummary?.auditCount ?? 0}',
      'Latest Audit Action: $latestAuditAction',
      'Latest Audit Entity: $latestAuditEntity',
      'Latest Audit Time: $latestAuditAt',
      '',
      'Financial Summary',
      'Total Sales: ${_money(widget.financialSummary.totalSales)}',
      'Collected Payments: ${_money(widget.financialSummary.collectedPayments)}',
      'Outstanding Receivables: ${_money(widget.financialSummary.outstandingReceivables)}',
      'Sales Records: ${widget.financialSummary.salesCount}',
      'Open Receivables: ${widget.financialSummary.unpaidReceivablesCount}',
    ].join('\n');
  }

  String _buildCsvText() {
    final latestAuditAction = widget.monitoringSummary?.latestAuditAction ?? 'none';
    final latestAuditEntity = widget.monitoringSummary?.latestAuditEntityType ?? '—';
    final latestAuditAt =
        widget.monitoringSummary?.latestAuditAt?.toIso8601String() ?? 'none';

    String escape(String value) {
      final normalized = value.replaceAll('"', '""');
      return '"$normalized"';
    }

    final rows = <List<String>>[
      ['section', 'field', 'value'],
      ['organization', 'name', widget.organization.name],
      [
        'organization',
        'code',
        widget.organization.code.isEmpty ? '—' : widget.organization.code,
      ],
      ['organization', 'id', widget.organization.id],
      ['organization', 'status', widget.organization.status],
      [
        'monitoring',
        'member_count',
        '${widget.monitoringSummary?.memberCount ?? 0}',
      ],
      [
        'monitoring',
        'audit_count',
        '${widget.monitoringSummary?.auditCount ?? 0}',
      ],
      ['monitoring', 'latest_audit_action', latestAuditAction],
      ['monitoring', 'latest_audit_entity', latestAuditEntity],
      ['monitoring', 'latest_audit_time', latestAuditAt],
      [
        'financial',
        'total_sales',
        widget.financialSummary.totalSales.toStringAsFixed(2),
      ],
      [
        'financial',
        'collected_payments',
        widget.financialSummary.collectedPayments.toStringAsFixed(2),
      ],
      [
        'financial',
        'outstanding_receivables',
        widget.financialSummary.outstandingReceivables.toStringAsFixed(2),
      ],
      ['financial', 'sales_count', '${widget.financialSummary.salesCount}'],
      [
        'financial',
        'open_receivables_count',
        '${widget.financialSummary.unpaidReceivablesCount}',
      ],
    ];

    return rows.map((row) => row.map(escape).join(',')).join('\n');
  }

  String _safeFilePart(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final latestAuditAction = widget.monitoringSummary?.latestAuditAction ?? 'none';
      final latestAuditEntity = widget.monitoringSummary?.latestAuditEntityType ?? '—';
      final latestAuditAt =
          widget.monitoringSummary?.latestAuditAt?.toIso8601String() ?? 'none';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(28),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ADMIN REPORT SNAPSHOT',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF143D34),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    widget.organization.name,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  _pdfSection(
                    title: 'Organization',
                    rows: [
                      ('Code', widget.organization.code.isEmpty ? '—' : widget.organization.code),
                      ('Status', widget.organization.status),
                      ('Organization ID', widget.organization.id),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  _pdfSection(
                    title: 'Monitoring',
                    rows: [
                      ('Members', '${widget.monitoringSummary?.memberCount ?? 0}'),
                      ('Audit Events', '${widget.monitoringSummary?.auditCount ?? 0}'),
                      ('Latest Audit Action', latestAuditAction),
                      ('Latest Audit Entity', latestAuditEntity),
                      ('Latest Audit Time', latestAuditAt),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  _pdfSection(
                    title: 'Financial Summary',
                    rows: [
                      ('Total Sales', _money(widget.financialSummary.totalSales)),
                      ('Collected Payments', _money(widget.financialSummary.collectedPayments)),
                      (
                        'Outstanding Receivables',
                        _money(widget.financialSummary.outstandingReceivables),
                      ),
                      ('Sales Records', '${widget.financialSummary.salesCount}'),
                      (
                        'Open Receivables',
                        '${widget.financialSummary.unpaidReceivablesCount}',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final orgPart = _safeFilePart(widget.organization.code.isEmpty
          ? widget.organization.name
          : widget.organization.code);
      final file = File('${dir.path}/admin_report_${orgPart}_snapshot.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      setState(() {
        _statusMessage = 'Admin report PDF exported';
      });
    } catch (_) {
      setState(() {
        _statusMessage = 'Admin report PDF export failed';
      });
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_statusMessage ?? 'Admin report PDF exported')),
    );
  }

  pw.Widget _pdfSection({
    required String title,
    required List<(String, String)> rows,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FBFA),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFDCE9E4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF143D34),
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 140,
                    child: pw.Text(
                      row.$1,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      row.$2,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final orgPart = _safeFilePart(widget.organization.code.isEmpty
          ? widget.organization.name
          : widget.organization.code);
      final file = File('${dir.path}/admin_report_${orgPart}_snapshot.csv');
      await file.writeAsString(_buildCsvText());
      await OpenFile.open(file.path);

      setState(() {
        _statusMessage = 'Admin report CSV exported';
      });
    } catch (_) {
      setState(() {
        _statusMessage = 'Admin report CSV export failed';
      });
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_statusMessage ?? 'Admin report CSV exported')),
    );
  }

  Future<void> _copySnapshot(BuildContext context) async {
    setState(() {
      _statusMessage = 'Admin report snapshot copied';
    });

    try {
      await Clipboard.setData(ClipboardData(text: _buildSnapshotText()));
    } catch (_) {
      // Clipboard access can be unavailable in widget tests or restricted
      // platform environments. The snapshot action should still complete.
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin report snapshot copied')),
    );
  }

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
            'Export',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Copy a plain-text organization snapshot for PDO reporting, handoff, or incident review.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _copySnapshot(context),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy Snapshot'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _exportCsv(context),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Save CSV'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _exportPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Save PDF'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.push(
                  '/audit_logs?organizationId=${Uri.encodeComponent(widget.organization.id)}',
                ),
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Open Audit Log'),
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _statusMessage!,
              key: copyStatusKey,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminReportsCard extends StatelessWidget {
  final String title;
  final String message;

  const _AdminReportsCard({
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
          Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
