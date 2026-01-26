import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../providers/capital_management_view_model_provider.dart';
import '../../providers/capital_management_repository_provider.dart';
import '../widgets/header.dart';

class CapitalManagementScreen extends ConsumerStatefulWidget {
  const CapitalManagementScreen({super.key});

  @override
  ConsumerState<CapitalManagementScreen> createState() =>
      _CapitalManagementScreenState();
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat('#,##0.##');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final rawText = newValue.text.replaceAll(',', '');
    final value = double.tryParse(rawText);
    if (value == null) return oldValue;

    final formatted = formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CapitalManagementScreenState
    extends ConsumerState<CapitalManagementScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(capitalManagementRepositoryProvider);

    return repoAsync.when(
      data: (_) {
        final vm = ref.watch(capitalManagementViewModelProvider);

        final totalCashOnHand = vm.capitals.fold<double>(
          0,
          (sum, e) => sum + e.cashOnHand,
        );

        final totalCapital = vm.capitals.fold<double>(
          0,
          (sum, e) => sum + e.capital,
        );

        /// 🔴 CHANGE `createdAt` IF YOUR FIELD NAME IS DIFFERENT
        final DateTime? lastAddedDate = vm.capitals.isNotEmpty
            ? vm.capitals
                  .map((e) => e.createdAt) // <--- CHANGE HERE IF NEEDED
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : null;

        final enteredAmount =
            double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

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
                /// LAST ADDED DATE
                Text(
                  lastAddedDate == null
                      ? 'Last capital added: —'
                      : 'Last capital added: ${_dateFormatter.format(lastAddedDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 16),

                _miniBalanceCard(
                  title: "Cash on Hand",
                  value: totalCashOnHand,
                  icon: Icons.money,
                ),
                const SizedBox(height: 15),

                _miniBalanceCard(
                  title: "Capital",
                  value: totalCapital,
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 30),

                _addCapitalCard(totalCapital, enteredAmount),
                const SizedBox(height: 24),

                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: vm.isLoading || enteredAmount <= 0
                            ? null
                            : () async {
                                await vm.addCapital(
                                  capitalAmount: enteredAmount,
                                  remarks: _remarksController.text,
                                );

                                _amountController.clear();
                                _remarksController.clear();
                                setState(() {});
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: vm.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                    const SizedBox(height: 6),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  /// ================= UI HELPERS =================

  Widget _miniBalanceCard({
    required String title,
    required double value,
    IconData? icon, // optional prefix icon
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
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 6),
              ],
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _currencyFormatter.format(value),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _addCapitalCard(double currentCapital, double enteredAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Capital',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          _amountInput(controller: _amountController),
          const SizedBox(height: 6),
          Text(
            'Enter the amount you want to add',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _quickAmountChip('₱500'),
              const SizedBox(width: 8),
              _quickAmountChip('₱1,000'),
              const SizedBox(width: 8),
              _quickAmountChip('₱5,000'),
            ],
          ),

          const SizedBox(height: 16),

          _remarksInput(),
          const SizedBox(height: 16),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _quickAmountChip(String label) {
    return OutlinedButton(
      onPressed: () {
        final value = label.replaceAll('₱', '').replaceAll(',', '');
        _amountController.text = value;
        setState(() {});
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }

  Widget _amountInput({required TextEditingController controller}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
        ThousandsSeparatorInputFormatter(),
      ],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: '0.00',
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '₱',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      ),
    );
  }

  Widget _remarksInput() {
    return _inputField(controller: _remarksController, hint: "Optional note");
  }

  Widget _inputField({
    required TextEditingController controller,
    String? hint,
    String? prefix,
    bool numbersOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numbersOnly
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numbersOnly
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
              ThousandsSeparatorInputFormatter(),
            ]
          : null,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
