import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/capital_management_model.dart';
import '../../providers/capital_management_view_model_provider.dart';
import '../../view_models/capital_management_view_model.dart';
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
      final vm = ref.read(capitalManagementViewModelProvider);
      vm?.loadCapitals();
      vm?.loadTotalBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(capitalManagementViewModelProvider);

    // If DB/repo is not ready yet, just show an empty scaffold
    if (vm == null) return const Scaffold(body: SizedBox());

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
            _balanceCard(vm.capitals),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _smallCard(
                    "Cash on Hand",
                    vm.capitals.fold<double>(0, (p, e) => p + e.cashOnHand),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallCard(
                    "Capital",
                    vm.capitals.fold<double>(0, (p, e) => p + e.capital),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallCard(
                    "Bank Cash",
                    vm.capitals.fold<double>(0, (p, e) => p + e.bankCash),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _sectionTitle('Add New Capital'),
            const SizedBox(height: 10),
            _amountInput(vm),
            const SizedBox(height: 10),
            const Text(
              "Enter a valid amount (greater than 0).",
              style: TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
            const SizedBox(height: 15),
            _remarksInput(vm),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) return;

                  await vm.addCapital(
                    cashOnHand: amount,
                    remarks: _remarksController.text,
                  );

                  _amountController.clear();
                  _remarksController.clear();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Add Capital",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(List<CapitalManagementModel> capitals) {
    final totalBalance = capitals.fold<double>(
      0.0,
      (sum, c) => sum + c.cashOnHand + c.bankCash,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            "Total Balance",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            "₱${totalBalance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Updated • ${DateFormat('yMMMd').format(DateTime.now())}",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _smallCard(String label, double value) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Text(
          "₱${value.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _amountInput(CapitalManagementViewModel vm) {
    return _inputField(
      controller: _amountController,
      hint: "0.00",
      prefix: "₱ ",
      onSubmitted: (value) async {
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) return;

        await vm.addCapital(
          cashOnHand: amount,
          remarks: _remarksController.text,
        );

        _amountController.clear();
        _remarksController.clear();
      },
    );
  }

  Widget _remarksInput(CapitalManagementViewModel vm) {
    return _inputField(
      controller: _remarksController,
      hint: "Optional note",
      onSubmitted: (value) async {
        final amount = double.tryParse(_amountController.text);
        if (amount == null || amount <= 0) return;

        await vm.addCapital(cashOnHand: amount, remarks: value);

        _amountController.clear();
        _remarksController.clear();
      },
    );
  }

  Widget _inputField({
    TextEditingController? controller,
    String? hint,
    String? prefix,
    required Function(String) onSubmitted,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(51),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: const TextStyle(fontSize: 18, color: Colors.black87),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
    ),
  );
}
