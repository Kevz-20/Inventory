import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../view_models/transaction_history_view_model.dart';
import '../widgets/header.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionHistoryViewModel viewModel = TransactionHistoryViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.addListener(() {
      setState(() {}); // Rebuild UI when viewModel changes
    });
    viewModel.loadHistory(); // Load initial data
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        title: 'Transaction History',
        showBackButton: true,
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
                    date: viewModel.startDate ?? DateTime.now(),
                    onDateSelected: (picked) {
                      viewModel.setStartDate(picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerBox(
                    title: 'End Date',
                    date: viewModel.endDate ?? DateTime.now(),
                    onDateSelected: (picked) {
                      viewModel.setEndDate(picked);
                    },
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
              selectedCategory: viewModel.selectedCategory,
              onCategorySelected: viewModel.setSelectedCategory,
            ),
          ),

          // Transaction list
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.transactions.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = viewModel.transactions[index];
                      final isExpense =
                          tx.type == 'Gasto' || tx.type == 'Withdraw';
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description and amount
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      tx.description ?? tx.type,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱${tx.amount?.toStringAsFixed(2) ?? '0.00'}',
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

                              // Type and date
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tx.type,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'yyyy-MM-dd',
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
    );
  }
}

// Date picker box widget
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
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM d, y').format(date),
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Category Chips with Dot Indicator (Enum-Based)
class CategoryChipsWithDots extends StatefulWidget {
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
  State<CategoryChipsWithDots> createState() => _CategoryChipsWithDotsState();
}

class _CategoryChipsWithDotsState extends State<CategoryChipsWithDots> {
  final ScrollController _scrollController = ScrollController();
  double _scrollFraction = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      setState(() {
        _scrollFraction = maxScroll == 0
            ? 0
            : _scrollController.offset / maxScroll;
      });
    });
  }

  @override
  void didUpdateWidget(covariant CategoryChipsWithDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.categories.indexOf(widget.selectedCategory);
    if (index != -1 && _scrollController.hasClients) {
      const itemWidth = 72.0;
      final targetOffset = index * itemWidth - 16;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 45,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final isSelected = widget.selectedCategory == category;

              return GestureDetector(
                onTap: () => widget.onCategorySelected(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.categories.length, (index) {
            final progress =
                (index / (widget.categories.length - 1) - _scrollFraction)
                    .abs();
            final alpha = (1 - progress.clamp(0.0, 1.0));
            final isSelected =
                widget.selectedCategory == widget.categories[index];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 10 : 8,
              height: isSelected ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : Color.fromRGBO(128, 128, 128, alpha),
              ),
            );
          }),
        ),
      ],
    );
  }
}
