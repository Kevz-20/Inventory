import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import '../widgets/header.dart';

class BalanceSheetScreen extends StatelessWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Balance Sheet', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date Range Row
            Row(
              children: const [
                Expanded(
                  child: _DateBox(
                    title: "Start Date",
                    dateLabel: "Oct 16, 2025",
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DateBox(title: "End Date", dateLabel: "Oct 23, 2025"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Assets Section
            _buildSectionCard(
              title: "Assets",
              items: [
                "Cash on Hand",
                "Cash in Bank",
                "Accounts Receivable",
                "Inventory",
                "Fixed Assets",
              ],
              footer: "Total Assets",
            ),

            const SizedBox(height: 20),

            // Liabilities Section
            _buildSectionCard(
              title: "Liabilities",
              items: ["Accounts Payable"],
              footer: "Total Liabilities",
            ),

            const SizedBox(height: 80), // Extra spacing for bottom button
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED1C24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: Colors.black.withAlpha((0.3 * 255).round()),
              elevation: 4,
            ),
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              "Download PDF",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            onPressed: () {
              debugPrint("Download Balance Sheet tapped");
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<String> items,
    required String footer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          for (var item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                item,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          const Divider(thickness: 1),
          Text(
            footer,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String title;
  final String dateLabel;
  const _DateBox({required this.title, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateLabel, style: const TextStyle(fontSize: 14)),
              const Icon(Icons.calendar_today, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
