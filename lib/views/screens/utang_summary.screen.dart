// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../screens/utang_screen.dart';
import '../widgets/header.dart'; // UtangCustomer model

class UtangSummaryPage extends StatelessWidget {
  final UtangCustomer customer;

  const UtangSummaryPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(title: customer.fullName, showBackButton: true),

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
                  vertical: 26, // 🔥 taller card
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
                    // HEADER
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
                        if (customer.dueDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: customer.remainingDays <= 0
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              customer.remainingDays <= 0
                                  ? "Overdue"
                                  : "${customer.remainingDays} days left",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: customer.remainingDays <= 0
                                    ? Colors.red
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // AMOUNT (VERY PROMINENT)
                    Text(
                      "₱${customer.totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(thickness: 1),
                    const SizedBox(height: 14),

                    // DETAILS
                    if (customer.municipality != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              customer.municipality!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (customer.phoneNumber != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 20, color: Colors.grey),
                          const SizedBox(width: 10),
                          Text(
                            customer.phoneNumber!,
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

              // ================= ITEMIZED UTANG =================
              const Text(
                "Itemized Utang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: const [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: ListTile(
                        title: Text("Item 1"),
                        subtitle: Text("₱50.00"),
                        trailing: Text("2 pcs"),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: ListTile(
                        title: Text("Item 2"),
                        subtitle: Text("₱30.00"),
                        trailing: Text("1 pcs"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
