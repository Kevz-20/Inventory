import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../view_models/income_statement_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

final incomeStatementProvider = ChangeNotifierProvider(
  (ref) => IncomeStatementViewModel(),
);

class IncomeStatementScreen extends ConsumerWidget {
  const IncomeStatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(incomeStatementProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Income Statement', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => vm.selectDate(context, true),
                    child: _DateBox(
                      title: 'Start Date',
                      dateLabel: vm.getFormattedDate(true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => vm.selectDate(context, false),
                    child: _DateBox(
                      title: 'End Date',
                      dateLabel: vm.getFormattedDate(false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRow('Sales', vm.formatCurrency(vm.merchandiseSales)),
                    _buildRow(
                      '  - Merchandise Sales',
                      vm.formatCurrency(vm.merchandiseSales),
                    ),
                    _buildRow('Total Sales', vm.formatCurrency(vm.totalSales)),
                    _buildRow('Expenses', vm.formatCurrency(vm.totalExpenses)),
                    _buildRow('  - Kumpra', vm.formatCurrency(vm.kumpra)),
                    _buildRow(
                      '  - Transportation',
                      vm.formatCurrency(vm.transportation),
                    ),
                    _buildRow(
                      'Total Expenses',
                      vm.formatCurrency(vm.totalExpenses),
                    ),
                    _buildRow('Net Income', vm.formatCurrency(vm.netIncome)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED1C24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Download PDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  final String title;
  final String dateLabel;

  const _DateBox({required this.title, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateLabel, style: const TextStyle(fontSize: 14)),
              const Icon(Icons.calendar_today, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
