import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';
import 'package:intl/intl.dart';
import '../../view_models/income_statement_view_model.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? start : end,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          start = picked;
        } else {
          end = picked;
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Range Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: _DateBox(title: 'Start Date', dateLabel: _format(start)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: _DateBox(title: 'End Date', dateLabel: _format(end)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Async Data Handling
            incomeState.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(e.toString(), style: const TextStyle(color: Colors.red)),
              ),
              data: (income) {
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
                        // Sales Section
                        Row(
                          children: const [
                            Icon(Icons.point_of_sale, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Sales',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._buildRows([
                          MapEntry('Merchandise Sales', income.merchandiseSales),
                          MapEntry('TOTAL SALES', income.sales),
                        ], highlightLast: true),

                        const SizedBox(height: 20),

                        // Expenses Section
                        Row(
                          children: const [
                            Icon(Icons.payments, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._buildRows([
                          MapEntry('Kompra', income.kompra),
                          MapEntry('Kuryente / Tubig', income.electricity),
                          MapEntry('Transportation', income.transportation),
                          MapEntry('Mga Bayronon', income.rentPayment),
                          MapEntry('Uban Pa', income.miscExpenses),
                        ]),

                        const Divider(height: 24),

                        // NET INCOME
                        _leaderRow('NET INCOME', income.netIncome, bold: true, highlight: true),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Bottom Download Button
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        child: SizedBox(
          height: 50,
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
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
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
    );
  }

  // ---------------- Build Rows with alternate shading ----------------
  List<Widget> _buildRows(List<MapEntry<String, double>> items,
      {bool highlightLast = false}) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isLast = highlightLast && index == items.length - 1;
      return _leaderRow(item.key, item.value,
          bold: isLast, highlight: isLast, indent: true, alternate: true, index: index);
    }).toList();
  }

  // ---------------- Leader Row ----------------
  Widget _leaderRow(
    String title,
    double value, {
    bool bold = false,
    bool indent = false,
    bool highlight = false,
    bool alternate = false,
    int index = 0,
  }) {
    final bgColor =
        alternate ? (index.isEven ? Colors.transparent : Colors.grey[100]) : Colors.transparent;

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(left: indent ? 16 : 0, top: 6, bottom: 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? AppColors.primary : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final dotCount = (constraints.maxWidth / 6).floor();
                return Text(
                  '.' * dotCount,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(color: Colors.black26),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
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