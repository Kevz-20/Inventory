// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/payable_model.dart';
import '../../repositories/capital_management_repository.dart';
import '../../repositories/payable_repository.dart';
import '../../services/db_service.dart';
import '../widgets/dashboard_background.dart';
import '../widgets/primary_footer_nav.dart';

// ============================================================
// FORMATTERS
// ============================================================

class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;

    final number = int.tryParse(text);
    if (number == null) return oldValue;

    final formatted = formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class OwnerPayablePayment {
  final int id;
  final double amount;
  final DateTime paidAt;
  final String? note;

  OwnerPayablePayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.note,
  });

  factory OwnerPayablePayment.fromMap(Map<String, dynamic> map) {
    return OwnerPayablePayment(
      id: map['id'] as int,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAt: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      note: map['note']?.toString(),
    );
  }
}

class OwnerUtangScreen extends StatefulWidget {
  const OwnerUtangScreen({super.key});

  @override
  State<OwnerUtangScreen> createState() => _OwnerUtangScreenState();
}

class _OwnerUtangScreenState extends State<OwnerUtangScreen>
    with WidgetsBindingObserver {
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _fieldBg = Color(0xFFF8FAFF);
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _titleColor = Color(0xFF213A6B);
  static const Color _subtitleColor = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  final currencyFormat = NumberFormat("#,##0.00", "en_PH");

  int selectedFilter = 0;

  List<Payable> ownerPayables = [];
  List<Payable> filteredOwnerPayables = [];

  bool _loadedOnce = false;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isPastDueDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return false;
    final due = DateTime.tryParse(isoDate);
    if (due == null) return false;
    return _dateOnly(due).isBefore(_dateOnly(DateTime.now()));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await fetchOwnerPayables();
  }

  Future<void> fetchOwnerPayables() async {
    final payables = await PayableRepository().getAllPayables();
    if (!mounted) return;

    setState(() {
      ownerPayables = payables;
      applyOwnerFilter(selectedFilter);
    });
  }

  Future<List<OwnerPayablePayment>> fetchOwnerPaymentHistory(int payableId) async {
    final db = await DBService.instance.database;
    final result = await db.query(
      'payable_payment',
      where: 'payable_id = ?',
      whereArgs: [payableId],
      orderBy: 'date ASC',
    );

    return result.map((row) => OwnerPayablePayment.fromMap(row)).toList();
  }

  void applyOwnerFilter(int filterIndex) {
    selectedFilter = filterIndex;

    switch (filterIndex) {
      case 0:
        filteredOwnerPayables = List.from(ownerPayables);
        break;
      case 1:
        filteredOwnerPayables = ownerPayables
            .where(
              (p) =>
                  !p.isPaid &&
                  _isPastDueDate(p.isInstallment ? p.nextDueDate : p.dueDate),
            )
            .toList();
        break;
      case 2:
        filteredOwnerPayables = ownerPayables.where((p) => p.isPaid).toList();
        break;
      default:
        filteredOwnerPayables = List.from(ownerPayables);
    }

    sortOwnerPayablesByDueDate();
    setState(() {});
  }

  void sortOwnerPayablesByDueDate() {
    filteredOwnerPayables.sort((a, b) {
      if (a.isPaid && !b.isPaid) return 1;
      if (!a.isPaid && b.isPaid) return -1;

      DateTime? dateA = DateTime.tryParse(
        a.isInstallment ? (a.nextDueDate ?? '') : (a.dueDate ?? ''),
      );
      DateTime? dateB = DateTime.tryParse(
        b.isInstallment ? (b.nextDueDate ?? '') : (b.dueDate ?? ''),
      );

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateA.compareTo(dateB);
    });
  }

  // ============================================================
  // OWNER PAYMENT LOGIC
  // ============================================================

  DateTime addMonths(DateTime date, int months) {
    int year = date.year + ((date.month + months - 1) ~/ 12);
    int month = (date.month + months - 1) % 12 + 1;
    int day = date.day;

    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfMonth) day = lastDayOfMonth;

    return DateTime(year, month, day);
  }

  Future<double?> promptPartialAmount(
    double remaining, {
    double? suggested,
  }) async {
    double? initialAmount;
    if (suggested != null && suggested > 0) {
      initialAmount = suggested > remaining ? remaining : suggested;
    }

    final controller = TextEditingController(
      text: initialAmount != null
          ? currencyFormat.format(initialAmount).replaceAll('.00', '')
          : '',
    );

    double? value = initialAmount;
    bool didConfirm = false;

    double parseAmount(String v) =>
        double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    String money(double v) => "₱${currencyFormat.format(v)}";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return LayoutBuilder(
          builder: (context, c) {
            final s = (c.maxWidth / 390).clamp(0.90, 1.15);
            final t18 = (18 * s).clamp(16.0, 20.0);
            final t14 = (14 * s).clamp(12.5, 15.0);
            final t20 = (20 * s).clamp(18.0, 22.0);
            final padH = (14 * s).clamp(12.0, 16.0);
            final padV = (14 * s).clamp(12.0, 16.0);
            final r14 = (14 * s).clamp(12.0, 16.0);
            final r18 = (18 * s).clamp(16.0, 22.0);

            return StatefulBuilder(
              builder: (dialogContext, setState) {
                final current = value ?? 0.0;
                final hasSuggested = (suggested != null && suggested > 0);
                final isValid = current > 0 && current <= remaining && remaining > 0;
                final overLimit = current > remaining && remaining > 0;

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(r18),
                  ),
                  titlePadding: EdgeInsets.fromLTRB(
                    (18 * s).clamp(14.0, 20.0),
                    (18 * s).clamp(14.0, 20.0),
                    (18 * s).clamp(14.0, 20.0),
                    (8 * s).clamp(6.0, 10.0),
                  ),
                  contentPadding: EdgeInsets.fromLTRB(
                    (18 * s).clamp(14.0, 20.0),
                    0,
                    (18 * s).clamp(14.0, 20.0),
                    (8 * s).clamp(6.0, 10.0),
                  ),
                  actionsPadding: EdgeInsets.fromLTRB(
                    (12 * s).clamp(10.0, 14.0),
                    0,
                    (12 * s).clamp(10.0, 14.0),
                    (12 * s).clamp(10.0, 14.0),
                  ),
                  title: Text(
                    "Partial Payment",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: t18),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Remaining: ${money(remaining)}",
                        style: TextStyle(
                          fontSize: t14,
                          color: _titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasSuggested) ...[
                        SizedBox(height: (8 * s).clamp(6.0, 10.0)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Monthly: ${money(suggested)}",
                                style: TextStyle(
                                  fontSize: t20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: (12 * s).clamp(10.0, 14.0)),
                      if (suggested == null || suggested == 0)
                        TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsFormatter()],
                          style: TextStyle(
                            fontSize: (18 * s).clamp(16.0, 20.0),
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            prefixText: "₱ ",
                            hintText: "Enter amount",
                            filled: true,
                            fillColor: _fieldBg,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: padH,
                              vertical: padV,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(r14),
                              borderSide: BorderSide(color: _cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(r14),
                              borderSide: BorderSide(color: _cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(r14),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                          onChanged: (v) => setState(() {
                            value = parseAmount(v);
                          }),
                        ),
                      if (overLimit)
                        Padding(
                          padding: EdgeInsets.only(top: (8 * s).clamp(6.0, 10.0)),
                          child: Text(
                            "Too high (exceeds remaining).",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: (13 * s).clamp(12.0, 14.0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        value = null;
                        Navigator.pop(dialogContext);
                      },
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: isValid
                          ? () {
                              value = parseAmount(controller.text);
                              didConfirm = true;
                              Navigator.pop(dialogContext);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r14),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: (18 * s).clamp(14.0, 20.0),
                          vertical: (12 * s).clamp(10.0, 14.0),
                        ),
                      ),
                      child: const Text("Confirm"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    return didConfirm ? value : null;
  }

  Future<void> applyPayment(
    Payable item,
    double amount, {
    bool isFullPay = false,
  }) async {
    try {
      final db = await DBService.instance.database;
      final double remaining = (item.remainingAmount ?? item.amount)
          .clamp(0.0, item.amount.toDouble())
          .toDouble();
      final payAmount = amount.clamp(0.0, remaining).toDouble();

      if (payAmount <= 0) return;

      final cashRes = await db.rawQuery(
        'SELECT IFNULL(SUM(cash_on_hand), 0) AS total_cash FROM capital_management',
      );
      final cashOnHand =
          (cashRes.first['total_cash'] as num?)?.toDouble() ?? 0.0;

      if (cashOnHand < payAmount) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              isFullPay
                  ? "You don't have enough money for Full payment"
                  : "You don't have enough money for partial payment",
            ),
          ),
        );
        return;
      }

      final capitalRepo = CapitalManagementRepository(db);
      await capitalRepo.deductCash(amount: payAmount);

      await db.insert('payable_payment', {
        'payable_id': item.id,
        'amount': payAmount,
        'date': DateTime.now().toIso8601String(),
        'note': isFullPay ? 'Full payment' : 'Partial payment',
        'created_at': DateTime.now().toIso8601String(),
      });

      final newRemaining = (remaining - payAmount).clamp(0.0, remaining);
      final updateMap = <String, dynamic>{
        'remaining_amount': newRemaining,
        'is_paid': newRemaining <= 0 ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // ✅ keep logic: after payment, move next_due_date by +1 month (simple schedule)
      if (item.isInstallment && newRemaining > 0) {
        final baseDate =
            DateTime.tryParse(item.nextDueDate ?? item.dueDate ?? '') ??
                DateTime.now();
        final nextDue = addMonths(baseDate, 1);
        updateMap['next_due_date'] = DateFormat('yyyy-MM-dd').format(nextDue);
      } else if (item.isInstallment) {
        updateMap['next_due_date'] = null;
      }

      await db.update(
        'payable',
        updateMap,
        where: 'id = ?',
        whereArgs: [item.id],
      );

      await fetchOwnerPayables();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFullPay
                ? "Full payment recorded successfully"
                : "Partial payment recorded successfully",
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final isInsufficientCash = e.toString().contains('Insufficient cash');
      final msg = isInsufficientCash
          ? 'Insufficient cash on hand'
          : 'Failed to process payment';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ============================================================
  // ✅ UPDATED BOTTOMSHEET (less redundant)
  // ============================================================

  Future<void> showOwnerUtangModal(Payable item) async {
    final paymentHistory = await fetchOwnerPaymentHistory(item.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final total = item.amount.toDouble();
        final remaining = (item.remainingAmount ?? item.amount)
            .clamp(0.0, item.amount.toDouble())
            .toDouble();
        final paidSoFar = (total - remaining).clamp(0.0, total);

        final bool isFullyPaid = item.isPaid || remaining <= 0;

        final nextDateStr = item.isInstallment ? item.nextDueDate : item.dueDate;
        final displayNextDue = (nextDateStr != null && nextDateStr.isNotEmpty)
            ? DateTime.tryParse(nextDateStr)
            : null;

        return LayoutBuilder(
          builder: (context, c) {
            final s = (c.maxWidth / 390).clamp(0.90, 1.15);
            final pad16 = (16 * s).clamp(12.0, 20.0);
            final pad14 = (14 * s).clamp(12.0, 18.0);
            final r22 = (22 * s).clamp(18.0, 26.0);
            final r16 = (16 * s).clamp(14.0, 20.0);
            final t20 = (20 * s).clamp(17.0, 22.0);
            final t15 = (15 * s).clamp(13.0, 16.0);

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.58,
                minChildSize: 0.48,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _pageBg,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(r22),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: (10 * s).clamp(8.0, 12.0),
                            bottom: (8 * s).clamp(6.0, 10.0),
                          ),
                          child: Container(
                            width: (42 * s).clamp(36.0, 48.0),
                            height: (5 * s).clamp(4.0, 6.0),
                            decoration: BoxDecoration(
                              color: _cardBorder,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: pad16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.item,
                                  style: TextStyle(
                                    fontSize: t20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (10 * s).clamp(8.0, 12.0),
                                  vertical: (6 * s).clamp(5.0, 8.0),
                                ),
                                decoration: BoxDecoration(
                                  color: item.isInstallment
                                      ? Colors.orange.shade100
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.isInstallment ? "Installment" : "Non-installment",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: (12 * s).clamp(11.0, 13.0),
                                    color: item.isInstallment
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: (12 * s).clamp(10.0, 14.0)),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(pad16, 0, pad16, pad16),
                            children: [
                              Container(
                                padding: EdgeInsets.all(pad14),
                                decoration: BoxDecoration(
                                  color: _cardBg,
                                  borderRadius: BorderRadius.circular(r16),
                                  border: Border.all(color: _cardBorder.withOpacity(0.8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _rowLabelValue(
                                      "Total Amount",
                                      "₱${currencyFormat.format(total)}",
                                      valueStyle: TextStyle(
                                        fontSize: (14.5 * s).clamp(13.0, 16.0),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: (8 * s).clamp(6.0, 10.0)),
                                    _rowLabelValue(
                                      "Paid so far",
                                      "₱${currencyFormat.format(paidSoFar)}",
                                      valueStyle: TextStyle(
                                        fontSize: (14.5 * s).clamp(13.0, 16.0),
                                        fontWeight: FontWeight.w900,
                                        color: paidSoFar <= 0
                                            ? _titleColor
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                    SizedBox(height: (8 * s).clamp(6.0, 10.0)),
                                    _rowLabelValue(
                                      "Remaining",
                                      "₱${currencyFormat.format(remaining)}",
                                      valueStyle: TextStyle(
                                        fontSize: (15 * s).clamp(13.5, 16.5),
                                        fontWeight: FontWeight.w900,
                                        color: remaining <= 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                    SizedBox(height: (10 * s).clamp(8.0, 12.0)),
                                    if (item.createdAtDate != null)
                                      Text(
                                        "Recorded On: ${DateFormat('MMM dd, yyyy').format(item.createdAtDate!)}",
                                        style: TextStyle(
                                          fontSize: (13 * s).clamp(11.5, 14.0),
                                          color: _subtitleColor,
                                        ),
                                      ),
                                    if (!isFullyPaid && displayNextDue != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: (4 * s).clamp(3.0, 6.0)),
                                        child: Text(
                                          "Next Due: ${DateFormat('MMM dd, yyyy').format(displayNextDue)}",
                                          style: TextStyle(
                                            fontSize: (13 * s).clamp(11.5, 14.0),
                                            color: _subtitleColor,
                                          ),
                                        ),
                                      ),
                                    if (item.isInstallment && (item.planMonthly ?? 0) > 0)
                                      Padding(
                                        padding: EdgeInsets.only(top: (4 * s).clamp(3.0, 6.0)),
                                        child: Text(
                                          "Monthly: ₱${currencyFormat.format(item.planMonthly)}",
                                          style: TextStyle(
                                            fontSize: (13 * s).clamp(11.5, 14.0),
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: (14 * s).clamp(12.0, 18.0)),
                              Text(
                                "Payment Trace",
                                style: TextStyle(
                                  fontSize: t15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: (8 * s).clamp(6.0, 10.0)),
                              if (paymentHistory.isEmpty)
                                Container(
                                  padding: EdgeInsets.all(pad14),
                                  decoration: BoxDecoration(
                                    color: _cardBg,
                                    borderRadius: BorderRadius.circular(r16),
                                    border: Border.all(color: _cardBorder.withOpacity(0.8)),
                                  ),
                                  child: const Text(
                                    "No payments recorded yet.",
                                    style: TextStyle(color: _subtitleColor),
                                  ),
                                ),
                              ...paymentHistory.map((payment) {
                                final paidLabel =
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(payment.paidAt);

                                final note = (payment.note?.isNotEmpty == true)
                                    ? payment.note!
                                    : 'Payment';

                                final leftLabel =
                                    '$note ₱${currencyFormat.format(payment.amount)}';

                                return Container(
                                  margin: EdgeInsets.only(bottom: (8 * s).clamp(6.0, 10.0)),
                                  padding: EdgeInsets.all((12 * s).clamp(10.0, 14.0)),
                                  decoration: BoxDecoration(
                                    color: _cardBg,
                                    borderRadius: BorderRadius.circular((14 * s).clamp(12.0, 16.0)),
                                    border: Border.all(color: _cardBorder.withOpacity(0.8)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          leftLabel,
                                          style: TextStyle(
                                            fontSize: (13 * s).clamp(12.0, 14.0),
                                            fontWeight: FontWeight.w600,
                                            color: _titleColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: (10 * s).clamp(8.0, 12.0)),
                                      Text(
                                        paidLabel,
                                        style: TextStyle(
                                          fontSize: (12 * s).clamp(11.0, 13.0),
                                          color: _subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        if (!isFullyPaid)
                          Container(
                            padding: EdgeInsets.only(
                              left: pad16,
                              right: pad16,
                              top: (12 * s).clamp(10.0, 14.0),
                              bottom: (12 * s).clamp(10.0, 14.0) +
                                  MediaQuery.of(context).viewPadding.bottom,
                            ),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular((16 * s).clamp(14.0, 20.0)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      double? amount = await promptPartialAmount(
                                        remaining,
                                        suggested: item.planMonthly,
                                      );
                                      if (amount != null) {
                                        await applyPayment(item, amount);
                                        if (context.mounted) Navigator.pop(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      padding: EdgeInsets.symmetric(
                                        vertical: (14 * s).clamp(12.0, 16.0),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular((14 * s).clamp(12.0, 16.0)),
                                      ),
                                    ),
                                    child: const Text(
                                      "Partial Pay",
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                SizedBox(width: (12 * s).clamp(10.0, 14.0)),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Confirm Full Payment"),
                                          content: Text(
                                            "Are you sure you want to record the full payment of ₱${currencyFormat.format(remaining)}?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Confirm"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await applyPayment(
                                          item,
                                          remaining,
                                          isFullPay: true,
                                        );
                                        if (context.mounted) Navigator.pop(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(
                                        vertical: (14 * s).clamp(12.0, 16.0),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular((14 * s).clamp(12.0, 16.0)),
                                      ),
                                    ),
                                    child: const Text(
                                      "Full Pay",
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _rowLabelValue(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _subtitleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ RESPONSIVE UI BUILD (NO LOGIC CHANGES)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final s = (w / 390).clamp(0.90, 1.20);

        final pad16 = (16 * s).clamp(12.0, 20.0);
        final gap16 = (16 * s).clamp(12.0, 18.0);
        final gap12 = (12 * s).clamp(10.0, 14.0);

        final fabH = (56 * s).clamp(50.0, 62.0);
        final fabFs = (16 * s).clamp(14.0, 17.0);
        final fabR = (18 * s).clamp(16.0, 22.0);

        return Scaffold(
          backgroundColor: _pageBg,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: _pageBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Image.asset(
                'lib/assets/arrowleft.png',
                width: (22 * s).clamp(20.0, 26.0),
                height: (22 * s).clamp(20.0, 26.0),
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
            title: Text(
              'Owner Utang',
              style: TextStyle(
                color: _titleColor,
                fontWeight: FontWeight.w900,
                fontSize: (20 * s).clamp(18.0, 24.0),
              ),
            ),
            centerTitle: true,
          ),

          body: Stack(
            children: [
              const DashboardBackground(),
              Column(
                children: [
                  SizedBox(height: gap16),
                  _buildFilterButtons(s: s, padH: pad16),
                  SizedBox(height: gap12),
                  Expanded(
                    child: _buildOwnerPage(
                      s: s,
                      padH: pad16,
                      bottomInset: bottomInset,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    pad16,
                    gap12,
                    pad16,
                    gap12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: fabH,
                    child: ElevatedButton(
                      onPressed: () async {
                        await GoRouter.of(context).push('/add_utang');
                        _refreshData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentBlue,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(fabR),
                        ),
                      ),
                      child: Text(
                        "Dugang Bayronon",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: fabFs,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const PrimaryFooterNav(
                  selectedTab: PrimaryFooterTab.ownerUtang,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOwnerPage({
    required double s,
    required double padH,
    required double bottomInset,
  }) {
    if (filteredOwnerPayables.isEmpty) {
      return _emptyState(s: s);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        padH,
        (8 * s).clamp(6.0, 10.0),
        padH,
        (95 * s).clamp(88.0, 120.0),
      ),
      itemCount: filteredOwnerPayables.length,
      itemBuilder: (context, index) {
        return _buildOwnerPayableCard(filteredOwnerPayables[index], s: s);
      },
    );
  }

  Widget _emptyState({required double s}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all((24 * s).clamp(18.0, 28.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Walay bayranan",
              style: TextStyle(
                fontSize: (18 * s).clamp(16.0, 20.0),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Segmented filter (responsive)
  Widget _buildFilterButtons({required double s, required double padH}) {
    final barH = (48 * s).clamp(44.0, 54.0);
    final innerPad = (4 * s).clamp(4.0, 6.0);
    final textFs = (14.5 * s).clamp(13.0, 16.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final segmentW = (w - (innerPad * 2)) / 3;
          final left = innerPad + (segmentW * selectedFilter);

          return Container(
            height: barH,
            padding: EdgeInsets.all(innerPad),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _cardBorder),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: segmentW,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _accentBlue,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8EA1D1).withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _slideSegButton(0, "Tanan", textFs: textFs)),
                    Expanded(child: _slideSegButton(1, "Overdue", textFs: textFs)),
                    Expanded(child: _slideSegButton(2, "Paid", textFs: textFs)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _slideSegButton(int index, String text, {required double textFs}) {
    final active = selectedFilter == index;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => applyOwnerFilter(index),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          style: TextStyle(
            color: active ? Colors.white : _titleColor,
            fontSize: textFs,
            fontWeight: FontWeight.w900,
          ),
          child: Text(text),
        ),
      ),
    );
  }

  // ✅ Card (responsive sizes only)
  Widget _buildOwnerPayableCard(Payable item, {required double s}) {
    final total = item.amount.toDouble();
    final remaining = (item.remainingAmount ?? item.amount)
        .clamp(0.0, item.amount.toDouble())
        .toDouble();
    final paidSoFar = (total - remaining).clamp(0.0, total);

    final isFullyPaid = item.isPaid || remaining <= 0;

    String status = isFullyPaid ? "Paid" : "";
    final nextDateStr = item.isInstallment ? item.nextDueDate : item.dueDate;

    DateTime? due;
    if (nextDateStr != null) due = DateTime.tryParse(nextDateStr);

    if (!isFullyPaid && due != null) {
      final daysLeft = _dateOnly(due).difference(_dateOnly(DateTime.now())).inDays;
      if (daysLeft < 0)
        status = "Overdue";
      else if (daysLeft <= 7) status = "Due Soon";
    }

    final double monthly = item.isInstallment ? (item.planMonthly ?? 0.0) : 0.0;

    final pad14 = (14 * s).clamp(12.0, 18.0);
    final r16 = (16 * s).clamp(14.0, 20.0);
    final titleFs = (16.5 * s).clamp(14.5, 18.5);

    return GestureDetector(
      onTap: () => showOwnerUtangModal(item),
      child: Container(
        margin: EdgeInsets.only(bottom: (10 * s).clamp(8.0, 12.0)),
        padding: EdgeInsets.all(pad14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(r16),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF93A4CF).withOpacity(0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFs,
                      fontWeight: FontWeight.w900,
                      color: _titleColor,
                    ),
                  ),
                ),
                if (status.isNotEmpty) _statusPill(status, s: s),
              ],
            ),
            SizedBox(height: (10 * s).clamp(8.0, 12.0)),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    label: item.isInstallment ? "Binulan" : "Nabayran",
                    value: item.isInstallment
                        ? "₱${currencyFormat.format(monthly)}"
                        : "₱${currencyFormat.format(paidSoFar)}",
                    valueColor: item.isInstallment
                        ? Colors.orange.shade900
                        : (paidSoFar <= 0
                            ? _titleColor
                            : Colors.green.shade700),
                    s: s,
                  ),
                ),
                SizedBox(width: (10 * s).clamp(8.0, 12.0)),
                Expanded(
                  child: _miniStat(
                    label: "Balayran",
                    value: "₱${currencyFormat.format(remaining)}",
                    valueColor:
                        isFullyPaid ? Colors.green.shade700 : Colors.red.shade700,
                    s: s,
                  ),
                ),
              ],
            ),
            SizedBox(height: (10 * s).clamp(8.0, 12.0)),
            if (!isFullyPaid && due != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: (18 * s).clamp(16.0, 20.0),
                    color: _subtitleColor,
                  ),
                  SizedBox(width: (8 * s).clamp(6.0, 10.0)),
                  Expanded(
                    child: Text(
                      "Next Due: ${DateFormat('MMM dd, yyyy').format(due)}",
                      style: TextStyle(
                        fontSize: (13 * s).clamp(12.0, 14.5),
                        fontWeight: FontWeight.w700,
                        color: _subtitleColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _subtitleColor.withOpacity(0.7),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right,
                  color: _subtitleColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    Color? valueColor,
    required double s,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (12 * s).clamp(10.0, 14.0),
        vertical: (10 * s).clamp(9.0, 12.0),
      ),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular((14 * s).clamp(12.0, 16.0)),
        border: Border.all(color: const Color(0xFFDCE5F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBAC7E6).withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: (12 * s).clamp(11.0, 13.0),
              fontWeight: FontWeight.w700,
              color: _subtitleColor,
            ),
          ),
          SizedBox(height: (6 * s).clamp(4.0, 8.0)),
          Text(
            value,
            style: TextStyle(
              fontSize: (14.5 * s).clamp(13.0, 16.0),
              fontWeight: FontWeight.w900,
              color: valueColor ?? _titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status, {required double s}) {
    final bg = _getStatusColor(status);
    final fg = _getStatusTextColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (10 * s).clamp(8.0, 12.0),
        vertical: (6 * s).clamp(5.0, 8.0),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: (12 * s).clamp(11.0, 13.0),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Overdue':
        return const Color(0xFFFFEBEE);
      case 'Due Soon':
        return const Color(0xFFFFF3E0);
      case 'Paid':
        return const Color(0xFFE8F5E9);
      default:
        return _cardBorder.withOpacity(0.55);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Overdue':
        return const Color(0xFFC62828);
      case 'Due Soon':
        return const Color(0xFFEF6C00);
      case 'Paid':
        return const Color(0xFF2E7D32);
      default:
        return _subtitleColor;
    }
  }
}
