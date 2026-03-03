// ignore_for_file: deprecated_member_use

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

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadBalanceSheet();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalLE = vm.totalLiabilities + vm.totalEquity;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Balance Sheet', showBackButton: true),

      // ✅ Scrollbar hint (same color/style as others)
      body: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.scrollbar),
          thickness: WidgetStateProperty.all(5),
          radius: const Radius.circular(8),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== SUMMARY CARD ====================
                _summaryCard(vm: vm),
                const SizedBox(height: 14),

                // ==================== ASSETS ====================
                _buildFinancialSection(
                  title: 'Assets',
                  icon: Icons.account_balance_wallet_rounded,
                  items: vm.assets,
                  total: vm.totalAssets,
                  vm: vm,
                ),
                const SizedBox(height: 14),

                // ==================== LIABILITIES ====================
                _buildFinancialSection(
                  title: 'Liabilities',
                  icon: Icons.payments_rounded,
                  items: vm.liabilities,
                  total: vm.totalLiabilities,
                  vm: vm,
                ),
                const SizedBox(height: 14),

                // ==================== EQUITY ====================
                _buildFinancialSection(
                  title: "Owner's Equity",
                  icon: Icons.account_balance_rounded,
                  items: vm.equity,
                  total: vm.totalEquity,
                  vm: vm,
                ),
                const SizedBox(height: 14),

                // ==================== TOTAL L + E ====================
                _totalHighlightCard(
                  title: 'Total Liabilities + Equity',
                  amount: totalLE,
                  vm: vm,
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),

      // ==================== BOTTOM BUTTON ====================
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(14),
          shadowColor: Colors.black.withOpacity(0.15),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final vm = ref.read(balanceSheetProvider);
                await vm.exportPdf();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              label: const Text(
                'Download PDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SUMMARY CARD ====================
  Widget _summaryCard({
    required BalanceSheetViewModel vm,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  label: 'Assets',
                  value: vm.formatCurrency(vm.totalAssets),
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  label: 'Liabilities',
                  value: vm.formatCurrency(vm.totalLiabilities),
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _miniStat(
            label: "Owner's Equity",
            value: vm.formatCurrency(vm.totalEquity),
            icon: Icons.balance_rounded,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Financial Section ----------------
  Widget _buildFinancialSection({
  required String title,
  required IconData icon,
  required Map<String, double> items,
  required double total,
  required BalanceSheetViewModel vm,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          offset: const Offset(0, 4),
          color: Colors.black.withOpacity(0.04),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),
            ),

            // ❌ Removed the header total amount here
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.grey.shade200, height: 1),
        const SizedBox(height: 6),

        // Items (List style)
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'No records yet.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...items.entries.map(
            (e) => _itemRow(label: e.key, amount: e.value, vm: vm),
          ),

        const SizedBox(height: 6),
        Divider(color: Colors.grey.shade200, height: 1),
        const SizedBox(height: 10),

        // Total row (✅ still kept at the bottom)
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            Text(
              vm.formatCurrency(total),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _itemRow({
    required String label,
    required double amount,
    required BalanceSheetViewModel vm,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            vm.formatCurrency(amount),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ---------------- Total Highlight Card ----------------
  Widget _totalHighlightCard({
    required String title,
    required double amount,
    required BalanceSheetViewModel vm,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calculate_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Text(
            vm.formatCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}