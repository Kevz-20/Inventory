// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/db_service.dart';
import '../screens/utang_screen.dart';

// ================================
// MODEL FOR INDIVIDUAL UTANG ITEMS
// ================================
class UtangItem {
  final int salesCreditId;
  final String itemName;
  final double amount;
  final int quantity;
  final DateTime creditDate;

  UtangItem({
    required this.salesCreditId,
    required this.itemName,
    required this.amount,
    required this.quantity,
    required this.creditDate,
  });

  factory UtangItem.fromMap(Map<String, dynamic> map) {
    return UtangItem(
      salesCreditId: map['sales_credit_id'],
      itemName: map['item_name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      creditDate: DateTime.tryParse(map['credit_date'] ?? '') ?? DateTime.now(),
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
  final int? creditDateId; // optional, in case you want to track

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

    // Fetch items
    final itemsResult = await db.rawQuery(
      '''
      SELECT
        sc.id AS sales_credit_id,
        p.name AS item_name,
        sc.amount,
        sc.quantity,
        sc.credit_date
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
    final TextEditingController paymentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Payment"),
        content: TextField(
          controller: paymentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Enter payment amount",
            prefixText: "₱",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(paymentController.text);
              if (amount == null || amount <= 0) return;

              Navigator.pop(context);
              final db = await DBService.instance.database;

              await db.insert('customer_payment', {
                'customer_id': widget.customer.id,
                'amount': amount,
                'paid_at': DateTime.now().toIso8601String(),
              });

              // Refresh data
              await fetchCustomerData();
            },
            child: const Text("Add"),
          ),
        ],
      ),
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
  // CALCULATE PAYMENTS PER DATE
  // ================================
  double totalPaymentsForDate(String dateKey) {
    // For simplicity, apply payments sequentially to oldest credit first
    final dateItems = groupItemsByDate()[dateKey]!;
    double remaining = dateItems.fold(0.0, (sum, item) => sum + item.amount);
    double applied = 0.0;

    for (var pay in customerPayments) {
      if (remaining <= 0) break;
      final applyAmount = (pay.amount <= remaining) ? pay.amount : remaining;
      applied += applyAmount;
      remaining -= applyAmount;
    }
    return applied;
  }

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
      appBar: AppBar(
        title: Text(widget.customer.fullName),
        backgroundColor: const Color(0xFF0C4B3E),
        elevation: 0,
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
                        if (widget.customer.dueDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: widget.customer.remainingDays <= 0
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              widget.customer.remainingDays <= 0
                                  ? "Overdue"
                                  : "${widget.customer.remainingDays} days left",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.customer.remainingDays <= 0
                                    ? Colors.red
                                    : Colors.green[800],
                              ),
                            ),
                          ),
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
                        widget.customer.barangay!.isNotEmpty) ...[
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
                    ],
                    if (widget.customer.phoneNumber != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 20, color: Colors.grey),
                          const SizedBox(width: 10),
                          Text(
                            widget.customer.phoneNumber!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: addPartialPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C4B3E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Add Payment"),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Itemized Utang",
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
                                      Text(
                                        dateLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
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
                                    "Remaining: ₱${currencyFormat.format(remaining)}",
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
                                // List payments applied to this date
                                if (appliedPayments.isNotEmpty) ...[
                                  const Divider(),
                                  const Text(
                                    "Payments applied:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...appliedPayments.map((pay) {
                                    final payTime = DateFormat(
                                      'MMM dd, yyyy hh:mm a',
                                    ).format(pay.paidAt);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "₱${currencyFormat.format(pay.amount)}",
                                          ),
                                          Text(
                                            payTime,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],

                                const SizedBox(height: 8),
                                // List items
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
                                }).toList(),
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
