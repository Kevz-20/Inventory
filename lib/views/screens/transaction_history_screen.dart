import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../view_models/transaction_history_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the transactions state from the ViewModel
    final transactionsAsync = ref.watch(transactionHistoryViewModelProvider);

    final categories = ['All', 'Gasto', 'Halin', 'Withdraw', 'Deposit'];

    return transactionsAsync.when(
      data: (transactions) {
        // Filter by category
        String selectedCategory = 'All';

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
                        date: DateTime.now(),
                        onDateSelected: (picked) {
                          ref
                              .read(
                                transactionHistoryViewModelProvider.notifier,
                              )
                              .loadTransactions(startDate: picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerBox(
                        title: 'End Date',
                        date: DateTime.now(),
                        onDateSelected: (picked) {
                          ref
                              .read(
                                transactionHistoryViewModelProvider.notifier,
                              )
                              .loadTransactions(endDate: picked);
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
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: (category) {
                    selectedCategory = category;
                  },
                ),
              ),

              // Transaction list
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tx.description ?? tx.type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
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
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
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

// Category Chips with Dot Indicator (dynamic & smooth)
class CategoryChipsWithDots extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

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
    // Scroll to selected category smoothly
    final index = widget.categories.indexOf(widget.selectedCategory);
    if (index != -1 && _scrollController.hasClients) {
      final itemWidth = 72.0; // Approximate width per chip including margin
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
                        color: Colors.grey.withValues(alpha: 51),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
        const SizedBox(height: 12),
        // Dot indicators
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
