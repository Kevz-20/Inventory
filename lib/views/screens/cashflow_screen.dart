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

  @override
  void initState() {
    super.initState();
    _loadCashflows();
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

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cashflowViewModelProvider);
    final records = vm.filteredRecords;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Cash Flow', showBackButton: true),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                ? const Center(
                    child: Text(
                      'No cashflow records yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (_, i) => _buildRow(records[i]),
                  ),
          ),
        ],
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
                        color: isInstallment ? Colors.blue : Colors.green,
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
                        valueColor: isInstallment ? Colors.blue : Colors.green,
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

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withAlpha(90)),
      ),
      child: Row(
        children: const [
          _HeaderCell(
            'Item',
            flex: 4,
            align: TextAlign.center,
            color: Colors.white,
            showRightBorder: true,
          ),
          _HeaderCell(
            'In',
            flex: 3,
            align: TextAlign.center,
            color: Colors.green,
            showRightBorder: true,
          ),
          _HeaderCell(
            'Out',
            flex: 3,
            align: TextAlign.center,
            color: Colors.red,
            showRightBorder: true,
          ),
          _HeaderCell(
            'Balance',
            flex: 3,
            align: TextAlign.center,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(CashflowRecord r) {
    final isInstallment = r.item.toLowerCase().contains('downpayment');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.withAlpha(90)),
          right: BorderSide(color: Colors.grey.withAlpha(90)),
          bottom: BorderSide(color: Colors.grey.withAlpha(90)),
        ),
      ),
      child: InkWell(
        splashColor: AppColors.primary.withAlpha(18),
        highlightColor: AppColors.primary.withAlpha(8),
        onTap: () => _showCashflowDetails(r),
        child: Row(
          children: [
            _buildTableRowCell(
              flex: 4,
              showRightBorder: true,
              child: _buildItemCell(r.item),
            ),
            _buildTableRowCell(
              flex: 3,
              showRightBorder: true,
              child: _buildAmountCell(
                r.cashIn == 0 ? '-' : _formatCurrency(r.cashIn),
                color: isInstallment ? Colors.blue : Colors.green,
                bold: true,
                forceAnimateWhenEligible: true,
              ),
            ),
            _buildTableRowCell(
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
    required int flex,
    required Widget child,
    bool showRightBorder = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: showRightBorder
              ? Border(right: BorderSide(color: Colors.grey.withAlpha(90)))
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildItemCell(String text) {
    final forceAnimate = _hasTenOrMoreLetters(text);
    return ClipRect(
      child: _MarqueeText(
        text: text,
        textAlign: TextAlign.center,
        forceAnimate: forceAnimate,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
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
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();

        final textWidth = tp.width;
        if (!widget.forceAnimate && textWidth <= maxWidth) {
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
            style: widget.style,
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

  const _HeaderCell(
    this.text, {
    required this.flex,
    this.align = TextAlign.center,
    this.color = Colors.white,
    this.showRightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
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
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
