// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../providers/capital_management_repository_provider.dart';
import '../../providers/capital_management_view_model_provider.dart';
import '../widgets/adaptive_digits_text.dart';
import '../widgets/dashboard_background.dart';

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
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _fieldBg = Color(0xFFF9FBFF);
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _titleColor = Color(0xFF213A6B);
  static const Color _subtitleColor = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '\u20B1',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

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
            final double s = (w / 390).clamp(0.90, 1.20).toDouble();
            final double padH = (16 * s).clamp(14, 22).toDouble();
            final double padTop = (14 * s).clamp(10, 18).toDouble();
            final double padBottom = (16 * s).clamp(12, 20).toDouble();
            final double cardPad = (14 * s).clamp(12, 18).toDouble();
            final double r16 = (16 * s).clamp(14, 20).toDouble();
            final double r14 = (14 * s).clamp(12, 18).toDouble();
            final double r12 = (12 * s).clamp(10, 16).toDouble();
            final double fieldH = (58 * s).clamp(54, 66).toDouble();
            final double btnH = (52 * s).clamp(48, 58).toDouble();
            final double gap12 = (12 * s).clamp(10, 14).toDouble();
            final double gap14 = (14 * s).clamp(12, 18).toDouble();
            final double titleFs = (16 * s).clamp(14.5, 18).toDouble();
            final double smallFs = (12 * s).clamp(11.5, 14).toDouble();
            final double balanceLabelFs = (13 * s).clamp(12, 15).toDouble();
            final double bottomBtnFs = (16 * s).clamp(14.5, 18).toDouble();
            return Scaffold(
              backgroundColor: _pageBg,
              extendBody: true,
              appBar: AppBar(
                backgroundColor: _pageBg,
                elevation: 0,
                centerTitle: true,
                titleSpacing: 0,
                leadingWidth: 52,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Image.asset(
                    'lib/assets/arrowleft.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
                title: const Text(
                  'Capital Management',
                  style: TextStyle(
                    color: _titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              body: Stack(
                children: [
                  const DashboardBackground(),
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            padH,
                            padTop,
                            padH,
                            padBottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _summaryHeroCard(
                                s: s,
                                padding: cardPad,
                                radius: r16,
                                labelFs: balanceLabelFs,
                                cashOnHand: totalCashOnHand,
                                capital: totalCapital,
                              ),
                              SizedBox(height: gap14),
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
                                    _fieldLabel('Amount to add', s: s),
                                    SizedBox(
                                      height: (8 * s).clamp(6, 10).toDouble(),
                                    ),
                                    _amountInput(
                                      s: s,
                                      height: fieldH,
                                      radius: r12,
                                    ),
                                    SizedBox(
                                      height: (8 * s).clamp(6, 10).toDouble(),
                                    ),
                                    Text(
                                      'Enter the amount you want to add',
                                      style: TextStyle(
                                        fontSize: smallFs,
                                        color: _subtitleColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: gap12),
                                    Wrap(
                                      spacing: (8 * s).clamp(6, 10).toDouble(),
                                      runSpacing: (
                                        8 * s
                                      ).clamp(6, 10).toDouble(),
                                      children: [
                                        _quickAmountChip(
                                          '500',
                                          s: s,
                                          radius: r12,
                                        ),
                                        _quickAmountChip(
                                          '1000',
                                          s: s,
                                          radius: r12,
                                        ),
                                        _quickAmountChip(
                                          '5000',
                                          s: s,
                                          radius: r12,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: gap14),
                                    _fieldLabel('Note', s: s),
                                    SizedBox(
                                      height: (8 * s).clamp(6, 10).toDouble(),
                                    ),
                                    _remarksInput(
                                      s: s,
                                      height: fieldH,
                                      radius: r12,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: (24 * s).clamp(20, 32).toDouble()),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          padH,
                          (12 * s).clamp(10, 14).toDouble(),
                          padH,
                          (12 * s).clamp(10, 14).toDouble() + bottomPadding,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 12,
                          borderRadius: BorderRadius.circular(r14),
                          shadowColor: const Color(
                            0xFF869BCE,
                          ).withValues(alpha: 0.22),
                          child: SizedBox(
                            height: btnH,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: vm.isLoading || enteredAmount <= 0
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
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
                                backgroundColor: _accentBlue,
                                disabledBackgroundColor: const Color(
                                  0xFFD8E1F5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(r14),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: (18 * s).clamp(16, 22).toDouble(),
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
                                  : Text(
                                      'Add Capital',
                                      style: TextStyle(
                                        fontSize: bottomBtnFs,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        backgroundColor: _pageBg,
        body: Stack(
          children: [
            DashboardBackground(),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: _pageBg,
        body: Stack(
          children: [
            const DashboardBackground(),
            Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(
                  color: _titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 10),
            color: const Color(0xFF95A6D8).withOpacity(0.14),
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
    String? subtitle,
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
                height: (36 * s).clamp(34, 44).toDouble(),
                width: (36 * s).clamp(34, 44).toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accentBlue.withOpacity(0.16),
                      const Color(0xFF78C5FF).withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    (12 * s).clamp(10, 16).toDouble(),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _accentBlue,
                  size: (20 * s).clamp(18, 24).toDouble(),
                ),
              ),
              SizedBox(width: (10 * s).clamp(8, 12).toDouble()),
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
          SizedBox(height: (10 * s).clamp(8, 12).toDouble()),
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: TextStyle(
                color: _subtitleColor,
                fontSize: (12.8 * s).clamp(12, 14.5).toDouble(),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: (12 * s).clamp(10, 14).toDouble()),
          ],
          Divider(color: _cardBorder, height: 1),
          SizedBox(height: (14 * s).clamp(12, 16).toDouble()),
          child,
        ],
      ),
    );
  }

  Widget _summaryHeroCard({
    required double s,
    required double padding,
    required double radius,
    required double labelFs,
    required double cashOnHand,
    required double capital,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 10),
            color: const Color(0xFF95A6D8).withOpacity(0.14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available funds',
            style: TextStyle(
              color: _subtitleColor,
              fontWeight: FontWeight.w800,
              fontSize: labelFs,
            ),
          ),
          SizedBox(height: (8 * s).clamp(6, 10).toDouble()),
          Row(
            children: [
              Expanded(
                child: _summaryStatTile(
                  title: 'Cash on Hand',
                  value: cashOnHand,
                  icon: Icons.payments_rounded,
                  s: s,
                  labelFs: labelFs,
                ),
              ),
              SizedBox(width: (10 * s).clamp(8, 12).toDouble()),
              Expanded(
                child: _summaryStatTile(
                  title: 'Capital',
                  value: capital,
                  icon: Icons.savings_rounded,
                  s: s,
                  labelFs: labelFs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStatTile({
    required String title,
    required double value,
    required IconData icon,
    required double s,
    required double labelFs,
  }) {
    return Container(
      padding: EdgeInsets.all((12 * s).clamp(10, 14).toDouble()),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular((14 * s).clamp(12, 18).toDouble()),
        border: Border.all(color: _cardBorder.withOpacity(0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: (18 * s).clamp(16, 20).toDouble(),
            color: _accentBlue,
          ),
          SizedBox(height: (10 * s).clamp(8, 12).toDouble()),
          Text(
            title,
            style: TextStyle(
              color: _subtitleColor,
              fontWeight: FontWeight.w700,
              fontSize: labelFs,
            ),
          ),
          SizedBox(height: (4 * s).clamp(3, 6).toDouble()),
          AdaptiveDigitsText(
            _currencyFormatter.format(value),
            style: TextStyle(
              fontSize: (16 * s).clamp(14, 18).toDouble(),
              fontWeight: FontWeight.w900,
              color: _titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {required double s}) {
    return Text(
      text,
      style: TextStyle(
        color: _titleColor,
        fontWeight: FontWeight.w800,
        fontSize: (13.5 * s).clamp(12.5, 15).toDouble(),
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
        foregroundColor: _accentBlue,
        backgroundColor: const Color(0xFFF4F8FF),
        side: BorderSide(color: _accentBlue.withOpacity(0.18)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (14 * s).clamp(12, 18).toDouble(),
          vertical: (12 * s).clamp(10, 14).toDouble(),
        ),
      ),
      child: Text(
        '\u20B1${NumberFormat('#,##0').format(int.parse(value))}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: (13.5 * s).clamp(12.5, 15.5).toDouble(),
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
          fontSize: (14 * s).clamp(13, 16).toDouble(),
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          filled: true,
          fillColor: _fieldBg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: (14 * s).clamp(12, 16).toDouble(),
            vertical: (16 * s).clamp(14, 18).toDouble(),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all((16 * s).clamp(14, 18).toDouble()),
            child: Text(
              '\u20B1',
              style: TextStyle(
                color: _accentBlue,
                fontSize: (18 * s).clamp(16, 22).toDouble(),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _cardBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _accentBlue, width: 1.2),
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
        minLines: 1,
        maxLines: 3,
        style: TextStyle(
          color: _titleColor,
          fontWeight: FontWeight.w700,
          fontSize: (14 * s).clamp(13, 16).toDouble(),
        ),
        decoration: InputDecoration(
          hintText: 'Optional note',
          filled: true,
          fillColor: _fieldBg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: (14 * s).clamp(12, 16).toDouble(),
            vertical: (16 * s).clamp(14, 18).toDouble(),
          ),
          prefixIcon: Icon(
            Icons.notes_rounded,
            color: _accentBlue,
            size: (22 * s).clamp(20, 26).toDouble(),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _cardBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _accentBlue, width: 1.2),
          ),
        ),
      ),
    );
  }
}
