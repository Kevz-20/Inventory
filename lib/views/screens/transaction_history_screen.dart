// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use

import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/current_user.dart';
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
  late final PageController _categoryPageController;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  static const List<TransactionCategory> _historyCategories = [
    TransactionCategory.all,
    TransactionCategory.expenses,
    TransactionCategory.sales,
    TransactionCategory.capitalManagement,
    TransactionCategory.customerPayment,
    TransactionCategory.ownerPayment,
  ];

  @override
  void initState() {
    super.initState();
    viewModel = TransactionHistoryViewModel();
    _categoryPageController = PageController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _categoryPageController.dispose();
    _scrollController.dispose();
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
          final _ = vm.sections;

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
                          date: vm.startDate,
                          onDateSelected: vm.setStartDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerBox(
                          title: 'End Date',
                          date: vm.endDate,
                          onDateSelected: vm.setEndDate,
                          // Constrain the end date to be >= start date.
                          firstDate: vm.startDate,
                        ),
                      ),
                    ],
                  ),
                ),

                // Category chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CategoryChipsWithDots(
                    categories: _historyCategories,
                    selectedCategory: vm.selectedCategory,
                    onCategorySelected: (cat) {
                      final index = _historyCategories.indexOf(cat);
                      vm.setSelectedCategory(cat);
                      if (index >= 0) {
                        _categoryPageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),

                // Transaction list
                Expanded(
                  child: PageView.builder(
                    controller: _categoryPageController,
                    itemCount: _historyCategories.length,
                    onPageChanged: (index) {
                      vm.setSelectedCategory(_historyCategories[index]);
                    },
                    itemBuilder: (context, index) => _buildHistoryList(vm),
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

  Widget _buildHistoryList(TransactionHistoryViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.sections.isEmpty) {
      return Center(
        child: Text(
          vm.emptyStateMessage,
          style: const TextStyle(fontSize: 16, color: Colors.black45),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: vm.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = vm.sections[sectionIndex];
        return _buildSection(section);
      },
    );
  }

  // ------------------------
  // Build single transaction card
  // ------------------------
  Widget _buildTransactionCard(TransactionItem tx, BuildContext context) {
    final isHalin = tx.type == 'Halin';
    final isHalinUtang = isHalin && (tx.isUtangSale == true);

    final isExpense = tx.type == 'Gasto';
    final isCapital = tx.type == 'Capital';
    final isCustomerPayment = tx.type == 'Customer Payment';
    final isOwnerPayment = tx.type == 'Owner Payment';
    final isDownpayment = tx.type == 'Downpayment';

    // ✅ Updated label (Halin vs Halin (Utang))
    final typeLabel = isDownpayment
        ? 'Owner Payment'
        : isHalinUtang
        ? 'Halin (Utang)'
        : isHalin
        ? 'Halin'
        : isExpense
        ? 'Gasto'
        : isCapital
        ? 'Capital'
        : isCustomerPayment
        ? 'Customer Payment'
        : isOwnerPayment
        ? 'Owner Payment'
        : tx.type;

    final descriptionLabel = isDownpayment
        ? '${tx.description ?? ''}  downpayment'
        : (tx.description ?? '');

    final capitalNote = (tx.description ?? '').trim().isEmpty
        ? 'N/A'
        : tx.description!.trim();

    // ✅ Income types in green, outgoing in red
    final isIncome = isCapital || isHalin || isCustomerPayment;
    final amountColor = isIncome ? Colors.green : Colors.red;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _TransactionDetailsSheet(transaction: tx),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: type + amount
            Row(
              children: [
                // ✅ Type text dark gray
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),

                const Spacer(),

                // ✅ Amount + sign
                Text(
                  isIncome
                      ? '+${_currencyFormatter.format((tx.amount ?? 0).abs())}'
                      : '-${_currencyFormatter.format((tx.amount ?? 0).abs())}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Second row: note / product + view receipt
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    (isExpense ||
                            isCustomerPayment ||
                            isOwnerPayment ||
                            isDownpayment)
                        ? descriptionLabel
                        : isCapital
                        ? ''
                        : (tx.productName ?? 'Product'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (isExpense && tx.receiptImagePath != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: Image.file(
                              File(tx.receiptImagePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View Receipt',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 2),

            // Third row: extra info + time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isCapital)
                  Text(
                    'Note: $capitalNote',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  )
                else if (isHalin)
                  tx.quantity != null
                      ? Text(
                          'Qty: ${tx.quantity}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        )
                      : const SizedBox()
                else if (isExpense)
                  tx.category != null
                      ? Text(
                          'Category: ${tx.category}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        )
                      : const SizedBox(),

                Text(
                  DateFormat('hh:mm a').format(tx.createdAt),
                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build a section (grouped by date)
  Widget _buildSection(TransactionSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title (Today / Date)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            section.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Transactions in this section
        ...section.items.map((tx) => _buildTransactionCard(tx, context)),
      ],
    );
  }
}

// ---------------- Date Picker Box ----------------
class _DatePickerBox extends StatelessWidget {
  final String title;
  // Nullable: null means "no filter applied" — shows "Any date" placeholder.
  final DateTime? date;
  final ValueChanged<DateTime?> onDateSelected;
  // When set, the picker will not allow selecting a date before this value.
  // Used by the End Date picker to enforce: end >= start.
  final DateTime? firstDate;

  const _DatePickerBox({
    required this.title,
    required this.date,
    required this.onDateSelected,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final earliest = firstDate ?? DateTime(2000);

        // If the current selection is before the new earliest (e.g. start date
        // was moved forward after an end date was already chosen), snap the
        // initial calendar page to the earliest allowed date instead.
        final initial =
            (date != null && !date!.isAfter(now) && !date!.isBefore(earliest))
            ? date!
            : (earliest.isAfter(now) ? now : earliest);

        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: earliest,
          lastDate: now, // 🚫 Prevent future dates
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

        if (picked != null && !picked.isAfter(now)) {
          onDateSelected(picked);
        }
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
              hasDate ? DateFormat('MMMM d, y').format(date!) : 'Any date',
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
            padding: EdgeInsets.zero,
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

// ---------------- Transaction BottomSheet ----------------
class _TransactionDetailsSheet extends StatelessWidget {
  final TransactionItem transaction;

  const _TransactionDetailsSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'Gasto';
    final isHalin = transaction.type == 'Halin';
    final isCapital = transaction.type == 'Capital';
    final isCustomerPayment = transaction.type == 'Customer Payment';
    final isOwnerPayment = transaction.type == 'Owner Payment';
    final isDownpayment = transaction.type == 'Downpayment';
    final detailTypeLabel = isDownpayment ? 'Owner Payment' : transaction.type;
    final currentUserName = [
      CurrentUser.firstName ?? '',
      CurrentUser.middleName ?? '',
      CurrentUser.lastName ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();
    final capitalAddedBy = (transaction.recordedBy ?? '').trim().isEmpty
        ? currentUserName
        : transaction.recordedBy!.trim();
    final recordedByValue = (transaction.recordedBy ?? '').trim().isEmpty
        ? currentUserName
        : transaction.recordedBy!.trim();
    final NumberFormat currency = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return SafeArea(
      top: false, // keeps drag handle closer to top
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Text(
              '$detailTypeLabel Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCapital ? 'Amount Added:' : 'Amount:',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  isCapital
                      ? currency.format(transaction.amount ?? 0)
                      : '${(isCapital || isHalin || isCustomerPayment) ? '+' : '-'}${currency.format(transaction.amount ?? 0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isHalin
                        ? Colors.green
                        : isExpense
                        ? Colors.red
                        : isCustomerPayment
                        ? Colors.green
                        : (isOwnerPayment || isDownpayment)
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date:', style: TextStyle(fontSize: 16)),
                Text(
                  DateFormat(
                    isCapital ? 'MMMM d, y' : 'MMMM d, y • hh:mm a',
                  ).format(transaction.createdAt),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (isExpense && transaction.category != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Category:', style: TextStyle(fontSize: 16)),
                  Text(
                    transaction.category!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

            if ((isHalin || isCapital) && transaction.quantity != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity:', style: TextStyle(fontSize: 16)),
                  Text(
                    transaction.quantity.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            if (isCapital)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Added By:', style: TextStyle(fontSize: 16)),
                  Text(capitalAddedBy, style: const TextStyle(fontSize: 16)),
                ],
              ),

            if (isHalin ||
                isExpense ||
                isCustomerPayment ||
                isOwnerPayment ||
                isDownpayment)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recorded By:', style: TextStyle(fontSize: 16)),
                  Text(recordedByValue, style: const TextStyle(fontSize: 16)),
                ],
              ),
            const SizedBox(height: 16),

            if (isExpense && transaction.receiptImagePath != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Receipt:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: Image.file(
                              File(transaction.receiptImagePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.file(
                      File(transaction.receiptImagePath!),
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
