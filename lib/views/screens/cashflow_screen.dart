import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/cashflow_model.dart';
import '../../view_models/cashflow_view_model.dart';
import '../../core/app_colors.dart';
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
    await vm.loadCashflows(1); // Replace 1 with actual accountId
    setState(() => _loading = false);
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

  void _showCashflowDetails(CashflowRecord record) {
    final isInstallment = record.item.toLowerCase().contains('downpayment');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.receipt_long, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cashflow Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Date', record.formattedDate),
            _detailRow('Item', record.item),
            _detailRow(
              'Cash In',
              _formatCurrency(record.cashIn),
              valueColor: isInstallment ? Colors.blue : Colors.green,
            ),
            _detailRow(
              'Cash Out',
              _formatCurrency(record.cashOut),
              valueColor: Colors.red,
            ),
            _detailRow(
              'Balance',
              _formatCurrency(record.balance),
              valueBold: true,
            ),
          ],
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

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.primary,
      child: Row(
        children: const [
          _HeaderCell('Item', flex: 3, align: TextAlign.left),
          _HeaderCell('In', flex: 2, align: TextAlign.right),
          _HeaderCell('Out', flex: 2, align: TextAlign.right),
          _HeaderCell('Balance', flex: 2, align: TextAlign.right),
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
            _buildCell(r.item, flex: 3, align: TextAlign.left),
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
              flex: 2,
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
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
