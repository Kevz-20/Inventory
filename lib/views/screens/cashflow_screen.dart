import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/current_user.dart';
import '../../core/app_colors.dart';
import '../../models/cashflow_model.dart';
import '../../view_models/cashflow_view_model.dart';
import '../widgets/header.dart';
import '../widgets/adaptive_digits_text.dart';

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  bool _loading = true;
  final ScrollController _listController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCashflows();
  }

  @override
  void dispose() {
    _listController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _loadCashflows() async {
    final vm = ref.read(cashflowViewModelProvider);
    try {
      await vm.loadCashflows();
    } catch (e) {
      debugPrint('Error fetching cashflows: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
      customPattern: '₱#,##0',
    );
    return formatter.format(value);
  }

  Size _screenSize(BuildContext context) => MediaQuery.of(context).size;

  double _screenWidth(BuildContext context) => _screenSize(context).width;

  bool _isTablet(BuildContext context) => _screenWidth(context) >= 700;

  double _responsiveScale(BuildContext context) {
    final width = _screenWidth(context);
    if (width < 360) return 0.88;
    if (width < 400) return 0.94;
    if (width < 700) return 1.00;
    if (width < 1000) return 1.10;
    return 1.18;
  }

  double _r(BuildContext context, double value) {
    final scaled = value * _responsiveScale(context);
    final min = value * 0.82;
    final max = value * 1.28;
    return scaled.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cashflowViewModelProvider);
    final records = vm.filteredRecords;
    final isTablet = _isTablet(context);
    final maxContentWidth = isTablet ? 980.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Cash Flow', showBackButton: true),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _r(context, 16),
              _r(context, 12),
              _r(context, 16),
              _r(context, 16),
            ),
            child: Column(
              children: [
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : records.isEmpty
                      ? _buildEmptyState(context)
                      : _buildCashflowTable(context, records),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UPDATED CASHFLOW DETAILS DIALOG (UI only)
  // ============================================================

  void _showCashflowDetails(CashflowRecord record) {
    final itemLower = record.item.toLowerCase();
    final isInstallment = itemLower.contains('downpayment');
    final hasCashIn = record.cashIn > 0;
    final hasCashOut = record.cashOut > 0;

    // ✅ Build fallback name exactly like TransactionHistory
    final currentUserName = [
      CurrentUser.firstName ?? '',
      CurrentUser.middleName ?? '',
      CurrentUser.lastName ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();

    final recordedByValue = (record.recordedBy ?? '').trim().isNotEmpty
        ? record.recordedBy!.trim()
        : (currentUserName.isNotEmpty ? currentUserName : 'System');

    // Determine chip label + color (purely UI)
    Color chipColor;
    String chipText;

    if (isInstallment) {
      chipColor = Colors.blue;
      chipText = 'Installment';
    } else if (hasCashIn && !hasCashOut) {
      chipColor = Colors.green;
      chipText = 'Cash In';
    } else if (!hasCashIn && hasCashOut) {
      chipColor = Colors.red;
      chipText = 'Cash Out';
    } else {
      chipColor = Colors.grey;
      chipText = 'Record';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cashflow Details',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TOP CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _typeChip(chipText, chipColor),
                          Text(
                            '${record.formattedDate} • ${record.formattedTime}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        record.item,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // SUMMARY CARDS
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        label: 'Cash In',
                        value: record.cashIn == 0
                            ? '—'
                            : _formatCurrency(record.cashIn),
                        color: Colors.green,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        label: 'Cash Out',
                        value: record.cashOut == 0
                            ? '—'
                            : _formatCurrency(record.cashOut),
                        color: Colors.red,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _summaryCard(
                  label: 'Balance',
                  value: _formatCurrency(record.balance),
                  color: AppColors.primary,
                  icon: Icons.account_balance_wallet_rounded,
                  isWide: true,
                ),

                const SizedBox(height: 12),

                // DETAILS LIST
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _detailRow('Date', record.formattedDate),
                      _divider(),
                      _detailRow('Time', record.formattedTime),
                      _divider(),

                      // ✅ NEW: Recorded By
                      _detailRow(
                        'Recorded By',
                        recordedByValue,
                        multiline: true,
                      ),
                      _divider(),

                      _detailRow('Item', record.item, multiline: true),
                      _divider(),
                      _detailRow(
                        'Cash In',
                        record.cashIn == 0
                            ? '—'
                            : _formatCurrency(record.cashIn),
                        valueColor: Colors.green,
                        boldValue: true,
                      ),
                      _divider(),
                      _detailRow(
                        'Cash Out',
                        record.cashOut == 0
                            ? '—'
                            : _formatCurrency(record.cashOut),
                        valueColor: Colors.red,
                        boldValue: true,
                      ),
                      _divider(),
                      _detailRow(
                        'Balance',
                        _formatCurrency(record.balance),
                        valueColor: AppColors.primary,
                        boldValue: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Helpers (UI only)
  // ============================================================

  Widget _divider() =>
      Divider(height: 14, thickness: 1, color: Colors.grey.withAlpha(40));

  Widget _typeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                AdaptiveDigitsText(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: isWide ? 18 : 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool boldValue = false,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: multiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: boldValue ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER + ROW (Date column removed)
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(_r(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_r(context, 18)),
          border: Border.all(color: const Color(0xFFD5E7E1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _r(context, 54),
              height: _r(context, 54),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(_r(context, 16)),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary,
                size: _r(context, 28),
              ),
            ),
            SizedBox(height: _r(context, 12)),
            Text(
              'No cashflow records yet',
              style: TextStyle(
                fontSize: _r(context, 16),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF143D34),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _r(context, 4)),
            Text(
              'Transactions will appear here once cash movement is recorded.',
              style: TextStyle(
                fontSize: _r(context, 12.5),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6A8580),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashflowTable(
    BuildContext context,
    List<CashflowRecord> records,
  ) {
    final minTableWidth = _isTablet(context) ? 0.0 : 620.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_r(context, 18)),
            border: Border.all(color: const Color(0xFFD5E7E1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0C4B3E).withValues(alpha: 0.05),
                blurRadius: _r(context, 14),
                offset: Offset(0, _r(context, 8)),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_r(context, 18)),
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth < minTableWidth
                      ? minTableWidth
                      : constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: Scrollbar(
                          controller: _listController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _listController,
                            itemCount: records.length,
                            itemBuilder: (_, i) =>
                                _buildRow(context, records[i], i),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerTop, AppColors.headerBottom],
        ),
      ),
      child: Row(
        children: [
          _HeaderCell(
            'Item',
            flex: 4,
            align: TextAlign.center,
            color: Colors.white,
            showRightBorder: true,
            height: _r(context, 48),
            fontSize: _r(context, 13),
          ),
          _HeaderCell(
            'In',
            flex: 3,
            align: TextAlign.center,
            color: const Color(0xFF86F0A5),
            showRightBorder: true,
            height: _r(context, 48),
            fontSize: _r(context, 13),
          ),
          _HeaderCell(
            'Out',
            flex: 3,
            align: TextAlign.center,
            color: const Color(0xFFFF9A94),
            showRightBorder: true,
            height: _r(context, 48),
            fontSize: _r(context, 13),
          ),
          _HeaderCell(
            'Balance',
            flex: 3,
            align: TextAlign.center,
            color: Colors.white,
            height: _r(context, 48),
            fontSize: _r(context, 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, CashflowRecord r, int index) {
    r.item.toLowerCase().contains('downpayment');

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? const Color(0xFFFCFEFD) : const Color(0xFFF5FAF8),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD6E6E0).withValues(alpha: 0.9),
          ),
        ),
      ),
      child: InkWell(
        splashColor: AppColors.primary.withAlpha(18),
        highlightColor: AppColors.primary.withAlpha(8),
        onTap: () => _showCashflowDetails(r),
        child: Row(
          children: [
            _buildTableRowCell(
              context: context,
              flex: 4,
              showRightBorder: true,
              child: _buildItemCell(r.item),
            ),
            _buildTableRowCell(
              context: context,
              flex: 3,
              showRightBorder: true,
              child: _buildAmountCell(
                r.cashIn == 0 ? '-' : _formatCurrency(r.cashIn),
                color: Colors.green,
                bold: true,
                forceAnimateWhenEligible: true,
              ),
            ),
            _buildTableRowCell(
              context: context,
              flex: 3,
              showRightBorder: true,
              child: _buildAmountCell(
                r.cashOut == 0 ? '-' : _formatCurrency(r.cashOut),
                color: Colors.red,
                bold: true,
                forceAnimateWhenEligible: true,
              ),
            ),
            _buildTableRowCell(
              context: context,
              flex: 3,
              child: _buildAmountCell(
                _formatCurrency(r.balance),
                bold: true,
                forceAnimateWhenEligible: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRowCell({
    required BuildContext context,
    required int flex,
    required Widget child,
    bool showRightBorder = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: _r(context, 54),
        padding: EdgeInsets.symmetric(horizontal: _r(context, 10)),
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: showRightBorder
              ? Border(
                  right: BorderSide(
                    color: const Color(0xFFD6E6E0).withValues(alpha: 0.9),
                  ),
                )
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildItemCell(String text) {
    final forceAnimate = _hasTenOrMoreLetters(text);
    return _MarqueeText(
      text: text,
      textAlign: TextAlign.center,
      forceAnimate: forceAnimate,
      style: const TextStyle(
        color: Color(0xFF143D34),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAmountCell(
    String text, {
    Color? color,
    bool bold = false,
    bool forceAnimateWhenEligible = false,
  }) {
    final shouldAnimate =
        forceAnimateWhenEligible && _hasSevenOrMoreDigits(text);
    final isDash = text.trim() == '-';
    final style = TextStyle(
      color: color ?? Colors.black87,
      fontWeight: (bold || isDash) ? FontWeight.w900 : FontWeight.normal,
      fontSize: 14,
    );

    return shouldAnimate
        ? _MarqueeText(
            text: text,
            style: style,
            textAlign: TextAlign.center,
            forceAnimate: forceAnimateWhenEligible,
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: style,
            ),
          );
  }

  bool _hasSevenOrMoreDigits(String value) {
    return RegExp(r'\d').allMatches(value).length >= 7;
  }

  bool _hasTenOrMoreLetters(String value) {
    return RegExp(r'[A-Za-z]').allMatches(value).length >= 10;
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final bool forceAnimate;

  const _MarqueeText({
    required this.text,
    required this.style,
    required this.textAlign,
    this.forceAnimate = false,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const double _gap = 24;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || !maxWidth.isFinite) {
          return const SizedBox.shrink();
        }

        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();

        final textWidth = tp.width;
        final shouldAnimate = widget.forceAnimate && textWidth > maxWidth;

        if (!shouldAnimate) {
          return SizedBox(
            width: maxWidth,
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: widget.textAlign,
              style: widget.style,
            ),
          );
        }

        final travel = textWidth + _gap;
        final trackWidth = (textWidth * 2) + _gap;

        return SizedBox(
          width: maxWidth,
          height: tp.height + 2,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                final offset = -travel * _controller.value;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: trackWidth,
                child: SizedBox(
                  width: trackWidth,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          style: widget.style,
                        ),
                      ),
                      Positioned(
                        left: textWidth + _gap,
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          style: widget.style,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  final Color color;
  final bool showRightBorder;
  final double height;
  final double fontSize;

  const _HeaderCell(
    this.text, {
    required this.flex,
    this.align = TextAlign.center,
    this.color = Colors.white,
    this.showRightBorder = false,
    this.height = 42,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: showRightBorder
              ? Border(right: BorderSide(color: Colors.grey.withAlpha(90)))
              : null,
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
