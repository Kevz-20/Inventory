import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../view_models/balance_sheet_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

final balanceSheetProvider = ChangeNotifierProvider(
  (ref) => BalanceSheetViewModel(),
);

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() =>
      _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalanceSheet();
  }

  Future<void> _loadBalanceSheet() async {
    final vm = ref.read(balanceSheetProvider);
    await vm.loadBalanceSheet();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(balanceSheetProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Balance Sheet',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // As of Today Label
            Text(
              'As of ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Assets
            _buildFinancialSection(
              title: 'Assets',
              items: vm.assets,
              total: vm.totalAssets,
              vm: vm,
            ),
            const SizedBox(height: 24),

            // Liabilities
            _buildFinancialSection(
              title: 'Liabilities',
              items: vm.liabilities,
              total: vm.totalLiabilities,
              vm: vm,
            ),
            const SizedBox(height: 24),

            // Equity
            _buildFinancialSection(
              title: "Owner's Equity",
              items: vm.equity,
              total: vm.totalEquity,
              vm: vm,
            ),
            const SizedBox(height: 24),

            // Total Liabilities + Equity
            _buildTotalRow(
              title: 'Total Liabilities + Equity',
              amount: vm.totalLiabilities + vm.totalEquity,
              vm: vm,
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black.withAlpha((0.3 * 255).round()),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final vm = ref.read(balanceSheetProvider);
                await vm.exportPdf();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  // ---------------- Financial Section ----------------
  Widget _buildFinancialSection({
    required String title,
    required Map<String, double> items,
    required double total,
    required BalanceSheetViewModel vm,
  }) {
    return Card(
      color: Colors.grey[50], // softer background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header with icon
            Row(
              children: [
                Icon(
                  title == 'Assets'
                      ? Icons.account_balance_wallet
                      : title == 'Liabilities'
                          ? Icons.money_off
                          : Icons.account_balance,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Rows with alternate background
            ...items.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                color: index.isEven ? Colors.transparent : Colors.grey[100],
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      vm.formatCurrency(item.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 10),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 6),

            // Total Row
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  vm.formatCurrency(total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.primary, // highlight total
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Total Row ----------------
  Widget _buildTotalRow({
    required String title,
    required double amount,
    required BalanceSheetViewModel vm,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          Text(
            vm.formatCurrency(amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}