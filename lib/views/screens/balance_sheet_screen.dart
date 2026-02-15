import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../view_models/balance_sheet_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

final balanceSheetProvider = ChangeNotifierProvider(
  (ref) => BalanceSheetViewModel(),
);

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
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
    await vm.loadBalanceSheet(); // ✅ no accountIds, show all transactions
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(balanceSheetProvider);

    // Get system bottom padding for adaptive layout
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Balance Sheet', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await vm.selectDate(context, true);
                      await _refreshData();
                    },
                    child: _DateBox(
                      title: 'Start Date',
                      dateLabel: vm.getFormattedDate(true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await vm.selectDate(context, false);
                      await _refreshData();
                    },
                    child: _DateBox(
                      title: 'End Date',
                      dateLabel: vm.getFormattedDate(false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Assets Section
            _buildFinancialSection(
              title: 'Assets',
              items: vm.assets,
              total: vm.totalAssets,
              vm: vm,
            ),
            const SizedBox(height: 20),

            // Liabilities Section
            _buildFinancialSection(
              title: 'Liabilities',
              items: vm.liabilities,
              total: vm.totalLiabilities,
              vm: vm,
            ),
            const SizedBox(height: 20),

            // Owner's Equity Section
            _buildFinancialSection(
              title: "Owner's Equity",
              items: vm.equity,
              total: vm.totalEquity,
              vm: vm,
            ),
            const SizedBox(height: 20),

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
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + bottomPadding, // Add system bottom padding
        ),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black.withAlpha((0.3 * 255).round()),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                debugPrint("Download Balance Sheet tapped");
              },
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

  // Refresh data
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    final vm = ref.read(balanceSheetProvider);
    await vm.loadBalanceSheet(); // ✅ no accountIds
    setState(() {
      _isLoading = false;
    });
  }

  // ------------------------------
  // Financial Section Card
  // ------------------------------
  Widget _buildFinancialSection({
    required String title,
    required Map<String, double> items,
    required double total,
    required BalanceSheetViewModel vm,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...items.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      vm.formatCurrency(entry.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                Text(
                  vm.formatCurrency(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // Total Liabilities + Equity Row
  // ------------------------------
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          Text(
            vm.formatCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ],
      ),
    );
  }
}

// ------------------------------
// Date Box Widget
// ------------------------------
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
            color: Colors.grey.withAlpha(51),
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
