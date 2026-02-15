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
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatter.format(int.parse(digits));
    final diff = formatted.length - digits.length;
    int cursor = newValue.selection.end + diff;
    cursor = cursor.clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(expensesViewModelProvider);

    // Get system bottom padding for adaptive layout
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

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
            onPressed: () {
              GoRouter.of(context).push('/list_expenses');
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (vm.successMessage != null)
              _banner(
                vm.successMessage!,
                Icons.check_circle,
                AppColors.success,
                Colors.green.shade100,
              ),
            if (vm.errorMessage != null)
              _banner(
                vm.errorMessage!,
                Icons.error,
                AppColors.error,
                Colors.red.shade100,
              ),
            InkWell(
              onTap: () => _pickDate(context, vm),
              child: _inputRow(
                icon: Icons.calendar_today,
                label: 'Petsa',
                value: vm.formattedDate,
                onTap: () => _pickDate(context, vm),
              ),
            ),
            const SizedBox(height: 15),
            _inputDropdown(
              icon: Icons.category,
              label: 'Kategorya',
              value: vm.selectedCategory,
              items: vm.categories,
              showError: vm.showValidationErrors,
              onChanged: vm.setCategory,
            ),
            const SizedBox(height: 15),
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
              label: 'Presyo',
              controller: vm.amountController,
              showError: vm.showValidationErrors,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
            ),
            const SizedBox(height: 15),
            _inputTextField(
              prefix: const Icon(Icons.description, color: AppColors.primary),
              label: 'Deskripsyon',
              controller: vm.descriptionController,
              showError: vm.showValidationErrors,
            ),
            const SizedBox(height: 25),
            _receiptSection(context, vm),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 15),
            //_allTransactionsList(vm), // ✅ Show all transactions
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + bottomPadding, // Add system bottom padding
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: vm.isLoading
              ? null
              : () async {
                  vm.triggerValidation();

                  if (vm.amountController.text.isNotEmpty) {
                    vm.amountController.text = vm.amountController.text
                        .replaceAll(',', '');
                  }

                  // ✅ Pass required CurrentUser info
                  await vm.save(
                    createdByFirstName: CurrentUser.firstName ?? '',
                    createdByMiddleName: CurrentUser.middleName ?? '',
                    createdByLastName: CurrentUser.lastName ?? '',
                  );
                },
          child: vm.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Rekord', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  // -----------------------------
  // Show all transactions (no filtering by account)
  // -----------------------------
  // Widget _allTransactionsList(ExpensesViewModel vm) {
  //   final expenses = vm.expenses; // ✅ All expenses from DB
  //   if (expenses.isEmpty) {
  //     return const Text(
  //       "Wala pang Gasto",
  //       style: TextStyle(color: Colors.grey),
  //     );
  //   }

  //   // Parse createdAt to DateTime and sort descending
  //   final sorted = [...expenses];
  //   sorted.sort((a, b) {
  //     final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
  //     final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
  //     return dateB.compareTo(dateA);
  //   });

  //   return ListView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: sorted.length,
  //     itemBuilder: (context, index) {
  //       final e = sorted[index];
  //       return Card(
  //         margin: const EdgeInsets.symmetric(vertical: 6),
  //         child: ListTile(
  //           title: Text(
  //             e.description.isNotEmpty ? e.description : 'Wala deskripsyon',
  //           ),
  //           subtitle: Text(
  //             '${e.createdByFirstName} ${e.createdByMiddleName ?? ''} ${e.createdByLastName}',
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           trailing: Text('₱${e.amount.toStringAsFixed(2)}'),
  //           onTap: () {
  //             // Optional: open existing expense
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // -----------------------------
  // Widgets (Receipt, Input, Banner, etc.)
  // -----------------------------
  Widget _receiptSection(BuildContext context, ExpensesViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Resibo (opsyonal)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickReceiptImage(context, vm),
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: vm.receiptImage != null
                ? Image.file(File(vm.receiptImage!.path), fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                  ),
          ),
        ),
        if (vm.receiptImage != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: vm.removeReceipt,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text("Remove", style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }

  Widget _banner(
    String message,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: iconColor)),
          ),
        ],
      ),
    );
  }

  Widget _inputRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 60,
      child: TextFormField(
        readOnly: true,
        onTap: onTap,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
        controller: TextEditingController(text: value),
      ),
    );
  }

  Widget _inputDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required bool showError,
    required void Function(String?) onChanged,
  }) {
    final bool isError = showError && value == null;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isError ? Colors.red : Colors.grey.shade400,
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
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
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
  }) {
    final bool isError = showError && controller.text.isEmpty;

    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: prefix,
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey.shade400,
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

  Future<void> _pickDate(BuildContext context, ExpensesViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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

  Future<void> _pickReceiptImage(
    BuildContext context,
    ExpensesViewModel vm,
  ) async {
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
                icon: const Icon(
                  Icons.photo_library,
                  size: 30,
                  color: AppColors.primary,
                ),
                label: const Text("Gallery", style: TextStyle(fontSize: 18)),
                onPressed: () {
                  vm.pickReceipt(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(
                  Icons.camera_alt,
                  size: 30,
                  color: AppColors.primary,
                ),
                label: const Text("Camera", style: TextStyle(fontSize: 18)),
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
