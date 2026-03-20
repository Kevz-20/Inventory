// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use

import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/current_user.dart';
import '../../view_models/transaction_history_view_model.dart';

// ─── Design Tokens (matches home_screen.dart palette) ─────────────────────────
class _C {
  static const bg        = Color(0xFFF0F4FF);
  static const surface   = Color(0xFFFFFFFF);
  static const border    = Color(0xFFCDD5EE);
  static const brandDeep = Color(0xFF1B3A7A);
  static const brandMid  = Color(0xFF5B6D96);
  static const textDark  = Color(0xFF1B3A7A);

  // Transaction type accent colours
  static const sale          = Color(0xFF2D5BE3);
  static const saleBg        = Color(0xFFEEF2FF);
  static const saleUtang     = Color(0xFF6C3FC4);
  static const saleUtangBg   = Color(0xFFF3EEFF);
  static const expense       = Color(0xFFD63031);
  static const expenseBg     = Color(0xFFFFF0F0);
  static const capital       = Color(0xFFE67E00);
  static const capitalBg     = Color(0xFFFFF3E0);
  static const custPayment   = Color(0xFF00897B);
  static const custPaymentBg = Color(0xFFE0F2F1);
  static const ownerPayment  = Color(0xFF6C3FC4);
  static const ownerPaymentBg= Color(0xFFF3EEFF);

  static const incomeGreen   = Color(0xFF0B7A52);
  static const expenseRed    = Color(0xFFC04E4E);
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late final TransactionHistoryViewModel viewModel;
  final ScrollController _scrollController         = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  late final PageController _categoryPageController;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH', symbol: '₱ ', decimalDigits: 2,
  );

  static const List<TransactionCategory> _cats = [
    TransactionCategory.all,
    TransactionCategory.expenses,
    TransactionCategory.sales,
    TransactionCategory.capitalManagement,
    TransactionCategory.customerPayment,
    TransactionCategory.ownerPayment,
  ];

  double _r(double v) {
    final w = MediaQuery.of(context).size.width;
    return v * (w / 390).clamp(0.85, 1.15);
  }

  @override
  void initState() {
    super.initState();
    viewModel = TransactionHistoryViewModel();
    _categoryPageController = PageController();
    _scrollController.addListener(_onScroll);
  }

  void _autoScrollChips(int index) {
    if (!_categoryScrollController.hasClients) return;
    const chipW = 110.0;
    final sw = MediaQuery.of(context).size.width;
    final scrollTo = (index * chipW) - (sw / 2) + (chipW / 2);
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

  // ── Type helpers ─────────────────────────────────────────────────────────────
  Color _accentOf(TransactionItem tx) {
    if (tx.type == 'Halin') return (tx.isUtangSale == true) ? _C.saleUtang : _C.sale;
    if (tx.type == 'Gasto')             return _C.expense;
    if (tx.type == 'Capital')           return _C.capital;
    if (tx.type == 'Customer Payment')  return _C.custPayment;
    if (tx.type == 'Owner Payment' || tx.type == 'Downpayment') return _C.ownerPayment;
    return _C.sale;
  }

  Color _accentBgOf(TransactionItem tx) {
    if (tx.type == 'Halin') return (tx.isUtangSale == true) ? _C.saleUtangBg : _C.saleBg;
    if (tx.type == 'Gasto')             return _C.expenseBg;
    if (tx.type == 'Capital')           return _C.capitalBg;
    if (tx.type == 'Customer Payment')  return _C.custPaymentBg;
    if (tx.type == 'Owner Payment' || tx.type == 'Downpayment') return _C.ownerPaymentBg;
    return _C.saleBg;
  }

  IconData _iconOf(TransactionItem tx) {
    if (tx.type == 'Gasto')             return Icons.receipt_long_rounded;
    if (tx.type == 'Capital')           return Icons.account_balance_rounded;
    if (tx.type == 'Customer Payment')  return Icons.people_alt_rounded;
    if (tx.type == 'Owner Payment' || tx.type == 'Downpayment') return Icons.payments_outlined;
    return Icons.shopping_bag_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 700;

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<TransactionHistoryViewModel>(
        builder: (_, vm, _) {
          return Scaffold(
            backgroundColor: _C.bg,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(_r(64)),
              child: AppBar(
                backgroundColor: _C.surface,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                toolbarHeight: _r(64),
                leading: IconButton(
                  onPressed: () => context.canPop()
                      ? context.pop() : context.go('/home'),
                  icon: Image.asset(
                    'lib/assets/arrowleft.png',
                    width: _r(22), height: _r(22),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: _r(18),
                      color: _C.brandDeep,
                    ),
                  ),
                ),
                title: Text('History',
                    style: TextStyle(
                      fontSize: _r(18), fontWeight: FontWeight.w900,
                      color: _C.brandDeep, letterSpacing: 0.2,
                    )),
                centerTitle: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _C.border),
                ),
              ),
            ),

            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isTablet ? 760.0 : double.infinity),
                  child: Column(children: [
                    // Filter + category chips
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          _r(16), _r(14), _r(16), _r(10)),
                      child: Column(children: [
                        _buildFilterPanel(vm),
                        SizedBox(height: _r(12)),
                        _CategoryChips(
                          scrollController: _categoryScrollController,
                          categories: _cats,
                          selected: vm.selectedCategory,
                          onSelect: (cat) {
                            final idx = _cats.indexOf(cat);
                            vm.setSelectedCategory(cat);
                            if (idx >= 0) {
                              _categoryPageController.animateToPage(idx,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeInOut);
                              _autoScrollChips(idx);
                            }
                          },
                          r: _r,
                        ),
                      ]),
                    ),

                    // Transaction list
                    Expanded(
                      child: PageView.builder(
                        controller: _categoryPageController,
                        itemCount: _cats.length,
                        onPageChanged: (i) {
                          vm.setSelectedCategory(_cats[i]);
                          _autoScrollChips(i);
                        },
                        itemBuilder: (_, _) => _buildList(vm),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Filter panel ─────────────────────────────────────────────────────────────
  Widget _buildFilterPanel(TransactionHistoryViewModel vm) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_r(14)),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(_r(20)),
        border: Border.all(color: _C.border, width: 1.5),
        boxShadow: [BoxShadow(
          color: _C.brandDeep.withOpacity(0.07),
          blurRadius: _r(14), offset: Offset(0, _r(4)),
        )],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxWidth < 420;
        return Row(children: [
          Expanded(child: _DateBox(
            title: 'Start Date', date: vm.startDate ?? DateTime.now(),
            onPicked: vm.setStartDate, compact: compact, r: _r,
          )),
          SizedBox(width: _r(compact ? 8 : 12)),
          Expanded(child: _DateBox(
            title: 'End Date', date: vm.endDate ?? DateTime.now(),
            onPicked: vm.setEndDate, compact: compact, r: _r,
          )),
        ]);
      }),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────────
  Widget _buildList(TransactionHistoryViewModel vm) {
    if (vm.isLoading) {
      return Center(child: CircularProgressIndicator(
          color: _C.brandDeep, strokeWidth: 2.5));
    }

    if (vm.sections.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(_r(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: _r(80), height: _r(80),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF), shape: BoxShape.circle,
                border: Border.all(color: _C.border, width: 2),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: _r(38), color: _C.brandMid),
            ),
            SizedBox(height: _r(18)),
            Text('Nothing to show yet',
                style: TextStyle(fontSize: _r(17),
                    fontWeight: FontWeight.w900, color: _C.brandDeep)),
            SizedBox(height: _r(8)),
            Text(vm.emptyStateMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: _r(13.5),
                    fontWeight: FontWeight.w600,
                    color: _C.brandMid, height: 1.5)),
          ]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(_r(16), _r(4), _r(16), _r(20)),
      itemCount: vm.sections.length,
      itemBuilder: (_, i) => _buildSection(vm.sections[i]),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────────
  Widget _buildSection(TransactionSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: _r(10)),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: _r(14), vertical: _r(6)),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(_r(999)),
              border: Border.all(color: _C.border, width: 1.5),
              boxShadow: [BoxShadow(
                color: _C.brandDeep.withOpacity(0.05),
                blurRadius: _r(8), offset: Offset(0, _r(2)),
              )],
            ),
            child: Text(section.title,
                style: TextStyle(
                  fontSize: _r(13),
                  fontWeight: FontWeight.w800,
                  color: _C.brandDeep,
                )),
          ),
        ),
        ...section.items.map((tx) => _buildCard(tx)),
        SizedBox(height: _r(4)),
      ],
    );
  }

  // ── Transaction card ──────────────────────────────────────────────────────────
  Widget _buildCard(TransactionItem tx) {
    final isHalin         = tx.type == 'Halin';
    final isHalinUtang    = isHalin && (tx.isUtangSale == true);
    final isExpense       = tx.type == 'Gasto';
    final isCapital       = tx.type == 'Capital';
    final isCustomerPay   = tx.type == 'Customer Payment';
    final isOwnerPay      = tx.type == 'Owner Payment';
    final isDownpayment   = tx.type == 'Downpayment';

    final typeLabel = isDownpayment ? 'Owner Payment'
        : isHalinUtang ? 'Sale (Credit)' : isHalin ? 'Sale'
        : isExpense ? 'Expense' : isCapital ? 'Capital'
        : isCustomerPay ? 'Customer Payment'
        : isOwnerPay ? 'Owner Payment' : tx.type;

    final mainLabel = (isExpense || isCustomerPay || isOwnerPay || isDownpayment)
        ? (isDownpayment
            ? '${tx.description ?? ''} downpayment'
            : (tx.description ?? ''))
        : isCapital ? 'Capital Movement'
        : (tx.productName ?? 'Product');

    final isIncome = isCapital || isHalin || isCustomerPay;
    final amtColor = isIncome ? _C.incomeGreen : _C.expenseRed;
    final amtText  = isIncome
        ? '+${_currency.format((tx.amount ?? 0).abs())}'
        : '-${_currency.format((tx.amount ?? 0).abs())}';

    final accent   = _accentOf(tx);
    final accentBg = _accentBgOf(tx);
    final icon     = _iconOf(tx);

    return InkWell(
      borderRadius: BorderRadius.circular(_r(20)),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DetailsSheet(
            transaction: tx, currency: _currency, r: _r),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: _r(10)),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(_r(20)),
          border: Border.all(color: _C.border, width: 1.5),
          boxShadow: [BoxShadow(
            color: _C.brandDeep.withOpacity(0.07),
            blurRadius: _r(12), offset: Offset(0, _r(3)),
          )],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: _r(5),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.only(
                    topLeft:    Radius.circular(_r(20)),
                    bottomLeft: Radius.circular(_r(20)),
                  ),
                ),
              ),
              // Card body
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      _r(12), _r(12), _r(14), _r(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon badge
                          Container(
                            width: _r(44), height: _r(44),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accentBg,
                              borderRadius: BorderRadius.circular(_r(13)),
                            ),
                            child: Icon(icon, color: accent, size: _r(22)),
                          ),
                          SizedBox(width: _r(11)),
                          // Type + name
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(typeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: _r(11.5),
                                    fontWeight: FontWeight.w700,
                                    color: _C.brandMid,
                                  )),
                              SizedBox(height: _r(3)),
                              Text(mainLabel.isEmpty ? '—' : mainLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: _r(14.5),
                                    fontWeight: FontWeight.w800,
                                    color: _C.textDark,
                                    height: 1.25,
                                  )),
                            ],
                          )),
                          SizedBox(width: _r(8)),
                          // Amount + time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(amtText,
                                  style: TextStyle(
                                    fontSize: _r(13.5),
                                    fontWeight: FontWeight.w900,
                                    color: amtColor,
                                  )),
                              SizedBox(height: _r(4)),
                              Text(DateFormat('hh:mm a').format(tx.createdAt),
                                  style: TextStyle(
                                    fontSize: _r(11.5),
                                    color: _C.brandMid,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ],
                      ),

                      // Meta chips
                      Builder(builder: (_) {
                        final chips = _metaChips(tx);
                        if (chips.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(top: _r(10)),
                          child: Wrap(
                              spacing: _r(7), runSpacing: _r(7),
                              children: chips),
                        );
                      }),

                      // View receipt button
                      if (isExpense && tx.receiptImagePath != null)
                        Padding(
                          padding: EdgeInsets.only(top: _r(10)),
                          child: GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.file(
                                      File(tx.receiptImagePath!),
                                      fit: BoxFit.contain),
                                ),
                              ),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: _r(12), vertical: _r(7)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(_r(10)),
                                border: Border.all(
                                    color: _C.border, width: 1),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min,
                                  children: [
                                Icon(Icons.image_outlined,
                                    size: _r(14), color: _C.brandDeep),
                                SizedBox(width: _r(5)),
                                Text('View Receipt',
                                    style: TextStyle(
                                      fontSize: _r(12),
                                      fontWeight: FontWeight.w700,
                                      color: _C.brandDeep,
                                    )),
                              ]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _metaChips(TransactionItem tx) {
    final chips = <Widget>[];

    void add(String label, IconData icon) {
      chips.add(Container(
        padding: EdgeInsets.symmetric(
            horizontal: _r(9), vertical: _r(5)),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(_r(999)),
          border: Border.all(color: _C.border, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: _r(12), color: _C.brandMid),
          SizedBox(width: _r(4)),
          Text(label,
              style: TextStyle(
                fontSize: _r(11.5),
                fontWeight: FontWeight.w700,
                color: _C.brandMid,
              )),
        ]),
      ));
    }

    if (tx.type == 'Capital') {
      final note = (tx.description ?? '').trim().isEmpty
          ? 'N/A' : tx.description!;
      add('Note: $note', Icons.sticky_note_2_outlined);
    } else if (tx.type == 'Halin' && tx.quantity != null) {
      add('Qty: ${tx.quantity}', Icons.inventory_2_outlined);
    } else if (tx.type == 'Gasto' && tx.category != null) {
      add(tx.category!, Icons.label_outline_rounded);
    }

    if ((tx.recordedBy ?? '').trim().isNotEmpty) {
      add('By ${tx.recordedBy!.trim()}', Icons.person_outline_rounded);
    }

    return chips;
  }
}

// ─── Date Picker Box ───────────────────────────────────────────────────────────
class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.title, required this.date, required this.onPicked,
    required this.compact, required this.r,
  });
  final String title;
  final DateTime date;
  final ValueChanged<DateTime?> onPicked;
  final bool compact;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now    = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date.isAfter(now) ? now : date,
          firstDate: DateTime(2000), lastDate: now,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
              dialogTheme: DialogThemeData(
                  backgroundColor: Colors.grey.shade100),
            ),
            child: child!,
          ),
        );
        if (picked != null && !picked.isAfter(now)) onPicked(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: r(compact ? 10 : 12),
            horizontal: r(compact ? 11 : 13)),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(r(16)),
          border: Border.all(color: const Color(0xFFCDD5EE), width: 1.5),
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: r(11),
                    color: const Color(0xFF5B6D96),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  )),
              SizedBox(height: r(3)),
              Text(
                DateFormat(compact ? 'MMM d, y' : 'MMMM d, y').format(date),
                style: TextStyle(
                  fontSize: r(compact ? 12.5 : 14),
                  color: const Color(0xFF1B3A7A),
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          SizedBox(width: r(8)),
          Container(
            width: r(32), height: r(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(r(10)),
              border: Border.all(color: const Color(0xFFCDD5EE), width: 1),
            ),
            child: Icon(Icons.calendar_today_rounded,
                size: r(15), color: const Color(0xFF2D5BE3)),
          ),
        ]),
      ),
    );
  }
}

// ─── Category Chips ────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.scrollController, required this.categories,
    required this.selected, required this.onSelect, required this.r,
  });
  final ScrollController scrollController;
  final List<TransactionCategory> categories;
  final TransactionCategory selected;
  final ValueChanged<TransactionCategory> onSelect;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: r(44),
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: categories.length,
          separatorBuilder: (_, _) => SizedBox(width: r(7)),
          itemBuilder: (_, i) {
            final cat   = categories[i];
            final isSel = selected == cat;
            return GestureDetector(
              onTap: () => onSelect(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                    horizontal: r(14), vertical: r(10)),
                decoration: BoxDecoration(
                  gradient: isSel
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A3584), Color(0xFF4B8AF0)])
                      : null,
                  color: isSel ? null : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(r(999)),
                  border: Border.all(
                    color: isSel ? Colors.transparent : const Color(0xFFCDD5EE),
                    width: 1.5,
                  ),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF1B3A7A).withOpacity(
                        isSel ? 0.18 : 0.05),
                    blurRadius: r(isSel ? 10 : 6),
                    offset: Offset(0, r(isSel ? 4 : 2)),
                  )],
                ),
                child: Text(cat.displayName,
                    style: TextStyle(
                      fontSize: r(13),
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white
                          : const Color(0xFF1B3A7A),
                    )),
              ),
            );
          },
        ),
      ),
      SizedBox(height: r(8)),
      // Pill-style indicator dots
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: categories.map((cat) {
          final isSel = selected == cat;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.symmetric(horizontal: r(3)),
            width: isSel ? r(16) : r(6),
            height: r(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r(999)),
              color: isSel ? const Color(0xFF2456D0)
                  : const Color(0xFFCDD5EE),
            ),
          );
        }).toList(),
      ),
      SizedBox(height: r(4)),
    ]);
  }
}

// ─── Transaction Details Bottom Sheet ─────────────────────────────────────────
class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({
    required this.transaction, required this.currency, required this.r,
  });
  final TransactionItem transaction;
  final NumberFormat currency;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    final tx           = transaction;
    final isExpense    = tx.type == 'Gasto';
    final isHalin      = tx.type == 'Halin';
    final isHalinUtang = isHalin && (tx.isUtangSale == true);
    final isCapital    = tx.type == 'Capital';
    final isCustomerPay= tx.type == 'Customer Payment';
    final isOwnerPay   = tx.type == 'Owner Payment';
    final isDownpayment= tx.type == 'Downpayment';

    final typeLabel = isDownpayment ? 'Owner Payment'
        : isHalinUtang ? 'Sale (Credit)' : isHalin ? 'Sale'
        : isExpense ? 'Expense' : isCapital ? 'Capital'
        : isCustomerPay ? 'Customer Payment'
        : isOwnerPay ? 'Owner Payment' : tx.type;

    final isIncome  = isCapital || isHalin || isCustomerPay;
    final amtPrefix = isCapital ? '' : isIncome ? '+' : '-';
    final amtText   = '$amtPrefix${currency.format((tx.amount ?? 0).abs())}';

    Color accent = const Color(0xFF2D5BE3);
    if (isHalinUtang || isOwnerPay || isDownpayment) {
      accent = const Color(0xFF6C3FC4);
    } else if (isExpense) {
      accent = const Color(0xFFD63031);
    } else if (isCapital) {
      accent = const Color(0xFFE67E00);
    } else if (isCustomerPay) {
      accent = const Color(0xFF00897B);
    }

    final currentUser = [
      CurrentUser.firstName ?? '',
      CurrentUser.middleName ?? '',
      CurrentUser.lastName ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();

    final recordedBy = (tx.recordedBy ?? '').trim().isEmpty
        ? currentUser : tx.recordedBy!.trim();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(r(28))),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: r(20), right: r(20), top: r(14),
            bottom: r(24) + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Drag handle
            Center(child: Container(
              width: r(44), height: r(5),
              margin: EdgeInsets.only(bottom: r(18)),
              decoration: BoxDecoration(
                color: const Color(0xFFCDD5EE),
                borderRadius: BorderRadius.circular(r(99)),
              ),
            )),

            // Header card — coloured gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(r(18)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [accent, Color.lerp(accent, Colors.white, 0.30)!],
                ),
                borderRadius: BorderRadius.circular(r(20)),
                boxShadow: [BoxShadow(
                  color: accent.withOpacity(0.28),
                  blurRadius: r(20), offset: Offset(0, r(8)),
                )],
              ),
              child: Row(children: [
                Container(
                  width: r(52), height: r(52),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(r(16)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 1.5),
                  ),
                  child: Icon(
                    isExpense ? Icons.receipt_long_rounded
                        : isCapital ? Icons.account_balance_rounded
                        : isCustomerPay ? Icons.people_alt_rounded
                        : (isOwnerPay || isDownpayment)
                            ? Icons.payments_outlined
                            : Icons.shopping_bag_outlined,
                    color: Colors.white, size: r(26),
                  ),
                ),
                SizedBox(width: r(14)),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel,
                        style: TextStyle(
                          fontSize: r(12),
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.80),
                        )),
                    SizedBox(height: r(3)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(amtText,
                          style: TextStyle(
                            fontSize: r(28),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5, height: 1.0,
                          )),
                    ),
                  ],
                )),
              ]),
            ),

            SizedBox(height: r(16)),

            // Details card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(r(16)),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(r(20)),
                border: Border.all(color: const Color(0xFFCDD5EE), width: 1.5),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF1B3A7A).withOpacity(0.06),
                  blurRadius: r(12), offset: Offset(0, r(3)),
                )],
              ),
              child: Column(children: [
                _row(r: r, icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat(isCapital
                            ? 'MMMM d, y'
                            : 'MMMM d, y  •  hh:mm a')
                        .format(tx.createdAt)),
                if (isExpense && tx.category != null) ...[
                  _divider(r),
                  _row(r: r, icon: Icons.label_outline_rounded,
                      label: 'Category', value: tx.category!),
                ],
                if ((isHalin || isCapital) && tx.quantity != null) ...[
                  _divider(r),
                  _row(r: r, icon: Icons.inventory_2_outlined,
                      label: 'Quantity', value: tx.quantity.toString()),
                ],
                if (isCapital) ...[
                  _divider(r),
                  _row(r: r, icon: Icons.person_outline_rounded,
                      label: 'Added By', value: recordedBy),
                ] else if (isHalin || isExpense || isCustomerPay ||
                    isOwnerPay || isDownpayment) ...[
                  _divider(r),
                  _row(r: r, icon: Icons.person_outline_rounded,
                      label: 'Recorded By', value: recordedBy),
                ],
              ]),
            ),

            // Receipt
            if (isExpense && tx.receiptImagePath != null) ...[
              SizedBox(height: r(16)),
              Text('Receipt',
                  style: TextStyle(
                    fontSize: r(13), fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B3A7A),
                  )),
              SizedBox(height: r(8)),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(child: InteractiveViewer(
                    child: Image.file(File(tx.receiptImagePath!),
                        fit: BoxFit.contain),
                  )),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r(16)),
                  child: Image.file(File(tx.receiptImagePath!),
                      height: r(170), width: double.infinity,
                      fit: BoxFit.cover),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _row({
    required double Function(double) r,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r(10)),
      child: Row(children: [
        Container(
          width: r(34), height: r(34),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(r(10)),
          ),
          child: Icon(icon, size: r(16), color: const Color(0xFF5B6D96)),
        ),
        SizedBox(width: r(12)),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: r(11), fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B6D96),
                )),
            SizedBox(height: r(2)),
            Text(value,
                style: TextStyle(
                  fontSize: r(14), fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B3A7A),
                )),
          ],
        )),
      ]),
    );
  }

  Widget _divider(double Function(double) r) => Container(
    height: 1, color: const Color(0xFFEEF2FF),
    margin: EdgeInsets.symmetric(horizontal: r(2)),
  );
}
