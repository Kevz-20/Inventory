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

    final formattedInt =
        intPartRaw.isEmpty ? '' : _intFormatter.format(int.parse(intPartRaw));
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
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return repoAsync.when(
      data: (_) {
        final vm = ref.watch(capitalManagementViewModelProvider);

        final totalCashOnHand = vm.capitals.fold(
          0.0,
          (sum, e) => sum + e.cashOnHand,
        );
        final totalCapital = vm.capitals.fold(0.0, (sum, e) => sum + e.capital);

        final enteredAmount = _parseAmount();

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const AppHeader(
            title: 'Capital Management',
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===================== SUMMARY (better layout) =====================
                Row(
                  children: [
                    Expanded(
                      child: _miniBalanceCard(
                        title: "Cash on Hand",
                        value: totalCashOnHand,
                        icon: Icons.money_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniBalanceCard(
                        title: "Capital",
                        value: totalCapital,
                        icon: Icons.account_balance_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ===================== ADD CAPITAL =====================
                _sectionCard(
                  title: 'Add Capital',
                  icon: Icons.add_circle_outline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _amountInput(),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the amount you want to add',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chips responsive
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickAmountChip('500'),
                          _quickAmountChip('1000'),
                          _quickAmountChip('5000'),
                        ],
                      ),

                      const SizedBox(height: 14),
                      _remarksInput(),
                    ],
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),

          // ===================== BOTTOM BUTTON (same behavior) =====================
          bottomNavigationBar: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(14),
              shadowColor: Colors.black.withOpacity(0.15),
              child: SizedBox(
                height: 52,
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
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  // ================= UI HELPERS =================

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _miniBalanceCard({
    required String title,
    required double value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null)
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormatter.format(value),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text('₱${NumberFormat('#,##0').format(int.parse(value))}'),
    );
  }

  Widget _amountInput() {
    return SizedBox(
      height: 58,
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ThousandDecimalInputFormatter(),
        ],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '₱',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _remarksInput() {
    return SizedBox(
      height: 58,
      child: TextField(
        controller: _remarksController,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Optional note',
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primary),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}