// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../widgets/header.dart';
import '../../services/db_service.dart';
import '../../models/current_user.dart';

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Dugang Bayronon',
        showBackButton: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTextField(
                    "Item / Description",
                    itemController,
                    icon: Icons.description,
                  ),
                  const SizedBox(height: 16),

                  buildPaymentCard(),

                  const SizedBox(height: 16),

                  buildNotesCard(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          buildSaveButton(),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ==============================
  // PAYMENT CARD (toggle inside)
  // ==============================
  Widget buildPaymentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            buildTextField(
              "Total Cost",
              totalCostController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              icon: Icons.attach_money,
              onChanged: (_) => onTotalCostChanged(),
            ),
            const SizedBox(height: 12),

            buildTextField(
              "Due Date",
              dueDateController,
              readOnly: true,
              icon: Icons.date_range,
              onTap: pickDueDate,
            ),

            const SizedBox(height: 8),

            // ✅ toggle now inside the card (not at the top of page)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                value: isInstallment,
                activeColor: AppColors.primary,
                onChanged: _setInstallment,
                title: const Text(
                  "Installment Plan",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isInstallment
                      ? "Monthly schedule will apply"
                      : "Enable if you will pay monthly",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),

            if (isInstallment) ...[
              const SizedBox(height: 12),
              buildTextField(
                "Downpayment",
                downpaymentController,
                keyboardType: TextInputType.number,
                icon: Icons.money_off,
                onChanged: (_) => onDownpaymentChanged(),
                inputFormatters: [ThousandsFormatter()],
                errorText: downpaymentErrorText,
              ),
              const SizedBox(height: 12),
              buildTextField(
                "Duration (months)",
                durationController,
                keyboardType: TextInputType.number,
                icon: Icons.calendar_today,
                onChanged: (_) => calculateInstallment(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildInfoCard(
                      "Remaining Balance",
                      remainingBalance,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildInfoCard(
                      "Monthly Payment",
                      monthlyPayment,
                      Colors.blue,
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
  Widget buildSaveButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: saveUtang,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Rekord",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================
  // TEXT FIELD BUILDER
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        errorText: errorText,
        prefixIcon: icon != null
            ? (icon == Icons.attach_money || icon == Icons.money_off
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        "₱",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Icon(icon, color: Colors.grey))
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget buildNotesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildTextField("Notes", notesController, icon: Icons.note),
      ),
    );
  }

  Widget buildInfoCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            "₱${currencyFormat.format(amount)}",
            style: TextStyle(
              fontSize: 16,
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
