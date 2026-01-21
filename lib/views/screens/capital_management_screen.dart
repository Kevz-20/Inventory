import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
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
            Column(
              children: [
                const SizedBox(height: 15),
                _miniBalanceCard(
                  title: "Cash on Hand",
                  value: vm.capitals.fold<double>(
                    0,
                    (p, e) => p + e.cashOnHand,
                  ),
                ),
                const SizedBox(height: 15),
                _miniBalanceCard(
                  title: "Capital",
                  value: vm.capitals.fold<double>(0, (p, e) => p + e.capital),
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
                    capitalAmount: amount,
                    cashOnHand: 0,
                    bankCash: 0,
                    remarks: _remarksController.text,
                  );

                  _amountController.clear();
                  _remarksController.clear();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  Widget _miniBalanceCard({required String title, required double value}) {
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
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(
            "₱${value.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

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
      numbersOnly: true, // ONLY numbers
      onSubmitted: (value) async {
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) return;

        await vm.addCapital(
          capitalAmount: amount,
          cashOnHand: 0,
          bankCash: 0,
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
      numbersOnly: false, // can input text and numbers
      onSubmitted: (value) async {
        final amount = double.tryParse(_amountController.text);
        if (amount == null || amount <= 0) return;

        await vm.addCapital(
          capitalAmount: amount,
          cashOnHand: 0,
          bankCash: 0,
          remarks: _remarksController.text,
        );
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
    bool numbersOnly = false, // true = only numbers, false = text + numbers
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
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
      keyboardType: numbersOnly
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numbersOnly
          ? [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,2}'), // only numbers with up to 2 decimals
              ),
            ]
          : null,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefix: prefix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  prefix,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              )
            : null,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
    ),
  );
}
