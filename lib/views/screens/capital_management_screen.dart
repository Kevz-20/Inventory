import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../providers/capital_management_view_model_provider.dart';
import '../widgets/header.dart';

class CapitalManagementScreen extends ConsumerStatefulWidget {
  const CapitalManagementScreen({super.key});

  @override
  ConsumerState<CapitalManagementScreen> createState() =>
      _CapitalManagementScreenState();
}

class _CapitalManagementScreenState
    extends ConsumerState<CapitalManagementScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(capitalManagementViewModelProvider).loadCapitals();
    });
  }

 @override
Widget build(BuildContext context) {
  final vm = ref.watch(capitalManagementViewModelProvider);

  // No need to check for null anymore
  return Scaffold(
    backgroundColor: AppColors.surface,
    appBar: const AppHeader(
      title: 'Capital Management',
      showBackButton: true,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),

          // Cash on Hand
          _miniBalanceCard(
            title: "Cash on Hand",
            value: vm.capitals.fold(0, (sum, e) => sum + e.cashOnHand),
          ),
          const SizedBox(height: 15),

          // Capital
          _miniBalanceCard(
            title: "Capital",
            value: vm.capitals.fold(0, (sum, e) => sum + e.capital),
          ),
          const SizedBox(height: 30),

          _sectionTitle('Add New Capital'),
          const SizedBox(height: 6),
          _amountInput(),
          const SizedBox(height: 10),
          const Text(
            "Enter a valid amount (greater than 0).",
            style: TextStyle(fontSize: 13, color: Color.fromARGB(255, 21, 21, 21)),
          ),
          const SizedBox(height: 15),
          _remarksInput(),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      final amount =
                          double.tryParse(_amountController.text);
                      if (amount == null || amount <= 0) return;

                      await vm.addCapital(
                        capitalAmount: amount,
                        remarks: _remarksController.text,
                      );

                      _amountController.clear();
                      _remarksController.clear();
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: vm.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      "Add Capital",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}


  /// ================= UI Helpers =================

  Widget _miniBalanceCard({
    required String title,
    required double value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(
            "₱${value.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );

  Widget _amountInput() {
    return _inputField(
      controller: _amountController,
      hint: "0.00",
      prefix: "₱ ",
      numbersOnly: true,
    );
  }

  Widget _remarksInput() {
    return _inputField(
      controller: _remarksController,
      hint: "Optional note",
      numbersOnly: false,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    String? hint,
    String? prefix,
    bool numbersOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: numbersOnly
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: numbersOnly
            ? [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
              ]
            : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
