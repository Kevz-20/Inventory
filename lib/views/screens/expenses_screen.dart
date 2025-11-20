import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../view_models/expenses_view_model.dart';
import '../widgets/header.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(expensesViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Gasto', showBackButton: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _datePicker(vm),
            const SizedBox(height: 18),
            _inputTextField(
              icon: Icons.payments,
              label: "Price",
              controller: vm.amountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            _categoryDropdown(vm),
            const SizedBox(height: 18),
            _inputTextField(
              icon: Icons.description,
              label: "Deskripsyon (Gikinahanglan)",
              controller: vm.descriptionController,
            ),
            const SizedBox(height: 20),
            _receiptButtons(vm),
            const SizedBox(height: 120),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              final saved = await vm.save();

              if (!context.mounted) return;

              if (!saved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Complete all required fields")),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Saved successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Rekord",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // DATE PICKER
  Widget _datePicker(ExpensesViewModel vm) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: vm.selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) vm.setDate(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Petsa",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDate(vm.selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _monthName(int m) {
    const List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[m - 1];
  }

  // CATEGORY
  Widget _categoryDropdown(ExpensesViewModel vm) {
    return SizedBox(
      height: 60,
      child: DropdownButtonFormField<String>(
        initialValue: vm.selectedCategory,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: "Kategorya sa Gasto",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: vm.categories.map((cat) {
          return DropdownMenuItem(value: cat, child: Text(cat));
        }).toList(),
        onChanged: (value) {
          if (value != null) vm.setCategory(value);
        },
      ),
    );
  }

  // RECEIPT BUTTONS
  Widget _receiptButtons(ExpensesViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resibo (opsyonal)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          // preview
          if (vm.receiptImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(vm.receiptImage!.path),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReceiptButton(
                "Photo",
                Colors.blue,
                vm.pickReceiptFromCamera,
              ),
              _buildReceiptButton(
                "Choose",
                Colors.indigo,
                vm.pickReceiptFromGallery,
              ),
              _buildReceiptButton("Remove", Colors.red, vm.removeReceipt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptButton(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _inputTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}
