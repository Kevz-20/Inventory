import 'package:dswd_slp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/header.dart';
import '../../viewmodels/transaction_history_viewmodel.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionHistoryViewModel(),
      child: const _TransactionHistoryView(),
    );
  }
}

class _TransactionHistoryView extends StatelessWidget {
  const _TransactionHistoryView();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TransactionHistoryViewModel>(context);

    final categories = [
      'All',
      'Food',
      'Transport',
      'Bills',
      'Shopping',
      'Salary',
      'Other',
    ];

    return Scaffold(
      appBar: const AppHeader(
        title: 'Rekord sa Transaksyon',
        showBackButton: true,
      ),
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
          ),

          // Horizontal Filter Slider
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = vm.selectedCategory == category;
                return GestureDetector(
                  onTap: () => vm.selectCategory(category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: vm.filteredTransactions.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = vm.filteredTransactions[index];
                      final isExpense = vm.isExpense(transaction['amount']!);

                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    transaction['title']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    transaction['amount']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isExpense
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    transaction['category']!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    transaction['method']!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    transaction['date']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  Text(
                                    isExpense ? 'Expense' : 'Income',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isExpense
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
            color: Colors.grey.withValues(alpha: 0.2),
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
