import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../models/utang_customer_model.dart';
import '../../repositories/capital_management_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../services/db_service.dart';
import '../widgets/header.dart';

// ================================
// MODEL FOR INDIVIDUAL UTANG ITEMS
// ================================
class UtangItem {
  final int salesCreditId;
  final String itemName;
  final double amount;
  final int quantity;
  final DateTime creditDate;
  final DateTime? dueDate;

  UtangItem({
    required this.salesCreditId,
    required this.itemName,
    required this.amount,
    required this.quantity,
    required this.creditDate,
    this.dueDate,
  });

  factory UtangItem.fromMap(Map<String, dynamic> map) {
    return UtangItem(
      salesCreditId: map['sales_credit_id'],
      itemName: map['item_name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      creditDate: DateTime.tryParse(map['credit_date'] ?? '') ?? DateTime.now(),
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date']) : null,
    );
  }
}

// ================================
// MODEL FOR CUSTOMER PAYMENTS
// ================================
class CustomerPayment {
  final int id;
  final double amount;
  final DateTime paidAt;
  final int? creditDateId;

  CustomerPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.creditDateId,
  });

  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id'],
      amount: (map['amount'] ?? 0).toDouble(),
      paidAt: DateTime.tryParse(map['paid_at'] ?? '') ?? DateTime.now(),
      creditDateId: map['credit_date_id'],
    );
  }
}

// ================================
// UTANG SUMMARY PAGE
// ================================
class UtangSummaryPage extends StatefulWidget {
  final UtangCustomer customer;

  const UtangSummaryPage({super.key, required this.customer});

  @override
  State<UtangSummaryPage> createState() => _UtangSummaryPageState();
}

class _UtangSummaryPageState extends State<UtangSummaryPage> {
  static const Color _pageBg = Color(0xFFF2F7F5);
  static const Color _cardBg = Color(0xFFEFF8F4);
  static const Color _cardBorder = Color(0xFFBFDCD4);
  static const Color _titleColor = Color(0xFF0B3D35);
  static const Color _subtitleColor = Color(0xFF2F5C54);

  List<UtangItem> customerItems = [];
  List<CustomerPayment> customerPayments = [];
  final currencyFormat = NumberFormat("#,##0.00", "en_PH");
  bool isLoading = true;
  double? creditLimit;
  double? availableCredit;

  // ✅ NEW: history checker to prevent showing "Paid" for brand-new customer
  bool get _hasUtangHistory => customerItems.isNotEmpty || customerPayments.isNotEmpty;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  int _daysUntil(DateTime dueDate) {
    final today = _dateOnly(DateTime.now());
    final due = _dateOnly(dueDate);
    return due.difference(today).inDays;
  }

  bool _isOverdue(DateTime dueDate) => _daysUntil(dueDate) < 0;

  @override
  void initState() {
    super.initState();
    fetchCustomerData();
  }

  // ================================
  // FETCH ITEMS AND PAYMENTS FROM DB
  // ================================
  Future<void> fetchCustomerData() async {
    setState(() => isLoading = true);
    final db = await DBService.instance.database;

    // Fetch customer credit info
    final customerResult = await db.query(
      'customer',
      columns: ['credit_limit', 'available_credit'],
      where: 'id = ?',
      whereArgs: [widget.customer.id],
      limit: 1,
    );

    // Fetch items
    final itemsResult = await db.rawQuery(
      '''
      SELECT
        sc.id AS sales_credit_id,
        p.name AS item_name,
        sc.amount,
        sc.quantity,
        sc.credit_date,
        sc.due_date
      FROM sales_credit sc
      JOIN product p ON sc.product_id = p.id
      WHERE sc.customer_id = ?
      ORDER BY sc.credit_date ASC
      ''',
      [widget.customer.id],
    );

    // Fetch customer payments
    final paymentsResult = await db.query(
      'customer_payment',
      where: 'customer_id = ?',
      whereArgs: [widget.customer.id],
      orderBy: 'paid_at ASC',
    );

    setState(() {
      if (customerResult.isNotEmpty) {
        creditLimit = (customerResult.first['credit_limit'] as num?)?.toDouble();
        availableCredit = (customerResult.first['available_credit'] as num?)?.toDouble();
      }
      customerItems = itemsResult.map((e) => UtangItem.fromMap(e)).toList();
      customerPayments = paymentsResult.map((e) => CustomerPayment.fromMap(e)).toList();
      isLoading = false;
    });
  }

  // ================================
  // ADD CUSTOMER-LEVEL PAYMENT
  // ================================
  Future<void> addPartialPayment() async {
    if (totalUtang <= 0) return;

    final TextEditingController paymentController = TextEditingController();
    double enteredAmount = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final remainingBalance = totalUtang;
            final isOverPaying = enteredAmount > remainingBalance;
            final isFullPay = enteredAmount == remainingBalance;

            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Add Payment",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Remaining balance: ₱${currencyFormat.format(remainingBalance)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paymentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Enter payment amount",
                        prefixText: "₱",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          enteredAmount = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isOverPaying)
                      const Text(
                        "Amount exceeds remaining balance",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    if (isFullPay && enteredAmount > 0)
                      const Text(
                        "This will fully pay the utang.",
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (enteredAmount <= 0 || isOverPaying)
                                ? null
                                : () async {
                                    final db = await DBService.instance.database;
                                    final prefs = await SharedPreferences.getInstance();
                                    final mobileNumber = prefs.getString('mobileNumber') ?? '';
                                    final accountRows = await db.query(
                                      'account',
                                      columns: ['id', 'first_name', 'middle_name', 'last_name'],
                                      where: 'mobile_number = ?',
                                      whereArgs: [mobileNumber],
                                      limit: 1,
                                    );
                                    final account = accountRows.isNotEmpty
                                        ? accountRows.first
                                        : <String, Object?>{};

                                    await db.insert('customer_payment', {
                                      'customer_id': widget.customer.id,
                                      'account_id': account['id'],
                                      'amount': enteredAmount,
                                      'paid_at': DateTime.now().toIso8601String(),
                                      'created_by_first_name': account['first_name'] ?? '',
                                      'created_by_middle_name': account['middle_name'] ?? '',
                                      'created_by_last_name': account['last_name'] ?? '',
                                    });

                                    final customerRepo = CustomerRepository(db);
                                    final currentCredit =
                                        await customerRepo.getAvailableCredit(widget.customer.id);

                                    await customerRepo.updateCustomer(widget.customer.id, {
                                      'available_credit': currentCredit + enteredAmount,
                                      'updated_at': DateTime.now().toIso8601String(),
                                    });

                                    final capitalRepo = CapitalManagementRepository(db);
                                    await capitalRepo.addCustomerPaymentCash(enteredAmount);

                                    if (!mounted) return;
                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context);
                                    await fetchCustomerData();

                                    ScaffoldMessenger.of(
                                      // ignore: use_build_context_synchronously
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('Successful payment'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFullPay ? Colors.green : Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isFullPay ? "Full Pay" : "Partial Pay"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================
  // ADJUST CREDIT LIMIT (INCREASE)
  // ================================
  Future<void> adjustCreditLimit() async {
    final TextEditingController customController = TextEditingController();
    double customAmount = 0;
    int? selectedPreset;

    const presets = [100, 200, 500, 1000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedAmount = selectedPreset != null ? presets[selectedPreset!] : customAmount;
            final isValid = selectedAmount > 0;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: SizedBox(width: 40, child: Divider(thickness: 4)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Increase Credit Limit",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Choose an amount to add:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(presets.length, (index) {
                        final value = presets[index];
                        final isSelected = selectedPreset == index;

                        return ChoiceChip(
                          label: Text("₱$value"),
                          selected: isSelected,
                          onSelected: (_) {
                            setModalState(() {
                              selectedPreset = index;
                              customAmount = presets[index].toDouble();
                              customController.text = presets[index].toString();
                            });
                          },
                          selectedColor: Colors.green[100],
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Custom amount",
                        prefixText: "₱",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          customAmount = double.tryParse(value) ?? 0;
                          selectedPreset = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !isValid
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                    final amountToAdd = selectedAmount;

                                    try {
                                      final db = await DBService.instance.database;

                                      await db.rawUpdate(
                                        '''
                                  UPDATE customer
                                  SET credit_limit = credit_limit + ?,
                                      available_credit = available_credit + ?
                                  WHERE id = ?
                                  ''',
                                        [amountToAdd, amountToAdd, widget.customer.id],
                                      );

                                      await fetchCustomerData();
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Credit limit increased by ₱${currencyFormat.format(amountToAdd)}',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } catch (_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to update credit limit'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            child: const Text("Add"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================
  // TOTAL UTANG (total items - total payments)
  // ================================
  double get totalUtang {
    final totalItems = customerItems.fold(0.0, (sum, item) => sum + item.amount);
    final totalPayments = customerPayments.fold(0.0, (sum, pay) => sum + pay.amount);
    return totalItems - totalPayments;
  }

  // ================================
  // AVAILABLE CREDIT (calculated dynamically)
  // ================================
  double get availableCreditCalculated {
    if (creditLimit == null) return 0;
    return creditLimit! - totalUtang;
  }

  // ================================
  // GROUP ITEMS BY DATE
  // ================================
  Map<String, List<UtangItem>> groupItemsByDate() {
    Map<String, List<UtangItem>> grouped = {};
    for (var item in customerItems) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.creditDate);
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(item);
    }
    return grouped;
  }

  // ================================
  // PAYMENTS APPLIED PER DATE
  // ================================
  Map<String, double> remainingPerDate(
    Map<String, List<UtangItem>> groupedItems,
    List<String> sortedDates,
  ) {
    final result = <String, double>{};
    double paymentPool = customerPayments.fold(0.0, (sum, pay) => sum + pay.amount);

    // Apply payments FIFO to oldest utang date first.
    for (final dateKey in sortedDates) {
      final items = groupedItems[dateKey] ?? const <UtangItem>[];
      final totalPerDate = items.fold(0.0, (sum, item) => sum + item.amount);

      final paidForDate = paymentPool >= totalPerDate ? totalPerDate : paymentPool;
      paymentPool = (paymentPool - paidForDate).clamp(0.0, double.infinity);

      result[dateKey] = (totalPerDate - paidForDate).clamp(0.0, double.infinity);
    }

    return result;
  }

  String _paymentTypeLabel(int index) {
    var remaining = customerItems.fold(0.0, (sum, item) => sum + item.amount);

    for (var i = 0; i < customerPayments.length; i++) {
      final payment = customerPayments[i];
      final isFull = remaining > 0 && payment.amount >= remaining;
      final appliedAmount = payment.amount <= remaining ? payment.amount : remaining;

      if (i == index) {
        return isFull ? 'Full' : 'Partial';
      }

      remaining = (remaining - appliedAmount).clamp(0.0, double.infinity);
    }

    return 'Partial';
  }

  void _showPaymentsAppliedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SizedBox(width: 40, child: Divider(thickness: 4)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Payments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (customerPayments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No payments recorded yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Flexible(
                    child: Builder(
                      builder: (context) {
                        final paymentsLatestFirst = customerPayments.reversed.toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: paymentsLatestFirst.length,
                          itemBuilder: (context, index) {
                            final pay = paymentsLatestFirst[index];
                            final originalIndex =
                                customerPayments.indexWhere((p) => p.id == pay.id);
                            final payTime = DateFormat('MMM dd, yyyy hh:mm a').format(pay.paidAt);
                            final paymentType =
                                _paymentTypeLabel(originalIndex < 0 ? 0 : originalIndex);
                            final paymentTypeColor =
                                paymentType == 'Full' ? Colors.green : Colors.orange;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  paymentType,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: paymentTypeColor,
                                  ),
                                ),
                                subtitle: Text(payTime),
                                trailing: Text(
                                  '₱${currencyFormat.format(pay.amount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================
  // BUILD (RESPONSIVE UI ONLY)
  // ================================
  @override
  Widget build(BuildContext context) {
    final groupedItems = groupItemsByDate();
    final sortedDates = groupedItems.keys.toList()..sort((a, b) => a.compareTo(b));
    final remainingByDate = remainingPerDate(groupedItems, sortedDates);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Same idea we used: phone->tablet scaling, clamped.
        final double scale = (w / 390).clamp(0.90, 1.20);

        final double pad = (16 * scale).clamp(14, 22);
        final double cardRadius = (24 * scale).clamp(18, 28);
        final double tileRadius = (16 * scale).clamp(14, 20);

        final double titleFs = (18 * scale).clamp(16, 22);
        final double labelFs = (16 * scale).clamp(14, 18);
        final double bigFs = (36 * scale).clamp(28, 44);

        final double iconFs = (20 * scale).clamp(18, 24);
        final double gap12 = (12 * scale).clamp(8, 16);
        final double gap24 = (24 * scale).clamp(18, 30);

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppHeader(
            title: widget.customer.fullName,
            showBackButton: true,
            action: IconButton(
              icon: Icon(Icons.list, color: Colors.white, size: (24 * scale).clamp(22, 28)),
              onPressed: _showPaymentsAppliedSheet,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // ================= TOTAL UTANG CARD =================
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: (22 * scale).clamp(16, 28),
                      vertical: (26 * scale).clamp(18, 30),
                    ),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: _cardBorder.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(51),
                          blurRadius: (2 * scale).clamp(2, 6),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: title + paid pill (avoid overflow)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Total Utang",
                                style: TextStyle(
                                  fontSize: labelFs,
                                  fontWeight: FontWeight.w600,
                                  color: _subtitleColor,
                                ),
                              ),
                            ),
                            // ✅ show "Paid" only if has history AND totalUtang <= 0
                            if (_hasUtangHistory && totalUtang <= 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (14 * scale).clamp(10, 16),
                                  vertical: (7 * scale).clamp(6, 8),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  "Paid",
                                  style: TextStyle(
                                    fontSize: (13 * scale).clamp(12, 15),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: (18 * scale).clamp(12, 22)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "₱${currencyFormat.format(totalUtang)}",
                            style: TextStyle(
                              fontSize: bigFs,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: _titleColor,
                            ),
                          ),
                        ),
                        SizedBox(height: (20 * scale).clamp(14, 24)),
                        const Divider(thickness: 1),
                        SizedBox(height: (14 * scale).clamp(10, 18)),

                        if (widget.customer.barangay != null && widget.customer.barangay!.isNotEmpty)
                          _infoRow(
                            icon: Icons.location_city,
                            text: "Barangay ${widget.customer.barangay!}",
                            scale: scale,
                            iconSize: iconFs,
                            textSize: (15 * scale).clamp(13, 17),
                          ),

                        if (widget.customer.barangay != null && widget.customer.barangay!.isNotEmpty)
                          SizedBox(height: gap12),

                        if (creditLimit != null || availableCredit != null)
                          _infoRow(
                            icon: Icons.credit_score,
                            text: "Credit Limit: ₱${currencyFormat.format(creditLimit ?? 0)}",
                            scale: scale,
                            iconSize: iconFs,
                            textSize: (15 * scale).clamp(13, 17),
                          ),

                        if (creditLimit != null || availableCredit != null)
                          SizedBox(height: (8 * scale).clamp(6, 10)),

                        if (creditLimit != null || availableCredit != null)
                          _infoRow(
                            icon: Icons.account_balance_wallet,
                            text:
                                "Available Credit: ₱${currencyFormat.format(availableCreditCalculated)}",
                            scale: scale,
                            iconSize: iconFs,
                            textSize: (15 * scale).clamp(13, 17),
                          ),

                        if (widget.customer.phoneNumber != null) SizedBox(height: gap12),

                        if (widget.customer.phoneNumber != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                icon: Icons.phone,
                                text: widget.customer.phoneNumber!,
                                scale: scale,
                                iconSize: iconFs,
                                textSize: (15 * scale).clamp(13, 17),
                              ),
                              SizedBox(height: (10 * scale).clamp(8, 14)),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: totalUtang > 0 ? addPartialPayment : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: (16 * scale).clamp(14, 18),
                                      vertical: (10 * scale).clamp(10, 12),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular((10 * scale).clamp(10, 14)),
                                    ),
                                  ),
                                  child: Text(
                                    "Add Payment",
                                    style: TextStyle(
                                      fontSize: (14 * scale).clamp(13, 16),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: (8 * scale).clamp(6, 12)),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: adjustCreditLimit,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: (16 * scale).clamp(14, 18),
                                      vertical: (10 * scale).clamp(10, 12),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular((10 * scale).clamp(10, 14)),
                                    ),
                                  ),
                                  child: Text(
                                    "Add Credit",
                                    style: TextStyle(
                                      fontSize: (14 * scale).clamp(13, 16),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: gap24),
                  Text(
                    "Lista",
                    style: TextStyle(
                      fontSize: titleFs,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                  ),
                  SizedBox(height: gap12),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (groupedItems.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: (20 * scale).clamp(14, 24)),
                      child: Center(
                        child: Text(
                          "Walay item sa utangan",
                          style: TextStyle(
                            fontSize: (16 * scale).clamp(14, 18),
                            color: _subtitleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      itemCount: sortedDates.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final dateKey = sortedDates[index];
                        final items = groupedItems[dateKey]!;
                        final date = DateTime.parse(dateKey);
                        final dateLabel = DateFormat('MMM dd, yyyy').format(date);

                        final totalPerDate = items.fold(0.0, (sum, item) => sum + item.amount);
                        final remaining = (remainingByDate[dateKey] ?? totalPerDate);

                        return Card(
                          color: _cardBg,
                          margin: EdgeInsets.symmetric(vertical: (8 * scale).clamp(6, 10)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(tileRadius),
                          ),
                          elevation: 3,
                          child: ExpansionTile(
                                      tilePadding: EdgeInsets.symmetric(
                                        horizontal: (16 * scale).clamp(12, 18),
                                        vertical: (12 * scale).clamp(10, 14),
                                      ),
                                      childrenPadding: EdgeInsets.symmetric(
                                        horizontal: (16 * scale).clamp(12, 18),
                                        vertical: (8 * scale).clamp(6, 10),
                                      ),
                                      initiallyExpanded: false,
                                      title: Row(
                                        children: [
                                          // LEFT side (date + due + total) must be flexible
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dateLabel,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: (16 * scale).clamp(14, 18),
                                                    color: _titleColor,
                                                  ),
                                                ),
                                                if (items.first.dueDate != null)
                                                  Text(
                                                    "Due: ${DateFormat('MMM dd, yyyy').format(items.first.dueDate!)}",
                                                    style: TextStyle(
                                                      fontSize: (13 * scale).clamp(12, 15),
                                                      color: _isOverdue(items.first.dueDate!)
                                                          ? Colors.red
                                                          : Colors.green,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                Text(
                                                  "Total: ₱${currencyFormat.format(totalPerDate)}",
                                                  style: TextStyle(
                                                    fontSize: (14 * scale).clamp(12.5, 16),
                                                    color: _subtitleColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // RIGHT side (Remaining / Paid) should never overflow
                                          const SizedBox(width: 10),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w < 360 ? 120 : 160,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                remaining > 0
                                                    ? "Remaining: ₱${currencyFormat.format(remaining)}"
                                                    : "Paid",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: (14 * scale).clamp(12.5, 16),
                                                  color: remaining > 0 ? Colors.red : Colors.green[800],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        SizedBox(height: (8 * scale).clamp(6, 10)),
                                        ...items.map((item) {
                                          return Container(
                                            margin: EdgeInsets.symmetric(vertical: (4 * scale).clamp(3, 6)),
                                            padding: EdgeInsets.all((12 * scale).clamp(10, 14)),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.72),
                                              borderRadius: BorderRadius.circular((12 * scale).clamp(10, 14)),
                                              boxShadow: [
                                                BoxShadow(
                                                  // ignore: deprecated_member_use
                                                  color: Colors.grey.withOpacity(0.05),
                                                  blurRadius: (2 * scale).clamp(2, 6),
                                                  offset: const Offset(0, 1),
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
                                                        item.itemName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: (14 * scale).clamp(13, 16),
                                                          color: _titleColor,
                                                        ),
                                                      ),
                                                      Text(
                                                        "${item.quantity} pcs",
                                                        style: TextStyle(
                                                          fontSize: (12 * scale).clamp(11, 14),
                                                          color: _subtitleColor,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    "₱${currencyFormat.format(item.amount)}",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: (14 * scale).clamp(13, 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String text,
    required double scale,
    required double iconSize,
    required double textSize,
  }) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: _subtitleColor),
        SizedBox(width: (10 * scale).clamp(8, 12)),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: textSize,
              color: _titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
