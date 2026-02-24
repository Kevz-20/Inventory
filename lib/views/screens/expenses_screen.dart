import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../view_models/expenses_view_model.dart';
import '../widgets/header.dart';
import '../../models/current_user.dart';

/// -----------------------------
/// Custom TextInputFormatter for thousands separator
/// -----------------------------
class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String text = newValue.text.replaceAll(',', '');

    if (!RegExp(r'^[0-9.]*$').hasMatch(text)) return oldValue;
    if ('.'.allMatches(text).length > 1) return oldValue;

    final parts = text.split('.');
    final integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);

    String formattedInteger = '';
    if (integerPart.isNotEmpty) {
      formattedInteger = _formatter.format(int.parse(integerPart));
    }

    String result = formattedInteger;

    if (text.endsWith('.')) {
      result = "$formattedInteger.";
    } else if (decimalPart.isNotEmpty) {
      result = "$formattedInteger.$decimalPart";
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(expensesViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final dateTextController = TextEditingController(text: vm.formattedDate);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Gasto',
        showBackButton: true,
        action: Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () => GoRouter.of(context).push('/list_expenses'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cleanCard(
                child: Column(
                children: [
                  _readOnlyField(
                    controller: dateTextController,
                    icon: Icons.calendar_month_rounded,
                    label: 'Petsa',
                    onTap: () => _pickDate(context, vm),
                  ),
                  const SizedBox(height: 12),
                  _inputDropdown(
                    icon: Icons.category_rounded,
                    label: 'Kategorya',
                    value: vm.selectedCategory,
                    items: vm.categories,
                    showError: vm.showValidationErrors,
                    onChanged: vm.setCategory,
                  ),
                  const SizedBox(height: 12),
                  _inputTextField(
                    prefix: const SizedBox(
                      width: 48,
                      child: Center(
                        child: Text(
                          '₱',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    label: 'Gasto',
                    controller: vm.amountController,
                    showError: vm.showValidationErrors,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsFormatter()],
                    hintText: "0.00",
                  ),
                  const SizedBox(height: 12),
                  _inputTextField(
                    prefix: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                    ),
                    label: 'Deskripsyon',
                    controller: vm.descriptionController,
                    showError: vm.showValidationErrors,
                    hintText: "Unsa ni nga gasto?",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: "Resibo (Opsyonal)",
              icon: Icons.camera_alt_rounded,
              child: _receiptSection(context, vm),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(14),
          shadowColor: Colors.black.withOpacity(0.15),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      vm.triggerValidation();

                      if (vm.amountController.text.isNotEmpty) {
                        vm.amountController.text =
                            vm.amountController.text.replaceAll(',', '');
                      }

                      await vm.save(
                        context: context,
                        createdByFirstName: CurrentUser.firstName ?? '',
                        createdByMiddleName: CurrentUser.middleName ?? '',
                        createdByLastName: CurrentUser.lastName ?? '',
                      );
                    },
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
                      'Rekord',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== CARD WRAPPER =====================
  Widget _sectionCard({
  required String title,
  required IconData icon,
  required Widget child,
}) {
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
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

  Widget _cleanCard({
  required Widget child,
}) {
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

  // ===================== READONLY DATE FIELD =====================
  Widget _readOnlyField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          suffixIcon: const Icon(Icons.chevron_right_rounded),
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

  // ===================== RECEIPT SECTION =====================
  Widget _receiptSection(BuildContext context, ExpensesViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pickReceiptImage(context, vm),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade50,
            ),
            child: vm.receiptImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(vm.receiptImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Tap para mag add og resibo",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickReceiptImage(context, vm),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text("Add / Retake"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.receiptImage == null ? null : vm.removeReceipt,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text("Remove"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================== INPUTS =====================
  Widget _inputDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required bool showError,
    required void Function(String?) onChanged,
  }) {
    final isError = showError && value == null;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isError ? Colors.red : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isError ? Colors.red : AppColors.primary,
            width: 1.2,
          ),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _inputTextField({
    required Widget? prefix,
    required String label,
    required TextEditingController controller,
    required bool showError,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
  }) {
    final isError = showError && controller.text.isEmpty;

    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: prefix,
          labelText: label,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : AppColors.primary,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ===================== DATE PICKER =====================
  Future<void> _pickDate(BuildContext context, ExpensesViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate.isAfter(DateTime.now())
          ? DateTime.now()
          : vm.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: DialogThemeData(backgroundColor: Colors.grey.shade100),
        ),
        child: child!,
      ),
    );

    if (picked != null) vm.setDate(picked);
  }

  // ===================== RECEIPT PICKER =====================
  Future<void> _pickReceiptImage(BuildContext context, ExpensesViewModel vm) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.photo_library, size: 28, color: AppColors.primary),
                label: const Text("Gallery", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                onPressed: () {
                  vm.pickReceipt(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.camera_alt, size: 28, color: AppColors.primary),
                label: const Text("Camera", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                onPressed: () {
                  vm.pickReceipt(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}