import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/current_user.dart';
import '../../core/app_colors.dart';
import '../../models/cashflow_model.dart';
import '../../view_models/cashflow_view_model.dart';
import '../widgets/header.dart';

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCashflows();
  }

  Future<void> _loadCashflows() async {
    final vm = ref.read(cashflowViewModelProvider);
    try {
      await vm.loadCashflows();
    } catch (e) {
      debugPrint('Error fetching cashflows: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
      customPattern: '₱#,##0',
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cashflowViewModelProvider);
    final records = vm.filteredRecords;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Cash Flow', showBackButton: true),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                    ? const Center(
                        child: Text(
                          'No cashflow records yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (_, i) => _buildRow(records[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPDATED CASHFLOW DETAILS DIALOG (UI only)
  // ============================================================

  void _showCashflowDetails(CashflowRecord record) {
    final itemLower = record.item.toLowerCase();
    final isInstallment = itemLower.contains('downpayment');
    final hasCashIn = record.cashIn > 0;
    final hasCashOut = record.cashOut > 0;

    // ✅ Build fallback name exactly like TransactionHistory
    final currentUserName = [
      CurrentUser.firstName ?? '',
      CurrentUser.middleName ?? '',
      CurrentUser.lastName ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();

    final recordedByValue = (record.recordedBy ?? '').trim().isNotEmpty
        ? record.recordedBy!.trim()
        : (currentUserName.isNotEmpty ? currentUserName : 'System');

    // Determine chip label + color (purely UI)
    Color chipColor;
    String chipText;

    if (isInstallment) {
      chipColor = Colors.blue;
      chipText = 'Installment';
    } else if (hasCashIn && !hasCashOut) {
      chipColor = Colors.green;
      chipText = 'Cash In';
    } else if (!hasCashIn && hasCashOut) {
      chipColor = Colors.red;
      chipText = 'Cash Out';
    } else {
      chipColor = Colors.grey;
      chipText = 'Record';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cashflow Details',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TOP CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _typeChip(chipText, chipColor),
                          Text(
                            '${record.formattedDate} • ${record.formattedTime}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        record.item,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // SUMMARY CARDS
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        label: 'Cash In',
                        value: record.cashIn == 0
                            ? '—'
                            : _formatCurrency(record.cashIn),
                        color: isInstallment ? Colors.blue : Colors.green,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        label: 'Cash Out',
                        value: record.cashOut == 0
                            ? '—'
                            : _formatCurrency(record.cashOut),
                        color: Colors.red,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _summaryCard(
                  label: 'Balance',
                  value: _formatCurrency(record.balance),
                  color: AppColors.primary,
                  icon: Icons.account_balance_wallet_rounded,
                  isWide: true,
                ),

                const SizedBox(height: 12),

                // DETAILS LIST
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _detailRow('Date', record.formattedDate),
                      _divider(),
                      _detailRow('Time', record.formattedTime),
                      _divider(),

                      // ✅ NEW: Recorded By
                      _detailRow('Recorded By', recordedByValue, multiline: true),
                      _divider(),

                      _detailRow('Item', record.item, multiline: true),
                      _divider(),
                      _detailRow(
                        'Cash In',
                        record.cashIn == 0
                            ? '—'
                            : _formatCurrency(record.cashIn),
                        valueColor:
                            isInstallment ? Colors.blue : Colors.green,
                        boldValue: true,
                      ),
                      _divider(),
                      _detailRow(
                        'Cash Out',
                        record.cashOut == 0
                            ? '—'
                            : _formatCurrency(record.cashOut),
                        valueColor: Colors.red,
                        boldValue: true,
                      ),
                      _divider(),
                      _detailRow(
                        'Balance',
                        _formatCurrency(record.balance),
                        valueColor: AppColors.primary,
                        boldValue: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Helpers (UI only)
  // ============================================================

  Widget _divider() =>
      Divider(height: 14, thickness: 1, color: Colors.grey.withAlpha(40));

  Widget _typeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: isWide ? 18 : 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool boldValue = false,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: multiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: boldValue ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER + ROW (Date column removed)
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.primary,
      child: Row(
        children: const [
          _HeaderCell('Item', flex: 5, align: TextAlign.left),
          _HeaderCell('In', flex: 2, align: TextAlign.right),
          _HeaderCell('Out', flex: 2, align: TextAlign.right),
          _HeaderCell('Balance', flex: 3, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildRow(CashflowRecord r) {
    final isInstallment = r.item.toLowerCase().contains('downpayment');

    return GestureDetector(
      onTap: () => _showCashflowDetails(r),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(50),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCell(r.item, flex: 5, align: TextAlign.left),
            _buildCell(
              r.cashIn == 0 ? '-' : _formatCurrency(r.cashIn),
              flex: 2,
              color: isInstallment ? Colors.blue : Colors.green,
              align: TextAlign.right,
            ),
            _buildCell(
              r.cashOut == 0 ? '-' : _formatCurrency(r.cashOut),
              flex: 2,
              color: Colors.red,
              align: TextAlign.right,
            ),
            _buildCell(
              _formatCurrency(r.balance),
              flex: 3,
              bold: true,
              align: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(
    String text, {
    int flex = 1,
    Color? color,
    bool bold = false,
    TextAlign align = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
      child: AutoSizeText(
        text,
        textAlign: align,
        maxLines: 1,
        minFontSize: 10,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;

  const _HeaderCell(
    this.text, {
    required this.flex,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}