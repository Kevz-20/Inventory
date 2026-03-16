// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use

import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/current_user.dart';
import '../../view_models/transaction_history_view_model.dart';
import '../widgets/dashboard_background.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _textPrimary = Color(0xFF213A6B);
  static const Color _textSecondary = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  late final TransactionHistoryViewModel viewModel;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  late final PageController _categoryPageController;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '\u20B1 ',
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

  void _autoScrollChips(int index) {
    if (!_categoryScrollController.hasClients) return;

    const chipWidth = 110.0; // approx width including spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollTo = (index * chipWidth) - (screenWidth / 2) + (chipWidth / 2);

    _categoryScrollController.animateTo(
      scrollTo.clamp(0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _categoryPageController.dispose();
    _scrollController.dispose();
    _categoryScrollController.dispose();
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
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700;
    final maxContentWidth = isTablet ? 760.0 : double.infinity;

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<TransactionHistoryViewModel>(
        builder: (_, vm, _) {
          return Scaffold(
            backgroundColor: _pageBg,
            appBar: AppBar(
              backgroundColor: _pageBg,
              surfaceTintColor: Colors.transparent,
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
                'History',
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              centerTitle: true,
              elevation: 0,
            ),
            body: Stack(
              children: [
                const DashboardBackground(),
                SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            child: Column(
                              children: [
                                _buildFilterPanel(vm),
                                const SizedBox(height: 14),
                                CategoryChipsWithDots(
                                  scrollController: _categoryScrollController,
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
                                      _autoScrollChips(index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PageView.builder(
                              controller: _categoryPageController,
                              itemCount: _historyCategories.length,
                              onPageChanged: (index) {
                                vm.setSelectedCategory(_historyCategories[index]);
                                _autoScrollChips(index);
                              },
                              itemBuilder: (context, index) => _buildHistoryList(vm),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(TransactionHistoryViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8EA1D1).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final isCompact = c.maxWidth < 420;
              final spacing = isCompact ? 8.0 : 12.0;

              final startBox = _DatePickerBox(
                title: 'Start Date',
                date: vm.startDate ?? DateTime.now(),
                onDateSelected: vm.setStartDate,
                compact: isCompact,
              );

              final endBox = _DatePickerBox(
                title: 'End Date',
                date: vm.endDate ?? DateTime.now(),
                onDateSelected: vm.setEndDate,
                compact: isCompact,
              );

              return Row(
                children: [
                  Expanded(child: startBox),
                  SizedBox(width: spacing),
                  Expanded(child: endBox),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(TransactionHistoryViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8EA1D1).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: _accentBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nothing to show yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.emptyStateMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: vm.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = vm.sections[sectionIndex];
        return _buildSection(section);
      },
    );
  }

  Widget _buildSection(TransactionSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _cardBorder),
            ),
            child: Text(
              section.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ),
        ),
        ...section.items.map((tx) => _buildTransactionCard(tx, context)),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionItem tx, BuildContext context) {
    final isHalin = tx.type == 'Halin';
    final isHalinUtang = isHalin && (tx.isUtangSale == true);

    final isExpense = tx.type == 'Gasto';
    final isCapital = tx.type == 'Capital';
    final isCustomerPayment = tx.type == 'Customer Payment';
    final isOwnerPayment = tx.type == 'Owner Payment';
    final isDownpayment = tx.type == 'Downpayment';

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
        ? '${tx.description ?? ''} downpayment'
        : (tx.description ?? '');

    final capitalNote = (tx.description ?? '').trim().isEmpty
        ? 'N/A'
        : tx.description!.trim();

    final isIncome = isCapital || isHalin || isCustomerPayment;
    final amountColor =
        isIncome ? const Color(0xFF0B8E5F) : const Color(0xFFC04E4E);

    final amountText = isIncome
        ? '+${_currencyFormatter.format((tx.amount ?? 0).abs())}'
        : '-${_currencyFormatter.format((tx.amount ?? 0).abs())}';

    final accentColor = isCapital
        ? const Color(0xFFF4A63D)
        : isExpense
            ? const Color(0xFFE46A5A)
            : isCustomerPayment
                ? const Color(0xFF1EAF8A)
                : isOwnerPayment || isDownpayment
                    ? const Color(0xFF7D6BF2)
                    : _accentBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _cardBg,
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8EA1D1).withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isExpense
                        ? Icons.receipt_long_rounded
                        : isCapital
                            ? Icons.savings_rounded
                            : isCustomerPayment
                                ? Icons.people_alt_rounded
                                : isOwnerPayment || isDownpayment
                                    ? Icons.payments_outlined
                                    : Icons.shopping_bag_outlined,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (isExpense ||
                                isCustomerPayment ||
                                isOwnerPayment ||
                                isDownpayment)
                            ? descriptionLabel
                            : isCapital
                                ? 'Capital movement'
                                : (tx.productName ?? 'Product'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        amountText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: amountColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('hh:mm a').format(tx.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMetaWrap(tx, capitalNote)),
                if (isExpense && tx.receiptImagePath != null) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accentBlue,
                        side: const BorderSide(color: Color(0xFFD6E0F6)),
                        backgroundColor: const Color(0xFFF5F8FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                      child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'View Receipt',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaWrap(TransactionItem tx, String capitalNote) {
    final isExpense = tx.type == 'Gasto';
    final isCapital = tx.type == 'Capital';
    final isHalin = tx.type == 'Halin';
    final chips = <Widget>[];

    if (isCapital) {
      chips.add(_metaChip('Note: $capitalNote'));
    } else if (isHalin && tx.quantity != null) {
      chips.add(_metaChip('Qty: ${tx.quantity}'));
    } else if (isExpense && tx.category != null) {
      chips.add(_metaChip('Category: ${tx.category}'));
    }

    if ((tx.recordedBy ?? '').trim().isNotEmpty) {
      chips.add(_metaChip('By ${tx.recordedBy!.trim()}'));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE5F8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textSecondary,
        ),
      ),
    );
  }
}

// ---------------- Date Picker ----------------
class _DatePickerBox extends StatelessWidget {
  final String title;
  final DateTime date;
  final ValueChanged<DateTime?> onDateSelected;
  final bool compact;

  const _DatePickerBox({
    required this.title,
    required this.date,
    required this.onDateSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date.isAfter(now) ? now : date,
          firstDate: DateTime(2000),
          lastDate: now,
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
        padding: EdgeInsets.symmetric(
          vertical: compact ? 10 : 12,
          horizontal: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF7FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE5F8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8EA1D1).withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 11.5 : 12.5,
                      color: const Color(0xFF60739B),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    DateFormat(compact ? 'MMM d, y' : 'MMMM d, y').format(date),
                    style: TextStyle(
                      fontSize: compact ? 13 : 15,
                      color: const Color(0xFF213A6B),
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 6 : 10),
            Container(
              width: compact ? 30 : 34,
              height: compact ? 30 : 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF2FF),
                    Color(0xFFD8E7FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: compact ? 15 : 17,
                color: const Color(0xFF2F6BFF),
              ),
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
  final ScrollController scrollController;

  const CategoryChipsWithDots({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            controller: scrollController,
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
                    color: isSelected
                        ? const Color(0xFF205CC8)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF205CC8)
                          : const Color(0xFFDDE5F8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8EA1D1).withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF213A6B),
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
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 8 : 6,
              height: isSelected ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF205CC8)
                    : const Color(0xFFBFC9E2),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
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
      symbol: '\u20B1 ',
      decimalDigits: 2,
    );

    return SafeArea(
      top: false,
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
                  Text(transaction.category!, style: const TextStyle(fontSize: 16)),
                ],
              ),

            if ((isHalin || isCapital) && transaction.quantity != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity:', style: TextStyle(fontSize: 16)),
                  Text(transaction.quantity.toString(), style: const TextStyle(fontSize: 16)),
                ],
              ),

            const SizedBox(height: 8),

            if (isCapital)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Added By:', style: TextStyle(fontSize: 16)),
                  Flexible(
                    child: Text(
                      capitalAddedBy,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                  Flexible(
                    child: Text(
                      recordedByValue,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(transaction.receiptImagePath!),
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
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


