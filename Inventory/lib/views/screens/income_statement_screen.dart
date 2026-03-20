// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../view_models/income_statement_view_model.dart';
import '../widgets/adaptive_digits_text.dart';


class IncomeStatementScreen extends ConsumerStatefulWidget {
  const IncomeStatementScreen({super.key});

  @override
  ConsumerState<IncomeStatementScreen> createState() =>
      _IncomeStatementScreenState();
}

class _IncomeStatementScreenState extends ConsumerState<IncomeStatementScreen> {
  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFCDD5EE);
  static const Color _textPrimary = Color(0xFF1B3A7A);
  static const Color _textSecondary = Color(0xFF5B6D96);
  static const Color _accentBlue = Color(0xFF2D5BE3);

  static final DateFormat _dateFormat = DateFormat('MMMM d, yyyy');

  DateTime start = DateTime.now();
  DateTime end = DateTime.now();

  late final ScrollController _scrollController;
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didInitialLoad) {
      _didInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? start : end,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          start = picked;
          if (start.isAfter(end)) end = start;
        } else {
          end = picked;
          if (end.isBefore(start)) start = end;
        }
      });

      _loadData();
    }
  }

  void _loadData() {
    ref
        .read(incomeStatementViewModelProvider.notifier)
        .load(startDate: start, endDate: end);
  }

  String _format(DateTime date) => _dateFormat.format(date);

  @override
  Widget build(BuildContext context) {
    final incomeState = ref.watch(incomeStatementViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

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
          'Income Statement',
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
                          _dateRangeCard(
                            startLabel: _format(start),
                            endLabel: _format(end),
                            onStartTap: () => _selectDate(context, true),
                            onEndTap: () => _selectDate(context, false),
                          ),
                          const SizedBox(height: 14),
                          incomeState.when(
                            loading: () => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                e.toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            data: (income) {
                              final currency = NumberFormat.currency(
                                symbol: 'â‚±',
                                decimalDigits: 2,
                              );

                              final expenseEntries =
                                  income.expenseCategories.entries.toList()..sort(
                                    (a, b) => a.key.toLowerCase().compareTo(
                                      b.key.toLowerCase(),
                                    ),
                                  );

                              final isEmpty =
                                  income.sales == 0 &&
                                  income.totalExpenses == 0;

                              return Column(
                                children: [
                                  _summaryCard(
                                    sales: income.sales,
                                    totalExpenses: income.totalExpenses,
                                    netIncome: income.netIncome,
                                    currency: currency,
                                  ),
                                  const SizedBox(height: 14),
                                  if (isEmpty)
                                    _emptyCard()
                                  else ...[
                                    _buildFinancialSection(
                                      title: 'Sales',
                                      icon: Icons.point_of_sale_rounded,
                                      totalText: currency.format(income.sales),
                                      children: [
                                        _itemRow(
                                          label: 'Merchandise Sales',
                                          value: income.merchandiseSales,
                                          currency: currency,
                                        ),
                                        const SizedBox(height: 8),
                                        Divider(
                                          color: Colors.grey.shade200,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 10),
                                        _totalRow(
                                          label: 'TOTAL SALES',
                                          amountText: currency.format(
                                            income.sales,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _buildFinancialSection(
                                      title: 'Expenses',
                                      icon: Icons.payments_rounded,
                                      totalText: currency.format(
                                        income.totalExpenses,
                                      ),
                                      children: [
                                        if (expenseEntries.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Text(
                                              'No expense records',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                        else
                                          ...expenseEntries.map(
                                            (entry) => _itemRow(
                                              label: entry.key,
                                              value: entry.value,
                                              currency: currency,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Divider(
                                          color: Colors.grey.shade200,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 10),
                                        _totalRow(
                                          label: 'TOTAL EXPENSES',
                                          amountText: currency.format(
                                            income.totalExpenses,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              );
                            },
                          ),
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
                        final vm = ref.read(
                          incomeStatementViewModelProvider.notifier,
                        );
                        final state = ref.read(incomeStatementViewModelProvider);
                        if (state.asData?.value == null) return;
                        await vm.exportPdf();
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

  Widget _dateRangeCard({
    required String startLabel,
    required String endLabel,
    required VoidCallback onStartTap,
    required VoidCallback onEndTap,
  }) {
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
      child: Row(
        children: [
          Expanded(
            child: _dateBox(
              title: 'Start Date',
              dateLabel: startLabel,
              onTap: onStartTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dateBox(
              title: 'End Date',
              dateLabel: endLabel,
              onTap: onEndTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox({
    required String title,
    required String dateLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: _accentBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required double sales,
    required double totalExpenses,
    required double netIncome,
    required NumberFormat currency,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  label: 'Sales',
                  value: currency.format(sales),
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  label: 'Expenses',
                  value: currency.format(totalExpenses),
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _miniStat(
            label: 'Net Income',
            value: currency.format(netIncome),
            icon: Icons.calculate_rounded,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? _accentBlue.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? _accentBlue.withValues(alpha: 0.18)
              : _cardBorder,
        ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                AdaptiveDigitsText(
                  value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: highlight ? _accentBlue : _textPrimary,
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
    required String totalText,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
          ...children,
        ],
      ),
    );
  }

  Widget _itemRow({
    required String label,
    required double value,
    required NumberFormat currency,
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
            currency.format(value),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _totalRow({required String label, required String amountText}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        Text(
          amountText,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: _accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _accentBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No records found for the selected date range.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
