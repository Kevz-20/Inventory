// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../view_models/balance_sheet_view_model.dart';
import '../widgets/adaptive_digits_text.dart';


final balanceSheetProvider = ChangeNotifierProvider(
  (ref) => BalanceSheetViewModel(),
);

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFCDD5EE);
  static const Color _textPrimary = Color(0xFF1B3A7A);
  static const Color _textSecondary = Color(0xFF5B6D96);
  static const Color _accentBlue = Color(0xFF2D5BE3);

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
    if (!mounted) return;
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
        backgroundColor: _pageBg,
        body: Stack(
          children: [
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    final totalLiabilitiesAndEquity = vm.totalLiabilities + vm.totalEquity;

    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFCDD5EE)),
        ),
        leading: IconButton(
          icon: Image.asset(
            'lib/assets/arrowleft.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Balance Sheet',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ScrollbarTheme(
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
                          _summaryCard(vm: vm),
                          const SizedBox(height: 14),
                          _buildFinancialSection(
                            title: 'Assets',
                            icon: Icons.account_balance_wallet_rounded,
                            items: vm.assets,
                            total: vm.totalAssets,
                            vm: vm,
                          ),
                          const SizedBox(height: 14),
                          _buildFinancialSection(
                            title: 'Liabilities',
                            icon: Icons.payments_rounded,
                            items: vm.liabilities,
                            total: vm.totalLiabilities,
                            vm: vm,
                          ),
                          const SizedBox(height: 14),
                          _buildFinancialSection(
                            title: "Owner's Equity",
                            icon: Icons.account_balance_rounded,
                            items: vm.equity,
                            total: vm.totalEquity,
                            vm: vm,
                          ),
                          const SizedBox(height: 14),
                          _totalHighlightCard(
                            title: 'Total Liabilities + Equity',
                            amount: totalLiabilitiesAndEquity,
                            vm: vm,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
                child: Material(
                  elevation: 14,
                  borderRadius: BorderRadius.circular(20),
                  shadowColor: const Color(
                    0xFF8EA1D1,
                  ).withValues(alpha: 0.22),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final readVm = ref.read(balanceSheetProvider);
                        await readVm.exportPdf();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required BalanceSheetViewModel vm}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: const Color(0xFF8EA1D1).withValues(alpha: 0.10),
          ),
        ],
      ),
      child: Column(
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
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accentBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                AdaptiveDigitsText(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: const Color(0xFF8EA1D1).withValues(alpha: 0.10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _accentBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No records yet.',
                style: TextStyle(
                  color: _textSecondary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...items.entries.map(
              (entry) => _itemRow(
                label: entry.key,
                amount: entry.value,
                vm: vm,
              ),
            ),
          const SizedBox(height: 6),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _textPrimary,
                  ),
                ),
              ),
              Text(
                vm.formatCurrency(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: _accentBlue,
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
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            vm.formatCurrency(amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalHighlightCard({
    required String title,
    required double amount,
    required BalanceSheetViewModel vm,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accentBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accentBlue.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calculate_rounded,
              color: _accentBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: _textPrimary,
              ),
            ),
          ),
          Text(
            vm.formatCurrency(amount),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
