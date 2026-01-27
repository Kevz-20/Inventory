// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/db_service.dart';
import '../screens/utang_screen.dart'; // UtangCustomer model

// ================================
// MODEL FOR INDIVIDUAL UTANG ITEMS
// ================================
class UtangItem {
  final String itemName;
  final double amount;
  final int quantity;
  final DateTime creditDate;

  UtangItem({
    required this.itemName,
    required this.amount,
    required this.quantity,
    required this.creditDate,
  });

  factory UtangItem.fromMap(Map<String, dynamic> map) {
    return UtangItem(
      itemName: map['item_name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      creditDate: DateTime.tryParse(map['credit_date'] ?? '') ?? DateTime.now(),
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
  final currencyFormat = NumberFormat("#,##0.00", "en_PH");
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomerItems();
  }

  // ================================
  // FETCH CUSTOMER ITEMS FROM DB (with product join)
  // ================================
  Future<void> fetchCustomerItems() async {
    final db = await DBService.instance.database;

    final result = await db.rawQuery(
      '''
      SELECT p.name AS item_name, sc.amount, sc.quantity, sc.credit_date
      FROM sales_credit sc
      JOIN product p ON sc.product_id = p.id
      WHERE sc.customer_id = ?
      ORDER BY sc.credit_date DESC
      ''',
      [widget.customer.id],
    );

    setState(() {
      customerItems = result.map((e) => UtangItem.fromMap(e)).toList();
      isLoading = false;
    });
  }

  // ================================
  // GROUP ITEMS BY DATE
  // ================================
  Map<String, List<UtangItem>> groupItemsByDate() {
    Map<String, List<UtangItem>> grouped = {};

    for (var item in customerItems) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.creditDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    return grouped;
  }

  // ================================
  // BUILD
  // ================================
  @override
  Widget build(BuildContext context) {
    final groupedItems = groupItemsByDate();
    final sortedDates = groupedItems.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

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
                      "₱${widget.customer.totalAmount.toStringAsFixed(2)}",
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
                          final totalPerDate = items.fold<double>(
                            0.0,
                            (sum, item) => sum + item.amount,
                          );

                          final date = DateTime.parse(dateKey);
                          final isToday = DateUtils.isSameDay(
                            date,
                            DateTime.now(),
                          );
                          final isOverdue =
                              !isToday && date.isBefore(DateTime.now());
                          final dateColor = isOverdue
                              ? Colors.red
                              : isToday
                              ? Colors.green[800]
                              : Colors.black87;
                          final dateLabel = isToday
                              ? "Today"
                              : DateFormat('MMM dd, yyyy').format(date);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isOverdue
                                    ? Colors.red
                                    : isToday
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 2,
                              ),
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
                              initiallyExpanded: isToday,
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: dateColor,
                                        ),
                                      ),
                                      Text(
                                        "${items.length} item${items.length > 1 ? 's' : ''}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "₱${currencyFormat.format(totalPerDate)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              children: items.map((item) {
                                // ignore: unused_local_variable
                                final isItemOverdue = item.creditDate.isBefore(
                                  DateTime.now(),
                                );

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
                                      Expanded(
                                        child: Text(
                                          item.itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "₱${currencyFormat.format(item.amount)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${item.quantity} pcs",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
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
