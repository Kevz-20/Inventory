// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../view_models/income_statement_view_model.dart';
import '../widgets/header.dart';

class IncomeStatementScreen extends ConsumerStatefulWidget {
  const IncomeStatementScreen({super.key});

  @override
  ConsumerState<IncomeStatementScreen> createState() =>
      _IncomeStatementScreenState();
}

class _IncomeStatementScreenState extends ConsumerState<IncomeStatementScreen> {
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
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Income Statement', showBackButton: true),
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
                      symbol: '₱',
                      decimalDigits: 2,
                    );

                    final expenseEntries =
                        income.expenseCategories.entries.toList()
                          ..sort(
                            (a, b) => a.key.toLowerCase().compareTo(
                              b.key.toLowerCase(),
                            ),
                          );

                    final isEmpty =
                        income.sales == 0 && income.totalExpenses == 0;

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
                              Divider(color: Colors.grey.shade200, height: 1),
                              const SizedBox(height: 10),
                              _totalRow(
                                label: 'TOTAL SALES',
                                amountText: currency.format(income.sales),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _buildFinancialSection(
                            title: 'Expenses',
                            icon: Icons.payments_rounded,
                            totalText: currency.format(income.totalExpenses),
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
                              Divider(color: Colors.grey.shade200, height: 1),
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

                        const SizedBox(height: 90),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
                final vm = ref.read(incomeStatementViewModelProvider.notifier);
                final state = ref.read(incomeStatementViewModelProvider);
                if (state.asData?.value == null) return;
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
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
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
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Colors.grey.shade700,
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
            ? AppColors.primary.withOpacity(0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withOpacity(0.18)
              : Colors.grey.shade200,
        ),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: highlight ? AppColors.primary : Colors.black87,
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
                color: Colors.black87,
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
            color: AppColors.primary,
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
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No records found for the selected date range.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}