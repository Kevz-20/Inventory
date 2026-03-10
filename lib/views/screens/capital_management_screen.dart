// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../providers/capital_management_view_model_provider.dart';
import '../../providers/capital_management_repository_provider.dart';
import '../widgets/header.dart';
import '../widgets/adaptive_digits_text.dart';

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
  static const Color _pageBg = Color(0xFFF2F7F5);
  static const Color _cardBg = Color(0xFFEFF8F4);
  static const Color _fieldBg = Color(0xFFF6FBF9);
  static const Color _cardBorder = Color(0xFFBFDCD4);
  static const Color _titleColor = Color(0xFF0B3D35);
  static const Color _subtitleColor = Color(0xFF2F5C54);

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

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // ✅ same responsive scaling approach
            final double s = (w / 390).clamp(0.90, 1.20);

            final double padH = (16 * s).clamp(14, 22);
            final double padTop = (14 * s).clamp(10, 18);
            final double padBottom = (16 * s).clamp(12, 20);

            final double cardPad = (14 * s).clamp(12, 18);
            final double r16 = (16 * s).clamp(14, 20);
            final double r14 = (14 * s).clamp(12, 18);
            final double r12 = (12 * s).clamp(10, 16);

            final double fieldH = (58 * s).clamp(54, 66);
            final double btnH = (52 * s).clamp(48, 58);

            final double gap12 = (12 * s).clamp(10, 14);
            final double gap14 = (14 * s).clamp(12, 18);

            final double titleFs = (16 * s).clamp(14.5, 18);
            final double smallFs = (12 * s).clamp(11.5, 14);
            final double balanceLabelFs = (13 * s).clamp(12, 15);
            final double balanceValueFs = (18 * s).clamp(16, 22);
            final double bottomBtnFs = (16 * s).clamp(14.5, 18);

            return Scaffold(
              backgroundColor: _pageBg,
              appBar: const AppHeader(
                title: 'Capital Management',
                showBackButton: true,
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===================== SUMMARY =====================
                    Column(
                      children: [
                        _miniBalanceCard(
                          title: "Cash on Hand",
                          value: totalCashOnHand,
                          icon: Icons.money_rounded,
                          s: s,
                          padding: cardPad,
                          radius: r16,
                          labelFs: balanceLabelFs,
                          valueFs: balanceValueFs,
                        ),
                        SizedBox(height: gap12),
                        _miniBalanceCard(
                          title: "Capital",
                          value: totalCapital,
                          icon: Icons.account_balance_rounded,
                          s: s,
                          padding: cardPad,
                          radius: r16,
                          labelFs: balanceLabelFs,
                          valueFs: balanceValueFs,
                        ),
                      ],
                    ),

                    SizedBox(height: gap14),

                    // ===================== ADD CAPITAL =====================
                    _sectionCard(
                      title: 'Add Capital',
                      icon: Icons.add_circle_outline_rounded,
                      s: s,
                      padding: cardPad,
                      radius: r16,
                      titleFs: titleFs,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _amountInput(s: s, height: fieldH, radius: r12),
                          SizedBox(height: (8 * s).clamp(6, 10)),
                          Text(
                            'Enter the amount you want to add',
                            style: TextStyle(
                              fontSize: smallFs,
                              color: _subtitleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: gap12),

                          // Chips responsive
                          Wrap(
                            spacing: (8 * s).clamp(6, 10),
                            runSpacing: (8 * s).clamp(6, 10),
                            children: [
                              _quickAmountChip('500', s: s, radius: r12),
                              _quickAmountChip('1000', s: s, radius: r12),
                              _quickAmountChip('5000', s: s, radius: r12),
                            ],
                          ),

                          SizedBox(height: gap14),
                          _remarksInput(s: s, height: fieldH, radius: r12),
                        ],
                      ),
                    ),

                    SizedBox(height: (90 * s).clamp(70, 110)),
                  ],
                ),
              ),

              // ===================== BOTTOM BUTTON =====================
              bottomNavigationBar: Padding(
                padding: EdgeInsets.fromLTRB(
                  padH,
                  (12 * s).clamp(10, 14),
                  padH,
                  (12 * s).clamp(10, 14) + bottomPadding,
                ),
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(r14),
                  shadowColor: Colors.black.withOpacity(0.15),
                  child: SizedBox(
                    height: btnH,
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
                                    content: Text(
                                      'Capital added successfully!',
                                    ),
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
                          borderRadius: BorderRadius.circular(r14),
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
                          : Text(
                              "Add Capital",
                              style: TextStyle(
                                fontSize: bottomBtnFs,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  // ================= UI HELPERS (responsive params) =================

  Widget _card({
    required Widget child,
    required double padding,
    required double radius,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder.withOpacity(0.8)),
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

    required double s,
    required double padding,
    required double radius,
    required double titleFs,
  }) {
    return _card(
      padding: padding,
      radius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: (36 * s).clamp(34, 44),
                width: (36 * s).clamp(34, 44),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: (20 * s).clamp(18, 24),
                ),
              ),
              SizedBox(width: (10 * s).clamp(8, 12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: titleFs,
                    color: _titleColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (10 * s).clamp(8, 12)),
          Divider(color: _cardBorder.withOpacity(0.8), height: 1),
          SizedBox(height: (12 * s).clamp(10, 14)),
          child,
        ],
      ),
    );
  }

  Widget _miniBalanceCard({
    required String title,
    required double value,
    IconData? icon,

    required double s,
    required double padding,
    required double radius,
    required double labelFs,
    required double valueFs,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder.withOpacity(0.8)),
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
              height: (42 * s).clamp(38, 52),
              width: (42 * s).clamp(38, 52),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular((14 * s).clamp(12, 18)),
              ),
              child: Icon(
                icon,
                size: (22 * s).clamp(20, 28),
                color: AppColors.primary,
              ),
            ),
          if (icon != null) SizedBox(width: (12 * s).clamp(10, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _subtitleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: labelFs,
                  ),
                ),
                SizedBox(height: (4 * s).clamp(3, 6)),
                AdaptiveDigitsText(
                  _currencyFormatter.format(value),
                  style: TextStyle(
                    fontSize: valueFs,
                    fontWeight: FontWeight.w900,
                    color: _titleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAmountChip(
    String value, {
    required double s,
    required double radius,
  }) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (14 * s).clamp(12, 18),
          vertical: (12 * s).clamp(10, 14),
        ),
      ),
      child: Text(
        '₱${NumberFormat('#,##0').format(int.parse(value))}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: (13.5 * s).clamp(12.5, 15.5),
        ),
      ),
    );
  }

  Widget _amountInput({
    required double s,
    required double height,
    required double radius,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ThousandDecimalInputFormatter(),
        ],
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          color: _titleColor,
          fontWeight: FontWeight.w800,
          fontSize: (14 * s).clamp(13, 16),
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: Padding(
            padding: EdgeInsets.all((16 * s).clamp(14, 18)),
            child: Text(
              '₱',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: (18 * s).clamp(16, 22),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: _cardBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _remarksInput({
    required double s,
    required double height,
    required double radius,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: _remarksController,
        style: TextStyle(
          color: _titleColor,
          fontWeight: FontWeight.w700,
          fontSize: (14 * s).clamp(13, 16),
        ),
        decoration: InputDecoration(
          hintText: 'Optional note',
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: Icon(
            Icons.notes_rounded,
            color: AppColors.primary,
            size: (22 * s).clamp(20, 26),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: _cardBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}
