import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class CapitalManagementScreen extends StatelessWidget {
  const CapitalManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Capital Management",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _balanceCard(),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: _smallCard("Cash on Hand", "₱0.00")),
                const SizedBox(width: 10),
                Expanded(child: _smallCard("Capital", "₱0.00")),
                const SizedBox(width: 10),
                Expanded(child: _smallCard("Bank Cash", "₱0.00")),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    "Add Capital",
                    AppColors.primary,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    "Bank Deposit",
                    Colors.grey.shade200,
                    Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _amountInput(),
            const SizedBox(height: 10),
            const Text(
              "Enter a valid amount (greater than 0).",
              style: TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
            const SizedBox(height: 25),
            const Text(
              "Remarks",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _remarksInput(),
            const SizedBox(height: 30),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Balance",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          const Text(
            "₱0.00",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Updated • Oct 23, 2025",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _smallCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _amountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixText: "₱ ",
          prefixStyle: TextStyle(fontSize: 18, color: Colors.black87),
          border: InputBorder.none,
          hintText: "0.00",
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _remarksInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Optional note",
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        "Add Capital",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}
