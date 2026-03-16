// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../widgets/adaptive_digits_text.dart';
import '../../services/db_service.dart';
import '../../models/current_user.dart';
import '../widgets/dashboard_background.dart';
import '../widgets/primary_footer_nav.dart';

class AddUtangPage extends StatefulWidget {
  const AddUtangPage({super.key});

  @override
  State<AddUtangPage> createState() => _AddUtangPageState();
}

// -----------------------------
// CURRENCY FORMAT
// -----------------------------
final NumberFormat currencyFormat = NumberFormat('#,##0');

class _AddUtangPageState extends State<AddUtangPage> {
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _fieldBg = Color(0xFFF9FBFF);
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _titleColor = Color(0xFF213A6B);
  static const Color _subtitleColor = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  // ✅ Default: One-Time Payment
  bool isInstallment = false;

  // ==============================
  // CONTROLLERS
  // ==============================
  final TextEditingController itemController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();
  final TextEditingController downpaymentController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController dueDateController =
      TextEditingController(); // ✅ single date

  double remainingBalance = 0.0;
  double monthlyPayment = 0.0;
  String? downpaymentErrorText;

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    itemController.dispose();
    totalCostController.dispose();
    downpaymentController.dispose();
    durationController.dispose();
    notesController.dispose();
    dueDateController.dispose();
    super.dispose();
  }

  // -----------------------------
  // ADD MONTHS UTILITY FUNCTION
  // -----------------------------
  DateTime addMonths(DateTime date, int months) {
    int newMonth = date.month + months;
    int yearAdjustment = (newMonth - 1) ~/ 12;
    int month = ((newMonth - 1) % 12) + 1;
    int year = date.year + yearAdjustment;
    int day = date.day;

    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfMonth) day = lastDayOfMonth;

    return DateTime(year, month, day);
  }

  // ==============================
  // CALCULATE INSTALLMENT
  // ==============================
  void calculateInstallment() {
    final total =
        double.tryParse(totalCostController.text.replaceAll(',', '')) ?? 0;
    final down =
        double.tryParse(downpaymentController.text.replaceAll(',', '')) ?? 0;
    final months = int.tryParse(durationController.text) ?? 1;

    setState(() {
      remainingBalance = total - down;
      monthlyPayment = months > 0
          ? remainingBalance / months
          : remainingBalance;
    });
  }

  double parseAmount(String text) {
    return double.tryParse(text.replaceAll(',', '').trim()) ?? 0;
  }

  void validateDownpaymentAgainstTotal() {
    final total = parseAmount(totalCostController.text);
    final down = parseAmount(downpaymentController.text);

    final nextError = (total > 0 && down > total)
        ? "Downpayment exceeds Total Cost"
        : null;

    if (downpaymentErrorText == nextError) return;
    setState(() => downpaymentErrorText = nextError);
  }

  void onTotalCostChanged() {
    if (!isInstallment) return;
    validateDownpaymentAgainstTotal();
    calculateInstallment();
  }

  void onDownpaymentChanged() {
    validateDownpaymentAgainstTotal();
    calculateInstallment();
  }

  void _setInstallment(bool v) {
    setState(() {
      isInstallment = v;

      if (!isInstallment) {
        downpaymentController.clear();
        durationController.clear();
        remainingBalance = 0.0;
        monthlyPayment = 0.0;
        downpaymentErrorText = null;
      } else {
        validateDownpaymentAgainstTotal();
        calculateInstallment();
      }
    });
  }

  Future<void> pickDueDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        dueDateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  // ==============================
  // SAVE UTANG
  // ==============================
  Future<void> saveUtang() async {
    final item = itemController.text.trim();
    final totalCost = totalCostController.text.trim();
    final dueDateText = dueDateController.text.trim();
    final notes = notesController.text.trim();

    final missingFields = <String>[];
    if (item.isEmpty) missingFields.add("Item / Description");
    if (totalCost.isEmpty) missingFields.add("Total Cost");
    if (dueDateText.isEmpty) missingFields.add("Due Date");

    if (isInstallment) {
      if (downpaymentController.text.trim().isEmpty) {
        missingFields.add("Downpayment");
      }
      if (durationController.text.trim().isEmpty) {
        missingFields.add("Duration (months)");
      }
    }

    if (missingFields.isNotEmpty) {
      showErrorSnackBar("Please fill all details: ${missingFields.join(", ")}");
      return;
    }

    final db = await DBService.instance.database;

    try {
      final total =
          double.tryParse(
            totalCostController.text.replaceAll(',', '').trim(),
          ) ??
          0;
      final down =
          double.tryParse(
            downpaymentController.text.replaceAll(',', '').trim(),
          ) ??
          0;

      if (total <= 0) {
        if (!mounted) return;
        showErrorSnackBar("Total Cost must be greater than 0");
        return;
      }

      final dueDate = DateTime.tryParse(dueDateText) ?? DateTime.now();

      // FETCH CASH ON HAND (SHARED DB)
      final cashRes = await db.rawQuery(
        'SELECT SUM(cash_on_hand) as total_cash FROM capital_management',
      );
      final cashOnHand =
          (cashRes.first['total_cash'] as num?)?.toDouble() ?? 0.0;

      if (isInstallment) {
        final months = int.tryParse(durationController.text) ?? 1;

        if (months <= 0) {
          if (!mounted) return;
          showErrorSnackBar("Duration (months) must be greater than 0");
          return;
        }

        if (down < 0 || down > total) {
          if (!mounted) return;
          showErrorSnackBar("Downpayment must be between 0 and Total Cost");
          return;
        }

        final remaining = total - down;
        final monthly = months > 0 ? remaining / months : remaining;

        // ✅ Due Date = first installment due date
        final firstDueDate = dueDate;
        final nextDueDate = firstDueDate;
        final finalDueDate = addMonths(firstDueDate, months);

        if (down > cashOnHand) {
          if (!mounted) return;
          showErrorSnackBar(
            "Downpayment of ₱${currencyFormat.format(down)} exceeds available cash of ₱${currencyFormat.format(cashOnHand)}",
          );
          return;
        }

        await db.insert('payable', {
          'supplier_name': 'Owner',
          'item': itemController.text,
          'original_amount': total,
          'remaining_amount': remaining,
          'due_date': DateFormat(
            'yyyy-MM-dd',
          ).format(finalDueDate), // end of plan
          'note': notes,
          'is_paid': 0,
          'has_plan': 1,
          'plan_months': months,
          'plan_monthly': monthly,
          'first_due_date': DateFormat('yyyy-MM-dd').format(firstDueDate),
          'next_due_date': DateFormat('yyyy-MM-dd').format(nextDueDate),
          'is_asset': 1,
          'asset_category': 'Installment Purchase',
          'created_by_first_name': CurrentUser.firstName ?? '',
          'created_by_middle_name': CurrentUser.middleName ?? '',
          'created_by_last_name': CurrentUser.lastName ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (down > 0) {
          await db.insert('owner_installments', {
            'account_id': 1,
            'item': itemController.text,
            'downpayment': down,
            'created_at': DateTime.now().toIso8601String(),
          });

          await db.rawUpdate(
            '''
            UPDATE capital_management
            SET cash_on_hand = cash_on_hand - ?
            ''',
            [down],
          );
        }

        await db.insert('fixed_asset', {
          'account_id': 1,
          'name': itemController.text,
          'cost': total,
          'accumulated_depreciation': 0,
          'category': 'Installment Purchase',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // ✅ One-time utang: due_date is the due date
        await db.insert('payable', {
          'supplier_name': 'Owner',
          'item': itemController.text,
          'original_amount': total,
          'remaining_amount': total,
          'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
          'note': notes,
          'is_paid': 0,
          'has_plan': 0,
          'plan_months': null,
          'plan_monthly': null,
          'first_due_date': null,
          'next_due_date': null,
          'is_asset': 1,
          'asset_category': 'One-Time Payment',
          'created_by_first_name': CurrentUser.firstName ?? '',
          'created_by_middle_name': CurrentUser.middleName ?? '',
          'created_by_last_name': CurrentUser.lastName ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        await db.insert('fixed_asset', {
          'account_id': 1,
          'name': itemController.text,
          'cost': total,
          'accumulated_depreciation': 0,
          'category': 'Owner Utang',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bayronon saved successfully"),
          backgroundColor: AppColors.success,
        ),
      );

      // CLEAR FIELDS
      itemController.clear();
      totalCostController.clear();
      downpaymentController.clear();
      durationController.clear();
      notesController.clear();
      dueDateController.clear();

      setState(() {
        remainingBalance = 0.0;
        monthlyPayment = 0.0;
        downpaymentErrorText = null;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar("Failed to save: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final s = (w / 390).clamp(0.90, 1.20);

        final padH = (20 * s).clamp(16.0, 26.0);
        final gap12 = (12 * s).clamp(10.0, 14.0);
        final gap16 = (16 * s).clamp(12.0, 18.0);
        final gap20 = (20 * s).clamp(14.0, 24.0);

        final cardPad = (16 * s).clamp(12.0, 18.0);
        final r16 = (16 * s).clamp(14.0, 20.0);
        final r12 = (12 * s).clamp(10.0, 16.0);

        final btnH = (50 * s).clamp(46.0, 58.0);
        final btnText = (18 * s).clamp(15.0, 19.0);

        return Scaffold(
          backgroundColor: _pageBg,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: _pageBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
              icon: Image.asset(
                'lib/assets/arrowleft.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/owner_utang');
                }
              },
            ),
            title: Text(
              'Dugang Bayronon',
              style: TextStyle(
                color: _titleColor,
                fontWeight: FontWeight.w900,
                fontSize: (20 * s).clamp(18.0, 24.0),
              ),
            ),
          ),
          body: Stack(
            children: [
              const DashboardBackground(),
              Column(
                children: [
                  SizedBox(height: (12 * s).clamp(10.0, 16.0)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: padH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTextField(
                            "Item / Description",
                            itemController,
                            icon: Icons.description,
                            s: s,
                            radius: r12,
                          ),
                          SizedBox(height: gap16),
                          buildPaymentCard(
                            s: s,
                            cardPad: cardPad,
                            r16: r16,
                            r12: r12,
                            gap12: gap12,
                          ),
                          SizedBox(height: gap16),
                          buildNotesCard(
                            s: s,
                            cardPad: cardPad,
                            r16: r16,
                            r12: r12,
                          ),
                          SizedBox(height: gap20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildSaveButton(
                  s: s,
                  padH: padH,
                  btnH: btnH,
                  btnText: btnText,
                  r12: r12,
                  bottomInset: 0,
                ),
                const PrimaryFooterNav(
                  selectedTab: PrimaryFooterTab.ownerUtang,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================
  // PAYMENT CARD (toggle inside)
  // ==============================
  Widget buildPaymentCard({
    required double s,
    required double cardPad,
    required double r16,
    required double r12,
    required double gap12,
  }) {
    final titleFs = (16 * s).clamp(14.5, 18.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r16)),
      elevation: 0,
      color: _cardBg,
      child: Padding(
        padding: EdgeInsets.all(cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Details",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: titleFs,
                color: _titleColor,
              ),
            ),
            SizedBox(height: gap12),

            buildTextField(
              "Total Cost",
              totalCostController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              icon: Icons.attach_money,
              onChanged: (_) => onTotalCostChanged(),
              s: s,
              radius: r12,
            ),
            SizedBox(height: gap12),

            buildTextField(
              "Due Date",
              dueDateController,
              readOnly: true,
              icon: Icons.date_range,
              onTap: pickDueDate,
              s: s,
              radius: r12,
            ),

            SizedBox(height: (8 * s).clamp(6.0, 10.0)),

            // ✅ toggle inside the card
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (6 * s).clamp(6.0, 10.0),
                vertical: (4 * s).clamp(4.0, 8.0),
              ),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular((12 * s).clamp(10.0, 16.0)),
                border: Border.all(color: _cardBorder),
              ),
              child: SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: (6 * s).clamp(6.0, 10.0),
                ),
                value: isInstallment,
                activeColor: _accentBlue,
                onChanged: _setInstallment,
                title: Text(
                  "Installment Plan",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: (14 * s).clamp(13.0, 16.0),
                    color: _titleColor,
                  ),
                ),
                subtitle: Text(
                  isInstallment
                      ? "Monthly schedule will apply"
                      : "Enable if you will pay monthly",
                  style: TextStyle(
                    color: _subtitleColor,
                    fontSize: (12 * s).clamp(11.0, 13.5),
                  ),
                ),
              ),
            ),

            if (isInstallment) ...[
              SizedBox(height: gap12),
              buildTextField(
                "Downpayment",
                downpaymentController,
                keyboardType: TextInputType.number,
                icon: Icons.money_off,
                onChanged: (_) => onDownpaymentChanged(),
                inputFormatters: [ThousandsFormatter()],
                errorText: downpaymentErrorText,
                s: s,
                radius: r12,
              ),
              SizedBox(height: gap12),
              buildTextField(
                "Duration (months)",
                durationController,
                keyboardType: TextInputType.number,
                icon: Icons.calendar_today,
                onChanged: (_) => calculateInstallment(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                s: s,
                radius: r12,
              ),
              SizedBox(height: gap12),
              Row(
                children: [
                  Expanded(
                    child: buildInfoCard(
                      "Remaining Balance",
                      remainingBalance,
                      Colors.green,
                      s: s,
                      radius: r12,
                    ),
                  ),
                  SizedBox(width: (12 * s).clamp(10.0, 14.0)),
                  Expanded(
                    child: buildInfoCard(
                      "Monthly Payment",
                      monthlyPayment,
                      Colors.blue,
                      s: s,
                      radius: r12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==============================
  // SAVE BUTTON
  // ==============================
  Widget buildSaveButton({
    required double s,
    required double padH,
    required double btnH,
    required double btnText,
    required double r12,
    required double bottomInset,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padH,
          (10 * s).clamp(8.0, 14.0),
          padH,
          (12 * s).clamp(10.0, 16.0) + bottomInset,
        ),
        child: SizedBox(
          width: double.infinity,
          height: btnH,
          child: ElevatedButton(
            onPressed: saveUtang,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentBlue,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r12),
              ),
            ),
            child: Text(
              "Rekord",
              style: TextStyle(
                fontSize: btnText,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================
  // TEXT FIELD BUILDER (responsive params)
  // ==============================
  Widget buildTextField(
    String label,
    TextEditingController? controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    IconData? icon,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,

    // ✅ responsive
    required double s,
    required double radius,
  }) {
    final labelFs = (13.5 * s).clamp(12.0, 15.0);
    final textFs = (14.5 * s).clamp(13.0, 16.0);
    final padV = (12 * s).clamp(10.0, 14.0);
    final padH = (16 * s).clamp(14.0, 18.0);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: textFs),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _subtitleColor, fontSize: labelFs),
        errorText: errorText,
        prefixIcon: icon != null
            ? (icon == Icons.attach_money || icon == Icons.money_off
                  ? Padding(
                      padding: EdgeInsets.all((14 * s).clamp(12.0, 16.0)),
                      child: Text(
                        "₱",
                        style: TextStyle(
                          fontSize: (20 * s).clamp(16.0, 22.0),
                          fontWeight: FontWeight.bold,
                          color: _accentBlue,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      color: _accentBlue,
                      size: (22 * s).clamp(20.0, 26.0),
                    ))
            : null,
        filled: true,
        fillColor: _fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: _cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _accentBlue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      ),
    );
  }

  Widget buildNotesCard({
    required double s,
    required double cardPad,
    required double r16,
    required double r12,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r16)),
      elevation: 0,
      color: _cardBg,
      child: Padding(
        padding: EdgeInsets.all(cardPad),
        child: buildTextField(
          "Notes",
          notesController,
          icon: Icons.note,
          s: s,
          radius: r12,
        ),
      ),
    );
  }

  Widget buildInfoCard(
    String title,
    double amount,
    Color color, {
    required double s,
    required double radius,
  }) {
    final tFs = (14 * s).clamp(12.0, 15.0);
    final vFs = (16 * s).clamp(13.5, 17.5);

    return Container(
      padding: EdgeInsets.all((12 * s).clamp(10.0, 14.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: tFs, color: _subtitleColor),
          ),
          SizedBox(height: (4 * s).clamp(3.0, 6.0)),
          AdaptiveDigitsText(
            "₱${currencyFormat.format(amount)}",
            style: TextStyle(
              fontSize: vFs,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// THOUSANDS FORMATTER
// ==============================
class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;

    final number = int.tryParse(text);
    if (number == null) return oldValue;

    final formatted = formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
