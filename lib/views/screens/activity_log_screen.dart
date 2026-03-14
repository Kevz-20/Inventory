import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/audit_log_entry.dart';
import '../../repositories/activity_log_repository.dart';
import '../widgets/header.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  static const List<String> _modules = [
    '',
    'association_setup',
    'association_profile',
    'member_management',
    'first_member_setup',
    'product',
    'stock_in',
    'stock_in_product',
    'sales_cash',
    'sales_credit',
    'expense',
    'customer',
    'payable',
    'capital_management',
    'fixed_asset',
    'customer_payment',
    'pin_change',
    'pin_reset',
  ];

  final ActivityLogRepository _repository = ActivityLogRepository();
  String _selectedModule = '';
  late Future<List<AuditLogEntry>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _loadLogs();
  }

  Future<List<AuditLogEntry>> _loadLogs() {
    return _repository.getLogs(
      module: _selectedModule.isEmpty ? null : _selectedModule,
    );
  }

  Future<void> _refresh() async {
    final future = _loadLogs();
    setState(() {
      _logsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const AppHeader(title: 'Activity Log', showBackButton: true),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<AuditLogEntry>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading activity log: ${snapshot.error}'),
                  );
                }

                final logs = snapshot.data ?? const <AuditLogEntry>[];
                if (logs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No activity found yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _logCard(logs[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: const Color(0xFFF6F6F6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _modules.map((module) {
            final selected = module == _selectedModule;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_moduleLabel(module)),
                selected: selected,
                selectedColor: AppColors.primarySoft,
                onSelected: (_) {
                  setState(() {
                    _selectedModule = module;
                    _logsFuture = _loadLogs();
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _logCard(AuditLogEntry log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _actionColor(log.action).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _actionIcon(log.action),
                  color: _actionColor(log.action),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _summary(log),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${log.memberName ?? 'Unknown member'} - ${_formatTimestamp(log.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip(log.action.toUpperCase(), _actionColor(log.action)),
              _metaChip(_moduleLabel(log.module), AppColors.primary),
              if (log.recordId != null && log.recordId!.isNotEmpty)
                _metaChip('ID ${log.recordId}', AppColors.info),
            ],
          ),
          if (log.oldValue != null || log.newValue != null) ...[
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                if (log.oldValue != null)
                  _valueBlock('Previous', log.oldValue!),
                if (log.newValue != null)
                  _valueBlock('Current', log.newValue!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _valueBlock(String title, Map<String, dynamic> value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatMap(value),
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _summary(AuditLogEntry log) {
    final target = _moduleLabel(log.module);
    switch (log.action) {
      case 'create':
        return '$target created';
      case 'update':
        return '$target updated';
      case 'delete':
        return '$target deleted';
      case 'bulk_delete':
        return '$target records deleted';
      case 'deduct_cash':
        return 'Capital cash deducted';
      default:
        return '$target ${log.action.replaceAll('_', ' ')}';
    }
  }

  String _moduleLabel(String module) {
    if (module.isEmpty) return 'All';
    return module
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatTimestamp(DateTime value) {
    final month = _monthName(value.month);
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$month ${value.day}, ${value.year} $hour:$minute $suffix';
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  String _formatMap(Map<String, dynamic> map) {
    final entries = map.entries
        .map((entry) => '${entry.key}: ${_stringify(entry.value)}')
        .toList();
    return entries.join('\n');
  }

  String _stringify(Object? value) {
    if (value == null) return '-';
    if (value is List) return value.map(_stringify).join(', ');
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}=${_stringify(entry.value)}')
          .join(', ');
    }
    return value.toString();
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
      case 'bulk_delete':
        return Icons.delete_outline;
      default:
        return Icons.history;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.info;
      case 'delete':
      case 'bulk_delete':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
