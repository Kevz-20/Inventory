import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/payable_model.dart';
import '../../models/utang_customer_model.dart';
import '../../repositories/capital_management_repository.dart';
import '../../repositories/payable_repository.dart';
import '../widgets/header.dart';
import '../../services/db_service.dart';

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

// ============================================================
// MAIN SCREEN
// ============================================================

class UtangScreen extends StatefulWidget {
  const UtangScreen({super.key});

  @override
  State<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends State<UtangScreen> with WidgetsBindingObserver {
  final currencyFormat = NumberFormat("#,##0.00", "en_PH");
  final searchController = TextEditingController();

  int selectedTab = 0;
  int selectedFilter = 0;

  List<UtangCustomer> utangan = [];
  List<UtangCustomer> filteredUtangan = [];

  List<Payable> ownerPayables = [];
  List<Payable> filteredOwnerPayables = [];

  // ✅ FIX: prevent double refresh from didChangeDependencies
  bool _loadedOnce = false;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  int _daysUntil(DateTime dueDate) {
    final today = _dateOnly(DateTime.now());
    final due = _dateOnly(dueDate);
    return due.difference(today).inDays;
  }

  bool _isOverdue(DateTime dueDate) => _daysUntil(dueDate) < 0;

  bool _isPastDueDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return false;
    final due = DateTime.tryParse(isoDate);
    if (due == null) return false;
    return _dateOnly(due).isBefore(_dateOnly(DateTime.now()));
  }

  String _buildDueStatusText(DateTime dueDate) {
    final daysLeft = _daysUntil(dueDate);
    final formattedDueDate = DateFormat('MMM dd, yyyy').format(dueDate);

    if (daysLeft < 0) return "Overdue • Due: $formattedDueDate";
    if (daysLeft == 0) return "Due today • Due: $formattedDueDate";
    return "Due: $formattedDueDate • $daysLeft day${daysLeft != 1 ? 's' : ''} left";
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ FIX: do NOT call _refreshData twice
    if (_loadedOnce) return;
    _loadedOnce = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  // ============================================================
  // DATA MANAGEMENT
  // ============================================================

  Future<void> _refreshData() async {
    await fetchUtangan();
    await fetchOwnerPayables();
  }

  Future<void> fetchUtangan() async {
    final db = await DBService.instance.database;

    const sql = '''
      SELECT
        c.id,
        c.first_name,
        c.middle_name,
        c.last_name,
        c.municipality,
        c.barangay,
        c.phone_number,
        MAX(0, COALESCE(sc.total_amount, 0) - COALESCE(cp.total_paid, 0)) AS total_amount,
        sc.min_due_date AS due_date
      FROM customer c
      LEFT JOIN (
        SELECT
          customer_id,
          SUM(amount) AS total_amount,
          MIN(due_date) AS min_due_date
        FROM sales_credit
        GROUP BY customer_id
      ) sc ON sc.customer_id = c.id
      LEFT JOIN (
        SELECT
          customer_id,
          SUM(amount) AS total_paid
        FROM customer_payment
        GROUP BY customer_id
      ) cp ON cp.customer_id = c.id
      WHERE sc.customer_id IS NOT NULL
      ORDER BY total_amount DESC
    ''';

    try {
      debugPrint('fetchUtangan SQL:\n$sql');
      final result = await db.rawQuery(sql);

      if (!mounted) return;
      setState(() {
        utangan = result.map((e) => UtangCustomer.fromMap(e)).toList();
        filteredUtangan = List.from(utangan);
      });
    } catch (e) {
      debugPrint('fetchUtangan ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('fetchUtangan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchOwnerPayables() async {
    final payables = await PayableRepository().getAllPayables();

    // ✅ FIX: avoid setState if screen is already disposed
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

  void filterUtangan(String query) {
    if (query.isEmpty) {
      filteredUtangan = List.from(utangan);
    } else {
      filteredUtangan = utangan
          .where((u) => u.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void applyOwnerFilter(int filterIndex) {
    selectedFilter = filterIndex;

    switch (filterIndex) {
      case 0:
        filteredOwnerPayables = List.from(ownerPayables);
        break;
      case 1:
        filteredOwnerPayables = ownerPayables
            .where((p) =>
                !p.isPaid &&
                _isPastDueDate(p.isInstallment ? p.nextDueDate : p.dueDate))
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

  Future<double?> promptPartialAmount(double remaining, {double? suggested}) async {
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

  double _parseAmount(String v) =>
      double.tryParse(v.replaceAll(',', '')) ?? 0.0;

  String _money(double v) => "₱${currencyFormat.format(v)}";

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                // Remaining (important)
                Text(
                  "Remaining: ${_money(remaining)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // Monthly suggestion (only if installment)
                if (hasSuggested) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Monthly: ${_money(suggested!)}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final fill =
                              (suggested! > remaining) ? remaining : suggested!;
                          controller.text =
                              currencyFormat.format(fill).replaceAll('.00', '');
                          value = fill;
                          setState(() {});
                        },
                        child: const Text("Use"),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Amount input (big + clear)
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    prefixText: "₱ ",
                    hintText: "Enter amount",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    value = _parseAmount(v);
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
                        value = _parseAmount(controller.text);
                        didConfirm = true;
                        Navigator.pop(dialogContext);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        'note': 'Owner payment',
        'created_at': DateTime.now().toIso8601String(),
      });

      final newRemaining = (remaining - payAmount).clamp(0.0, remaining);
      final updateMap = <String, dynamic>{
        'remaining_amount': newRemaining,
        'is_paid': newRemaining <= 0 ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

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
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ============================================================
  // UI - MODALS
  // ============================================================

  Future<void> showOwnerUtangModal(Payable item) async {
  final paymentHistory = await fetchOwnerPaymentHistory(item.id);
  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // ✅ makes rounded corners look clean
    builder: (context) {
      final double remaining = (item.remainingAmount ?? item.amount)
          .clamp(0.0, item.amount.toDouble())
          .toDouble();

      final bool isFullyPaid =
          item.isPaid || ((item.remainingAmount ?? item.amount) <= 0);

      final nextDateStr = item.isInstallment ? item.nextDueDate : item.dueDate;

      DateTime? displayNextDue;
      String nextDueLabel = "Next Due";

      if (item.isInstallment) {
        final baseDate = DateTime.tryParse(nextDateStr ?? '');
        if (baseDate != null) {
          displayNextDue = addMonths(baseDate, 1);
          nextDueLabel = "Next Due (after payment)";
        }
      } else if (nextDateStr != null) {
        displayNextDue = DateTime.tryParse(nextDateStr);
      }

      return SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55, // ✅ better default height
          minChildSize: 0.45,
          maxChildSize: 0.92, // ✅ allows scrolling taller for long history
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  // ✅ Drag handle
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

                  // ✅ Title
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
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

                  // ✅ Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        // ✅ Summary card
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
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _rowLabelValue(
                                "Amount",
                                "₱${currencyFormat.format(item.amount)}",
                                valueStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
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
                                    "$nextDueLabel: ${DateFormat('MMM dd, yyyy').format(displayNextDue)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ✅ Payment trace section
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

                          final leftLabel = !item.isInstallment
                              ? 'Full payment ₱${currencyFormat.format(payment.amount)}'
                              : (payment.note?.isNotEmpty == true
                                  ? payment.note!
                                  : 'Owner payment');

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

                  // ✅ Bottom action bar (buttons feel “attached” + not floating awkwardly)
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
                          )
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Partial Pay",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Full Pay",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
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

// ✅ small UI helper (does NOT affect logic)
Widget _rowLabelValue(
  String label,
  String value, {
  TextStyle? valueStyle,
}) {
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
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
      ),
    ],
  );
}

  // ============================================================
  // UI - BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Utang', showBackButton: true),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildTabToggle(),
          const SizedBox(height: 15),
          Expanded(
            child: selectedTab == 0 ? _buildCustomerPage() : _buildOwnerPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: selectedTab == 0 ? 0 : MediaQuery.of(context).size.width / 2 - 30,
              right: selectedTab == 0 ? MediaQuery.of(context).size.width / 2 - 30 : 0,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4B3E),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 0),
                    child: Center(
                      child: Text(
                        "Customer Utang",
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedTab == 0 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 1),
                    child: Center(
                      child: Text(
                        "Owner Utang",
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedTab == 1 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI - CUSTOMER PAGE
  // ============================================================

  Widget _buildCustomerPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Pangalan sa Utangan",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: filterUtangan,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: utangan.isEmpty
              ? const Center(
                  child: Text(
                    "Walay utangan",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredUtangan.length,
                  itemBuilder: (context, index) {
                    final item = filteredUtangan[index];
                    return _buildCustomerCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(UtangCustomer item) {
    return GestureDetector(
      onTap: () async {
        await GoRouter.of(context).push('/utang_summary', extra: item);
        _refreshData();
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₱${currencyFormat.format(item.totalAmount)}",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (item.totalAmount <= 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Paid",
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (item.municipality != null && item.municipality!.isNotEmpty)
                Text(item.municipality!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 2),
              if (item.barangay != null && item.barangay!.isNotEmpty)
                Text("Barangay ${item.barangay!}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                    Text(item.phoneNumber!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  if (item.dueDate != null && item.totalAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isOverdue(item.dueDate!) ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _buildDueStatusText(item.dueDate!),
                        style: TextStyle(
                          color: _isOverdue(item.dueDate!) ? Colors.red : Colors.green[800],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UI - OWNER PAGE
  // ============================================================

  Widget _buildOwnerPage() {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 20),
            _buildFilterButtons(),
            const SizedBox(height: 15),
            Expanded(
              child: filteredOwnerPayables.isEmpty
                  ? const Center(
                      child: Text(
                        "Walay bayranan",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredOwnerPayables.length,
                      itemBuilder: (context, index) {
                        return _buildOwnerPayableCard(filteredOwnerPayables[index]);
                      },
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
        _buildAddButton(bottomPadding),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFilterButton(0, "Tanan"),
          _buildFilterButton(1, "Overdue"),
          _buildFilterButton(2, "Paid"),
        ],
      ),
    );
  }

  Widget _buildFilterButton(int index, String text) {
    bool active = selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => applyOwnerFilter(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerPayableCard(Payable item) {
    String? nextDueDisplay;
    final isFullyPaid = item.isPaid || ((item.remainingAmount ?? item.amount) <= 0);
    String status = isFullyPaid ? "Paid" : "";
    final nextDateStr = item.isInstallment ? item.nextDueDate : item.dueDate;

    if (nextDateStr != null) {
      final due = DateTime.tryParse(nextDateStr);
      if (due != null) {
        nextDueDisplay = "Next Due: ${DateFormat('MMM dd, yyyy').format(due)}";

        if (!isFullyPaid) {
          final daysLeft = _dateOnly(due).difference(_dateOnly(DateTime.now())).inDays;
          if (daysLeft < 0) {
            status = "Overdue";
          } else if (daysLeft <= 7) {
            status = "Due Soon";
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => showOwnerUtangModal(item),
        child: Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.item,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (nextDueDisplay != null)
                      Text(
                        nextDueDisplay,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              if (status.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusTextColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(double bottomPadding) {
    return Positioned(
      bottom: 20 + bottomPadding,
      left: 20,
      right: 20,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () async {
            await GoRouter.of(context).push('/add_utang');
            _refreshData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          child: const Text(
            "Pagdugang og Bayronon",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Overdue':
        return const Color(0xFFFFEBEE);
      case 'Due Soon':
         return const Color(0xFFFFF3E0); // softer orange background
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