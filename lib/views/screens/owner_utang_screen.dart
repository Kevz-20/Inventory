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
import '../widgets/header.dart';

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

    double parseAmount(String v) => double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    String money(double v) => "₱${currencyFormat.format(v)}";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final current = value ?? 0.0;
            final hasSuggested = (suggested != null && suggested > 0);
            final isValid = current > 0 && current <= remaining && remaining > 0;
            final overLimit = current > remaining && remaining > 0;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: const Text(
                "Partial Payment",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Remaining: ${money(remaining)}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasSuggested) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Monthly: ${money(suggested)}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final fill = (suggested > remaining) ? remaining : suggested;
                            controller.text = currencyFormat.format(fill).replaceAll('.00', '');
                            value = fill;
                            setState(() {});
                          },
                          child: const Text("Use"),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      prefixText: "₱ ",
                      hintText: "Enter amount",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade500),
                      ),
                    ),
                    onChanged: (v) => setState(() {
                      value = parseAmount(v);
                    }),
                  ),
                  if (overLimit)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Too high (exceeds remaining).",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
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
      final cashOnHand = (cashRes.first['total_cash'] as num?)?.toDouble() ?? 0.0;

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
            DateTime.tryParse(item.nextDueDate ?? item.dueDate ?? '') ?? DateTime.now();
        final nextDue = addMonths(baseDate, 1);
        updateMap['next_due_date'] = DateFormat('yyyy-MM-dd').format(nextDue);
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
      final msg = isInsufficientCash ? 'Insufficient cash on hand' : 'Failed to process payment';

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
  // - Card shows: (Monthly or Paid so far) + Remaining + Next Due
  // - Bottomsheet shows: Total + Paid so far + Remaining + Next Due + Trace
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

        // ✅ show CURRENT Next Due only (no +1 month preview)
        final nextDateStr = item.isInstallment ? item.nextDueDate : item.dueDate;
        final displayNextDue = (nextDateStr != null && nextDateStr.isNotEmpty)
            ? DateTime.tryParse(nextDateStr)
            : null;

        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.58,
            minChildSize: 0.48,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.item,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                fontSize: 12,
                                color: item.isInstallment
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          // ✅ SUMMARY CARD: Total / Paid / Remaining + Next Due
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                                  valueStyle: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _rowLabelValue(
                                  "Paid so far",
                                  "₱${currencyFormat.format(paidSoFar)}",
                                  valueStyle: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: paidSoFar <= 0
                                        ? Colors.black87
                                        : Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _rowLabelValue(
                                  "Remaining",
                                  "₱${currencyFormat.format(remaining)}",
                                  valueStyle: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: remaining <= 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (item.createdAtDate != null)
                                  Text(
                                    "Recorded On: ${DateFormat('MMM dd, yyyy').format(item.createdAtDate!)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                if (displayNextDue != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Next Due: ${DateFormat('MMM dd, yyyy').format(displayNextDue)}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                if (item.isInstallment && (item.planMonthly ?? 0) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Monthly: ₱${currencyFormat.format(item.planMonthly)}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            "Payment Trace",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (paymentHistory.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                "No payments recorded yet.",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),

                          ...paymentHistory.map((payment) {
                            final paidLabel = DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(payment.paidAt);

                            final note = (payment.note?.isNotEmpty == true)
                                ? payment.note!
                                : 'Payment';

                            final leftLabel =
                                '$note ₱${currencyFormat.format(payment.amount)}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      leftLabel,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    paidLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
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
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, -6),
                            ),
                          ],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
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
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  "Partial Pay",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
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
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
  }

  Widget _rowLabelValue(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
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
  // ✅ UPDATED UI BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Owner Utang',
        showBackButton: true,
      ),

      // ✅ Full-width Add button (same functionality)
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              await GoRouter.of(context).push('/add_utang');
              _refreshData();
            },
            icon: const SizedBox.shrink(),
            label: const Text(
              "Add Payable",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildFilterButtons(),
          const SizedBox(height: 12),
          Expanded(child: _buildOwnerPage()),
        ],
      ),
    );
  }

  Widget _buildOwnerPage() {
    if (filteredOwnerPayables.isEmpty) {
      return _emptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 95),
      itemCount: filteredOwnerPayables.length,
      itemBuilder: (context, index) {
        return _buildOwnerPayableCard(filteredOwnerPayables[index]);
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Walay bayranan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              "Add a payable para ma-track nimo ang due dates ug payments.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Segmented filter
  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final segmentW = (w - 8) / 3; // container padding = 4 left + 4 right
          final left = 4 + (segmentW * selectedFilter);

          return Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300.withOpacity(0.35),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.grey.shade300.withOpacity(0.6)),
            ),
            child: Stack(
              children: [
                // ✅ Sliding active pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: segmentW,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ Buttons layer
                Row(
                  children: [
                    Expanded(child: _slideSegButton(0, "Tanan")),
                    Expanded(child: _slideSegButton(1, "Overdue")),
                    Expanded(child: _slideSegButton(2, "Paid")),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _slideSegButton(int index, String text) {
    final active = selectedFilter == index;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => applyOwnerFilter(index),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
          child: Text(text),
        ),
      ),
    );
  }


  // ✅ Card: show (Monthly or Paid so far) + Remaining + Next Due
  Widget _buildOwnerPayableCard(Payable item) {
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
      if (daysLeft < 0) status = "Overdue";
      else if (daysLeft <= 7) status = "Due Soon";
    }

    final dueText =
        (due != null) ? DateFormat('MMM dd, yyyy').format(due) : "No due date";

    final double monthly = item.isInstallment ? (item.planMonthly ?? 0.0) : 0.0;

    return GestureDetector(
      onTap: () => showOwnerUtangModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
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
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (status.isNotEmpty) _statusPill(status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    label: item.isInstallment ? "Monthly" : "Paid so far",
                    value: item.isInstallment
                        ? "₱${currencyFormat.format(monthly)}"
                        : "₱${currencyFormat.format(paidSoFar)}",
                    valueColor: item.isInstallment
                        ? Colors.orange.shade900
                        : (paidSoFar <= 0 ? Colors.black87 : Colors.green.shade700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniStat(
                    label: "Remaining",
                    value: "₱${currencyFormat.format(remaining)}",
                    valueColor: isFullyPaid
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: Colors.black.withOpacity(0.55)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Next Due: $dueText",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.60),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.black.withOpacity(0.35)),
              ],
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final bg = _getStatusColor(status);
    final fg = _getStatusTextColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withOpacity(0.7)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12,
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
        return Colors.grey.shade200;
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
        return Colors.black54;
    }
  }
}