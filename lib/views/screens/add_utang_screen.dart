import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';
import '../../services/db_service.dart'; // import your DBService
import 'package:intl/intl.dart';

class AddUtangPage extends StatefulWidget {
  const AddUtangPage({super.key});

  @override
  State<AddUtangPage> createState() => _AddUtangPageState();
}

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
  final TextEditingController startDateController =
      TextEditingController(); // <-- Added

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
    startDateController.dispose(); // <-- Added
    paymentMethodController.dispose();
    datePaidController.dispose();
    super.dispose();
  }

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

    if (selectedTab == 0) {
      // Installment
      final total =
          double.tryParse(totalCostController.text.replaceAll(',', '')) ?? 0;
      final down =
          double.tryParse(downpaymentController.text.replaceAll(',', '')) ?? 0;
      final months = int.tryParse(durationController.text) ?? 1;
      final remaining = total - down;
      final monthly = months > 0 ? remaining / months : remaining;

      await db.insert('payable', {
        'account_id': 1,
        'supplier_name': 'Owner',
        'item': itemController.text,
        'original_amount': total,
        'remaining_amount': remaining,
        'due_date': DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().add(Duration(days: 30 * months))),
        'note': notesController.text,
        'is_paid': 0,
        'has_plan': 1,
        'plan_months': months,
        'plan_monthly': monthly,
        'first_due_date': DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().add(const Duration(days: 30))),
        'next_due_date': DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().add(const Duration(days: 30))),
        'is_asset': 0,
        'asset_category': null,
        'create_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Non-Installment
      final total =
          double.tryParse(totalCostController.text.replaceAll(',', '')) ?? 0;
      await db.insert('payable', {
        'account_id': 1,
        'supplier_name': 'Owner',
        'item': itemController.text,
        'original_amount': total,
        'remaining_amount': total,
        'due_date': datePaidController.text.isNotEmpty
            ? datePaidController.text
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'note': notesController.text,
        'is_paid': 1,
        'has_plan': 0,
        'plan_months': null,
        'plan_monthly': null,
        'first_due_date': null,
        'next_due_date': null,
        'is_asset': 0,
        'asset_category': null,
        'create_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bayronon saved successfully")),
    );

    // Clear fields
    itemController.clear();
    totalCostController.clear();
    downpaymentController.clear();
    durationController.clear();
    notesController.clear();
    startDateController.clear(); // <-- Added
    paymentMethodController.clear();
    datePaidController.clear();

    setState(() {
      remainingBalance = 0.0;
      monthlyPayment = 0.0;
    });

    // Go back to Owner Utang page
    Future.delayed(const Duration(milliseconds: 500), () {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    });
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
          // ==============================
          // TOGGLE TAB
          // ==============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTab == 0
                            ? AppColors.primary
                            : Colors.white,
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
                        color: selectedTab == 1
                            ? AppColors.primary
                            : Colors.white,
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
          ),
          const SizedBox(height: 15),
          // ==============================
          // FORM
          // ==============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: selectedTab == 0
                  ? buildInstallmentForm()
                  : buildNonInstallmentForm(),
            ),
          ),
          const SizedBox(height: 20),
          // ==============================
          // SAVE BUTTON
          // ==============================
          Padding(
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
          ),
          const SizedBox(height: 20),
        ],
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

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Remaining Balance",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₱${currencyFormat.format(remainingBalance)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Monthly Payment",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₱${currencyFormat.format(monthlyPayment)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  startDateController, // <-- Updated
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
        ),
        const SizedBox(height: 20),
      ],
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

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                  icon: Icons.attach_money,
                  inputFormatters: [ThousandsFormatter()],
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
                        datePaidController.text = date.toIso8601String().split(
                          'T',
                        )[0];
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        ),
        const SizedBox(height: 20),
      ],
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
}

// ==============================
// THOUSANDS FORMATTER
// ==============================
class ThousandsFormatter extends TextInputFormatter {
  final formatter = NumberFormat('#,###');

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
