import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../view_models/transaction_history_view_model.dart';
import '../widgets/nav_bar.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late final TransactionHistoryViewModel viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    viewModel = TransactionHistoryViewModel();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      viewModel.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<TransactionHistoryViewModel>(
        builder: (_, vm, _) {
          final count = vm.transactionCount;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            backgroundColor: AppColors.surface,
            body: Column(
              children: [
                // Date pickers
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DatePickerBox(
                          title: 'Start Date',
                          date: vm.startDate ?? DateTime.now(),
                          onDateSelected: vm.setStartDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerBox(
                          title: 'End Date',
                          date: vm.endDate ?? DateTime.now(),
                          onDateSelected: vm.setEndDate,
                        ),
                      ),
                    ],
                  ),
                ),
                // Category chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CategoryChipsWithDots(
                    categories: TransactionCategory.values,
                    selectedCategory: vm.selectedCategory,
                    onCategorySelected: (cat) {
                      vm.setSelectedCategory(cat);
                      vm.resetPagination();
                    },
                  ),
                ),
                // Transaction list
                Expanded(
                  child: count == 0 && vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : count == 0
                      ? Center(
                          child: Text(
                            vm.emptyStateMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: count + 1,
                          itemBuilder: (_, index) {
                            if (index >= count) {
                              return vm.transactionCount <
                                      vm.transactions.length
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final tx = vm.transactionAt(index);

                            final isHalin = tx.type == 'Halin';
                            final isExpense = tx.type == 'Gasto';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha(51),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),

                                // Halin card layout
                                child: isHalin
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Top row: Halin + Product name and amount
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Halin',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        tx.description ??
                                                            'Product',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 14,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '+₱${tx.amount?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Payment type (Cash/Utang) and date
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                tx.paymentType ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'MMMM d, yyyy',
                                                ).format(tx.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    // Expenses (Gasto) card layout
                                    : isExpense
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Top row: type and amount
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                tx.type, // Gasto
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '-₱${tx.amount?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Bottom row: description as category and date
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                tx.description ??
                                                    '', // Show category text
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'MMMM d, yyyy',
                                                ).format(tx.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    // Default layout for other types
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  tx.type,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '+₱${tx.amount?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
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
                                                tx.description ?? tx.type,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'MMMM d, yyyy',
                                                ).format(tx.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45,
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
            bottomNavigationBar: const BottomNavBar(currentIndex: 1),
          );
        },
      ),
    );
  }
}

class _DatePickerBox extends StatelessWidget {
  final String title;
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerBox({
    required this.title,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.grey.shade100,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and icon in the same row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 17),
              ],
            ),
            const SizedBox(height: 4),
            // Selected date below the title
            Text(
              DateFormat('MMMM d, y').format(date),
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// Category chips with dot indicator
class CategoryChipsWithDots extends StatelessWidget {
  final List<TransactionCategory> categories;
  final TransactionCategory selectedCategory;
  final Function(TransactionCategory) onCategorySelected;

  const CategoryChipsWithDots({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category;

              return GestureDetector(
                onTap: () => onCategorySelected(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    category.displayName,
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: categories.map((category) {
            final isSelected = selectedCategory == category;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 8 : 6,
              height: isSelected ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
