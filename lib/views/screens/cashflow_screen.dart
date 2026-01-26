import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/cashflow_view_model.dart';
import '../../core/app_colors.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(cashflowViewModelProvider);
    final records = vm.filteredRecords;
    final balances = vm.runningBalances;

    return Scaffold(
      backgroundColor: AppColors.surface, // Match Home screen
      appBar: AppBar(
        title: const Text(
          'Cash Flow',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 1,
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Text(
                      'No cashflow records yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final r = records[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => vm.showCashflowDialog(
                            context,
                            record: r,
                            index: i,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            child: Row(
                              children: [
                                _cell(r.formattedDate, flex: 2),
                                _cell(r.item, flex: 3, alignLeft: true),
                                _cell(
                                  r.cashIn == 0 ? '-' : '₱${r.cashIn}',
                                  color: Colors.green,
                                ),
                                _cell(
                                  r.cashOut == 0 ? '-' : '₱${r.cashOut}',
                                  color: Colors.red,
                                ),
                                _cell(
                                  '₱${balances[i].toStringAsFixed(2)}',
                                  bold: true,
                                  alignRight: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Table header
  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: AppColors.primary,
      child: Row(
        children: const [
          _HeaderCell('Date', 2),
          _HeaderCell('Item', 3),
          _HeaderCell('In', 1),
          _HeaderCell('Out', 1),
          _HeaderCell('Balance', 2), // Increase flex to prevent wrapping
        ],
      ),
    );
  }

  // Table cell
  Widget _cell(
    String text, {
    int flex = 1,
    Color? color,
    bool bold = false,
    bool alignLeft = false,
    bool alignRight = false,
  }) {
    TextAlign alignment = TextAlign.center;
    if (alignLeft) alignment = TextAlign.left;
    if (alignRight) alignment = TextAlign.right;

    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignment,
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
  const _HeaderCell(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: FittedBox( // Prevents wrapping
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: flex == 3 ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
