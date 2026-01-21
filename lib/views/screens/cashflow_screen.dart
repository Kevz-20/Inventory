import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../view_models/cashflow_view_model.dart';
import '../widgets/header.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(cashflowViewModelProvider);

    // Filter records by date
    final filteredRecords = vm.cashflowRecords.where((r) {
      final afterStart =
          vm.startDate == null || !r.date.isBefore(vm.startDate!);
      final beforeEnd = vm.endDate == null || !r.date.isAfter(vm.endDate!);
      return afterStart && beforeEnd;
    }).toList();

    final incomeTotal = filteredRecords
        .where((r) => r.type == CashflowType.income)
        .fold(0.0, (sum, r) => sum + r.amount);
    final expenseTotal = filteredRecords
        .where((r) => r.type == CashflowType.expense)
        .fold(0.0, (sum, r) => sum + r.amount);
    final balance = incomeTotal - expenseTotal;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Cashflow', showBackButton: true),
      body: Column(
        children: [
          const SizedBox(height: 15),

          // Dashboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _dashboardTile('Income', incomeTotal, Colors.green),
                  _dashboardTile('Expense', expenseTotal, Colors.red),
                  _dashboardTile('Balance', balance, Colors.blue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Date Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickStartDate(context, vm),
                    child: _inputRow(
                      label: 'Start Date',
                      value: vm.startDate != null
                          ? vm.formattedStartDate
                          : 'Select',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickEndDate(context, vm),
                    child: _inputRow(
                      label: 'End Date',
                      value: vm.endDate != null
                          ? vm.formattedEndDate
                          : 'Select',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Cashflow List
          Expanded(
            child: Builder(
              builder: (_) {
                if (filteredRecords.isEmpty) {
                  return const Center(
                    child: Text(
                      'No records yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          record.type == CashflowType.income
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: record.type == CashflowType.income
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          record.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(record.formattedDate),
                        trailing: Text(
                          '₱${record.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: record.type == CashflowType.income
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => vm.showAddCashflowDialog(context),
      ),
    );
  }

  // Dashboard Tile Widget
  Widget _dashboardTile(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          // ignore: deprecated_member_use
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _inputRow({required String label, required String value}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --------------------
  // Date pickers
  // --------------------
  Future<void> _pickStartDate(
    BuildContext context,
    CashflowViewModel vm,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) vm.setStartDate(picked);
  }

  Future<void> _pickEndDate(BuildContext context, CashflowViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) vm.setEndDate(picked);
  }
}
