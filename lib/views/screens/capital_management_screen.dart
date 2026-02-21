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

class ThousandDecimalInputFormatter extends TextInputFormatter {
  final RegExp _amountPattern = RegExp(r'^\d*\.?\d{0,2}$');
  final NumberFormat _intFormatter = NumberFormat('#,##0');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return const TextEditingValue(text: '');

    if (!_amountPattern.hasMatch(raw)) return oldValue;

    final hasDot = raw.contains('.');
    final parts = raw.split('.');
    final intPartRaw = parts.first;
    final fracPart = hasDot ? (parts.length > 1 ? parts[1] : '') : '';

    final formattedInt = intPartRaw.isEmpty
        ? ''
        : _intFormatter.format(int.parse(intPartRaw));
    final formatted = hasDot ? '$formattedInt.$fracPart' : formattedInt;

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

  double _parseAmount() {
    final raw = _amountController.text.replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(capitalManagementViewModelProvider).loadCapitals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(capitalManagementRepositoryProvider);

    return repoAsync.when(
      data: (_) {
        final vm = ref.watch(capitalManagementViewModelProvider);

        final totalCashOnHand = vm.capitals.fold(
          0.0,
          (sum, e) => sum + e.cashOnHand,
        );
        final totalCapital = vm.capitals.fold(0.0, (sum, e) => sum + e.capital);

        final DateTime? lastAddedDate = vm.capitals.isNotEmpty
            ? vm.capitals
                  .map((e) => e.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : null;

        final enteredAmount = _parseAmount();

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const AppHeader(
            title: 'Capital Management',
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 12),
                _miniBalanceCard(
                  title: "Capital",
                  value: totalCapital,
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 24),
                _addCapitalCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isLoading || enteredAmount <= 0
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();

                            await vm.addCapital(
                              capitalAmount: enteredAmount,
                              remarks: _remarksController.text,
                            );

                            if (!mounted) return;

                            if (vm.error == null) {
                              _amountController.clear();
                              _remarksController.clear();
                              setState(() {});
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Capital added successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to add capital: ${vm.error}',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
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
                              color: Colors.white,
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
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  /// ================= UI HELPERS =================

  Widget _miniBalanceCard({
    required String title,
    required double value,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
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
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _addCapitalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Capital',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _amountInput(),
          const SizedBox(height: 6),
          Text(
            'Enter the amount you want to add',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickAmountChip('500'),
              const SizedBox(width: 8),
              _quickAmountChip('1000'),
              const SizedBox(width: 8),
              _quickAmountChip('5000'),
            ],
          ),
          const SizedBox(height: 16),
          _remarksInput(),
        ],
      ),
    );
  }

  Widget _quickAmountChip(String value) {
    return OutlinedButton(
      onPressed: () {
        final current = _amountController.text.replaceAll(',', '');
        final currentAmount = double.tryParse(current) ?? 0;
        final chipAmount = double.tryParse(value) ?? 0;
        final newAmount = currentAmount + chipAmount;
        _amountController.text = NumberFormat('#,##0.##').format(newAmount);
        setState(() {});
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
      ),
      child: Text('₱${NumberFormat('#,##0').format(int.parse(value))}'),
    );
  }

  Widget _amountInput() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ThousandDecimalInputFormatter(),
      ],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: '0.00',
        prefixText: '₱ ',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.info),
        ),
      ),
    );
  }

  Widget _remarksInput() {
    return TextField(
      controller: _remarksController,
      decoration: InputDecoration(
        hintText: 'Optional note',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.info),
        ),
      ),
    );
  }
}
