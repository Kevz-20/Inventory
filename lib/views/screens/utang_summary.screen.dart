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
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'])
          : null,
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
  List<UtangItem> customerItems = [];
  List<CustomerPayment> customerPayments = [];
  final currencyFormat = NumberFormat("#,##0.00", "en_PH");
  bool isLoading = true;
  double? creditLimit;
  double? availableCredit;

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

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
        creditLimit = (customerResult.first['credit_limit'] as num?)
            ?.toDouble();
        availableCredit = (customerResult.first['available_credit'] as num?)
            ?.toDouble();
      }
      customerItems = itemsResult.map((e) => UtangItem.fromMap(e)).toList();
      customerPayments = paymentsResult
          .map((e) => CustomerPayment.fromMap(e))
          .toList();
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
                    Text(
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
                                    final db =
                                        await DBService.instance.database;
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final mobileNumber =
                                        prefs.getString('mobileNumber') ?? '';
                                    final accountRows = await db.query(
                                      'account',
                                      columns: [
                                        'id',
                                        'first_name',
                                        'middle_name',
                                        'last_name',
                                      ],
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
                                      'paid_at': DateTime.now()
                                          .toIso8601String(),
                                      'created_by_first_name':
                                          account['first_name'] ?? '',
                                      'created_by_middle_name':
                                          account['middle_name'] ?? '',
                                      'created_by_last_name':
                                          account['last_name'] ?? '',
                                    });

                                    final customerRepo = CustomerRepository(db);
                                    final currentCredit = await customerRepo
                                        .getAvailableCredit(widget.customer.id);

                                    await customerRepo
                                        .updateCustomer(widget.customer.id, {
                                          'available_credit':
                                              currentCredit + enteredAmount,
                                          'updated_at': DateTime.now()
                                              .toIso8601String(),
                                        });

                                    final capitalRepo =
                                        CapitalManagementRepository(db);
                                    await capitalRepo.addCustomerPaymentCash(
                                      enteredAmount,
                                    );

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
                              backgroundColor: isFullPay
                                  ? Colors.green
                                  : Colors.orange,
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
            final selectedAmount = selectedPreset != null
                ? presets[selectedPreset!]
                : customAmount;
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

                    /// Presets
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

                    /// Custom Amount
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

                    /// Buttons
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
                                      final db =
                                          await DBService.instance.database;

                                      await db.rawUpdate(
                                        '''
                                  UPDATE customer
                                  SET credit_limit = credit_limit + ?,
                                      available_credit = available_credit + ?
                                  WHERE id = ?
                                  ''',
                                        [
                                          amountToAdd,
                                          amountToAdd,
                                          widget.customer.id,
                                        ],
                                      );

                                      await fetchCustomerData();
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Credit limit increased by ₱${currencyFormat.format(amountToAdd)}',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } catch (_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to update credit limit',
                                          ),
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
    final totalItems = customerItems.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final totalPayments = customerPayments.fold(
      0.0,
      (sum, pay) => sum + pay.amount,
    );
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
  List<CustomerPayment> paymentsAppliedToDate(String dateKey) {
    final dateItems = groupItemsByDate()[dateKey]!;
    double remaining = dateItems.fold(0.0, (sum, item) => sum + item.amount);
    List<CustomerPayment> appliedPayments = [];

    for (var pay in customerPayments) {
      if (remaining <= 0) break;
      final applyAmount = (pay.amount <= remaining) ? pay.amount : remaining;
      if (applyAmount > 0) {
        appliedPayments.add(pay);
        remaining -= applyAmount;
      }
    }
    return appliedPayments;
  }

  String _paymentTypeLabel(int index) {
    var remaining = customerItems.fold(0.0, (sum, item) => sum + item.amount);

    for (var i = 0; i < customerPayments.length; i++) {
      final payment = customerPayments[i];
      final isFull = remaining > 0 && payment.amount >= remaining;
      final appliedAmount = payment.amount <= remaining
          ? payment.amount
          : remaining;

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
      backgroundColor: Colors.white, // White background
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
                        final paymentsLatestFirst = customerPayments.reversed
                            .toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: paymentsLatestFirst.length,
                          itemBuilder: (context, index) {
                            final pay = paymentsLatestFirst[index];
                            final originalIndex = customerPayments.indexWhere(
                              (p) => p.id == pay.id,
                            );
                            final payTime = DateFormat(
                              'MMM dd, yyyy hh:mm a',
                            ).format(pay.paidAt);
                            final paymentType = _paymentTypeLabel(
                              originalIndex < 0 ? 0 : originalIndex,
                            );
                            final paymentTypeColor = paymentType == 'Full'
                                ? Colors.green
                                : Colors.orange;

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
  // BUILD
  // ================================
  @override
  Widget build(BuildContext context) {
    final groupedItems = groupItemsByDate();
    final sortedDates = groupedItems.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: widget.customer.fullName,
        showBackButton: true,
        action: IconButton(
          icon: const Icon(Icons.list, color: Colors.white),
          onPressed: _showPaymentsAppliedSheet,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOTAL UTANG CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                        const Text(
                          "Total Utang",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                        if (totalUtang <= 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "Paid",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "₱${currencyFormat.format(totalUtang)}",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(thickness: 1),
                    const SizedBox(height: 14),
                    if (widget.customer.barangay != null &&
                        widget.customer.barangay!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_city,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Barangay ${widget.customer.barangay!}",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (creditLimit != null || availableCredit != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_score,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Credit Limit: ₱${currencyFormat.format(creditLimit ?? 0)}",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (creditLimit != null || availableCredit != null)
                      const SizedBox(height: 8),
                    if (creditLimit != null || availableCredit != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Available Credit: ₱${currencyFormat.format(availableCreditCalculated)}",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (widget.customer.phoneNumber != null)
                      const SizedBox(height: 12),
                    if (widget.customer.phoneNumber != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.customer.phoneNumber!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: totalUtang > 0
                                  ? addPartialPayment
                                  : null,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C4B3E),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("Add Payment"),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: adjustCreditLimit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0C4B3E),
                                side: const BorderSide(
                                  color: Color(0xFF0C4B3E),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("Add Credit"),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Lista",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // ================= ITEMIZED UTANG =================
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : groupedItems.isEmpty
                    ? const Center(
                        child: Text(
                          "Walay item sa utangan",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDates[index];
                          final items = groupedItems[dateKey]!;

                          final date = DateTime.parse(dateKey);
                          final dateLabel = DateFormat(
                            'MMM dd, yyyy',
                          ).format(date);

                          final totalPerDate = items.fold(
                            0.0,
                            (sum, item) => sum + item.amount,
                          );
                          final appliedPayments = paymentsAppliedToDate(
                            dateKey,
                          );
                          final totalPaidForDate = appliedPayments.fold(
                            0.0,
                            (sum, pay) => sum + pay.amount,
                          );
                          final remaining = totalPerDate - totalPaidForDate;

                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              initiallyExpanded: false,
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Credit date (date they owed)
                                      Text(
                                        dateLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      // Due date
                                      if (items.first.dueDate != null)
                                        Text(
                                          "Due: ${DateFormat('MMM dd, yyyy').format(items.first.dueDate!)}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                _isOverdue(items.first.dueDate!)
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                      // Total for that date
                                      Text(
                                        "Total: ₱${currencyFormat.format(totalPerDate)}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    remaining > 0
                                        ? "Remaining: ₱${currencyFormat.format(remaining)}"
                                        : "Paid",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: remaining > 0
                                          ? Colors.red
                                          : Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                const SizedBox(height: 8),

                                // ================= ITEMIZED LIST =================
                                ...items.map((item) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: Colors.grey.withOpacity(0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.itemName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "${item.quantity} pcs",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "₱${currencyFormat.format(item.amount)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
