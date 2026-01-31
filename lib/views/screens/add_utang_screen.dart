import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../widgets/header.dart';
import '../../services/db_service.dart';

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
  int selectedTab = 0; // 0 = Installment, 1 = Non-Installment

  // ==============================
  // CONTROLLERS
  // ==============================
  final TextEditingController itemController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();
  final TextEditingController downpaymentController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController paymentMethodController = TextEditingController();
  final TextEditingController datePaidController = TextEditingController();

  double remainingBalance = 0.0;
  double monthlyPayment = 0.0;

  @override
  void dispose() {
    itemController.dispose();
    totalCostController.dispose();
    downpaymentController.dispose();
    durationController.dispose();
    notesController.dispose();
    startDateController.dispose();
    paymentMethodController.dispose();
    datePaidController.dispose();
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

    // Adjust for shorter months (e.g., Feb)
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

  // ==============================
  // SAVE UTANG
  // ==============================
  Future<void> saveUtang() async {
    final db = await DBService.instance.database;

    if (itemController.text.isEmpty || totalCostController.text.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill item and total cost")),
      );
      return;
    }

    try {
      final total =
          double.tryParse(totalCostController.text.replaceAll(',', '')) ?? 0;
      final down =
          double.tryParse(downpaymentController.text.replaceAll(',', '')) ?? 0;

      // -----------------------------
      // FETCH CASH ON HAND
      // -----------------------------
      final cashRes = await db.rawQuery(
        'SELECT cash_on_hand FROM capital_management WHERE account_id = 1',
      );
      final cashOnHand =
          (cashRes.first['cash_on_hand'] as num?)?.toDouble() ?? 0.0;

      if (selectedTab == 0) {
        // INSTALLMENT
        final months = int.tryParse(durationController.text) ?? 1;
        final remaining = total - down;
        final monthly = months > 0 ? remaining / months : remaining;
        final firstDueDate = startDateController.text.isNotEmpty
            ? DateTime.tryParse(startDateController.text) ?? DateTime.now()
            : DateTime.now();

        // Set next due date initially to the first installment
        final nextDueDate = firstDueDate; // first installment is the next due

        // -----------------------------
        // CHECK DOWNPAYMENT VS CASH
        // -----------------------------
        if (down > cashOnHand) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Downpayment exceeds available cash."),
            ),
          );
          return;
        }

        // Insert into payable
        final finalDueDate = addMonths(firstDueDate, months);

      await db.insert('payable', {
        'account_id': 1,
        'supplier_name': 'Owner',
        'item': itemController.text,
        'original_amount': total,
        'remaining_amount': remaining,
        'due_date': DateFormat('yyyy-MM-dd').format(finalDueDate), // use variable
        'note': notesController.text,
        'is_paid': 0,
        'has_plan': 1,
        'plan_months': months,
        'plan_monthly': monthly,
        'first_due_date': DateFormat('yyyy-MM-dd').format(firstDueDate),
        'next_due_date': DateFormat('yyyy-MM-dd').format(nextDueDate),
        'is_asset': 1,
        'asset_category': 'Installment Purchase',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

        // Insert downpayment into owner_installments
        if (down > 0) {
          await db.insert('owner_installments', {
            'account_id': 1,
            'item': itemController.text,
            'downpayment': down,
            'created_at': DateTime.now().toIso8601String(),
          });

          // Deduct downpayment from Cash on Hand
          await db.rawUpdate(
            '''
          UPDATE capital_management
          SET cash_on_hand = cash_on_hand - ?
          WHERE account_id = 1
        ''',
            [down],
          );
        }

        // Increase Asset (Total Cost)
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
        // NON-INSTALLMENT
        final datePaid = datePaidController.text.isNotEmpty
            ? datePaidController.text
            : DateFormat('yyyy-MM-dd').format(DateTime.now());

        // -----------------------------
        // CHECK TOTAL COST VS CASH
        // -----------------------------
        if (total > cashOnHand) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Not enough cash to pay in full today."),
            ),
          );
          return;
        }

        await db.insert('payable', {
          'account_id': 1,
          'supplier_name': 'Owner',
          'item': itemController.text,
          'original_amount': total,
          'remaining_amount': 0,
          'due_date': datePaid,
          'note': notesController.text,
          'is_paid': 1,
          'has_plan': 0,
          'plan_months': null,
          'plan_monthly': null,
          'first_due_date': null,
          'next_due_date': null,
          'is_asset': 1,
          'asset_category': 'Direct Purchase',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Deduct from Cash on Hand
        if (total > 0) {
          await db.rawUpdate(
            '''
          UPDATE capital_management
          SET cash_on_hand = cash_on_hand - ?
          WHERE account_id = 1
        ''',
            [total],
          );
        }

        // Increase Asset (Total Cost)
        await db.insert('fixed_asset', {
          'account_id': 1,
          'name': itemController.text,
          'cost': total,
          'accumulated_depreciation': 0,
          'category': 'Direct Purchase',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // SUCCESS MESSAGE
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bayronon saved successfully")),
      );

      // CLEAR FIELDS
      itemController.clear();
      totalCostController.clear();
      downpaymentController.clear();
      durationController.clear();
      notesController.clear();
      startDateController.clear();
      paymentMethodController.clear();
      datePaidController.clear();
      setState(() {
        remainingBalance = 0.0;
        monthlyPayment = 0.0;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Pagdugang og Bayronon',
        showBackButton: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          buildToggleTab(),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: selectedTab == 0
                  ? buildInstallmentForm()
                  : buildNonInstallmentForm(),
            ),
          ),
          const SizedBox(height: 20),
          buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==============================
  // TOGGLE TAB
  // ==============================
  Widget buildToggleTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTab == 0 ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Installment",
                  style: TextStyle(
                    color: selectedTab == 0 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTab == 1 ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Non-Installment",
                  style: TextStyle(
                    color: selectedTab == 1 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // SAVE BUTTON
  // ==============================
  Widget buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            "Save Bayronon",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // ==============================
  // INSTALLMENT FORM
  // ==============================
  Widget buildInstallmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          "Item / Description",
          itemController,
          icon: Icons.description,
        ),
        const SizedBox(height: 16),
        buildCostDetailsCard(),
        const SizedBox(height: 16),
        buildScheduleNotesCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildCostDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cost Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            buildTextField(
              "Total Cost",
              totalCostController,
              keyboardType: TextInputType.number,
              icon: Icons.attach_money,
              onChanged: (_) => calculateInstallment(),
              inputFormatters: [ThousandsFormatter()],
            ),
            const SizedBox(height: 12),
            buildTextField(
              "Downpayment (optional)",
              downpaymentController,
              keyboardType: TextInputType.number,
              icon: Icons.money_off,
              onChanged: (_) => calculateInstallment(),
              inputFormatters: [ThousandsFormatter()],
            ),
            const SizedBox(height: 12),
            buildTextField(
              "Duration (months)",
              durationController,
              keyboardType: TextInputType.number,
              icon: Icons.calendar_today,
              onChanged: (_) => calculateInstallment(),
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
        ),
      ),
    );
  }

  Widget buildScheduleNotesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Schedule & Notes",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            buildTextField(
              "Start Date",
              startDateController,
              readOnly: true,
              icon: Icons.date_range,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    startDateController.text = DateFormat(
                      'yyyy-MM-dd',
                    ).format(date);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            buildTextField(
              "Notes / Optional Attachments",
              notesController,
              icon: Icons.note,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
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

  // ==============================
  // NON-INSTALLMENT FORM
  // ==============================
  Widget buildNonInstallmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          "Item / Description",
          itemController,
          icon: Icons.description,
        ),
        const SizedBox(height: 16),
        buildNonInstallmentPaymentCard(),
        const SizedBox(height: 16),
        buildNotesCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildNonInstallmentPaymentCard() {
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
            ),
            const SizedBox(height: 12),
            buildTextField(
              "Payment Method (Cash / Owner Paid / Bank Transfer)",
              paymentMethodController,
              icon: Icons.payment,
            ),
            const SizedBox(height: 12),
            buildTextField(
              "Date Paid",
              datePaidController,
              readOnly: true,
              icon: Icons.date_range,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    datePaidController.text = DateFormat(
                      'yyyy-MM-dd',
                    ).format(date);
                  });
                }
              },
            ),
          ],
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
        child: buildTextField(
          "Notes / Optional Attachments",
          notesController,
          icon: Icons.note,
        ),
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
