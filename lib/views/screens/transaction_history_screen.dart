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

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

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
                            final isCapital = tx.type == 'Capital';

                            // unified container for all card types
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Badge
                                              // Badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isHalin
                                                      ? Colors.green.withAlpha(
                                                          25,
                                                        )
                                                      : isExpense
                                                      ? Colors.red.withAlpha(25)
                                                      : Colors.blue.withAlpha(
                                                          25,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isHalin
                                                      ? 'Halin'
                                                      : isExpense
                                                      ? 'Gasto'
                                                      : 'Capital',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isHalin
                                                        ? Colors.green
                                                        : isExpense
                                                        ? Colors.red
                                                        : Colors.blue,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isHalin || isCapital
                                                    ? tx.productName ??
                                                          'Product'
                                                    : tx.description ??
                                                          'Transaction',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Amount
                                        // Amount
                                        Text(
                                          isCapital
                                              ? '+${_currencyFormatter.format((tx.amount ?? 0).abs())}'
                                              : isExpense
                                              ? '-${_currencyFormatter.format((tx.amount ?? 0).abs())}'
                                              : '+${_currencyFormatter.format((tx.amount ?? 0).abs())}', // Halin
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isHalin
                                                ? Colors.green
                                                : isCapital
                                                ? Colors.blue
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if ((isHalin || isCapital) &&
                                            tx.quantity != null)
                                          Text(
                                            'Qty: ${tx.quantity}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black54,
                                            ),
                                          )
                                        else
                                          const SizedBox(),
                                        Text(
                                          DateFormat(
                                            'MMMM d, yyyy',
                                          ).format(tx.createdAt),
                                          style: const TextStyle(
                                            fontSize: 15,
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

// ---------------- Date Picker Box ----------------
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 17),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMMM d, y').format(date),
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Category Chips ----------------
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
                      fontSize: 14,
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
