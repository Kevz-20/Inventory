import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../view_models/stock_in_view_model.dart';
import '../widgets/header.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(stockInViewModelProvider);

    if (!vm.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Stock In', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (vm.successMessage != null)
              _messageBox(
                color: Colors.green.shade100,
                icon: Icons.check_circle,
                iconColor: AppColors.success,
                text: vm.successMessage!,
              ),
            if (vm.errorMessage != null)
              _messageBox(
                color: Colors.red.shade100,
                icon: Icons.error,
                iconColor: AppColors.error,
                text: vm.errorMessage!,
              ),

            _inputDate(vm),
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

            _autocompleteProduct(vm),
            const SizedBox(height: 15),

            _inputNumberField(
              label: 'Presyo sa pagpalit',
              controller: vm.purchasePriceController,
              showError: vm.showValidationErrors,
              prefix: '₱ ',
            ),
            const SizedBox(height: 15),

            _inputNumberField(
              label: 'Presyo sa pagbaligya',
              controller: vm.sellingPriceController,
              showError: vm.showValidationErrors,
              prefix: '₱ ',
            ),
            const SizedBox(height: 15),

            _inputNumberField(
              label: 'Gidaghanon',
              controller: vm.quantityController,
              showError: vm.showValidationErrors,
            ),
            const SizedBox(height: 15),

            _imagePicker(vm),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
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
              : () {
                  vm.triggerValidation();
                  vm.saveProduct();
                },
          child: vm.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  // ----------------- Helper Widgets -----------------

  Widget _messageBox({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: iconColor))),
        ],
      ),
    );
  }

  Widget _inputDate(StockInViewModel vm) {
    return SizedBox(
      height: 60,
      child: TextField(
        readOnly: true,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: vm.selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) vm.pickDate(picked);
        },
        controller: TextEditingController(text: vm.formattedDate),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
          labelText: 'Date',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
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
    final isError = showError && value == null;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isError ? Colors.red : Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isError ? Colors.red : AppColors.primary),
        ),
      ),
      dropdownColor: Colors.white,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _autocompleteProduct(StockInViewModel vm) {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        return vm.productNames.where(
          (name) => name.toLowerCase().startsWith(value.text.toLowerCase()),
        );
      },
      fieldViewBuilder: (context, fieldController, focusNode, onSubmit) {
        vm.autocompleteFieldController = fieldController;
        final isError = vm.showValidationErrors && fieldController.text.isEmpty;

        return SizedBox(
          height: 60,
          child: TextField(
            controller: fieldController,
            focusNode: focusNode,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.edit, color: AppColors.primary),
              labelText: 'Pangalan sa produkto',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isError ? Colors.red : Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isError ? Colors.red : AppColors.primary),
              ),
            ),
            onChanged: (text) {
              vm.productController.text = text;
              vm.productController.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
            },
          ),
        );
      },
      onSelected: (value) {
        final product = vm.allProducts.firstWhere((p) => p.name == value);
        vm.selectedProduct = product;
        vm.productController.text = product.name;
        vm.setCategory(product.category);
        vm.purchasePriceController.text = _formatNumber(product.purchasePrice);
        vm.sellingPriceController.text = _formatNumber(product.sellingPrice);
        vm.quantityController.text = _formatNumber(product.quantity);
        vm.productImage = product.image != null ? File(product.image!) : null;
      },
    );
  }

  Widget _inputNumberField({
    required String label,
    required TextEditingController controller,
    required bool showError,
    String? prefix,
  }) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          ThousandsSeparatorInputFormatter(),
        ],
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixText: prefix,
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: showError && controller.text.isEmpty ? Colors.red : Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: showError && controller.text.isEmpty ? Colors.red : AppColors.primary),
          ),
        ),
        onChanged: (text) {
          final number = text.replaceAll(',', '');
          controller.value = controller.value.copyWith(
            text: _formatNumber(number),
            selection: TextSelection.collapsed(offset: _formatNumber(number).length),
          );
        },
      ),
    );
  }

  Widget _imagePicker(StockInViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload Image', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => vm.pickImage(ImageSource.gallery),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: vm.productImage != null
                ? Image.file(vm.productImage!, fit: BoxFit.cover)
                : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ----------------- Utilities -----------------
  String _formatNumber(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final digits = value.toString().replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    final chars = digits.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      chunks.add(chars.skip(i).take(3).join());
    }
    return chunks.map((e) => e.split('').reversed.join()).toList().reversed.join(',');
  }
}

// ----------------- Thousands Separator Input Formatter -----------------
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return const TextEditingValue();
    final chars = digits.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      chunks.add(chars.skip(i).take(3).join());
    }
    final formatted = chunks.map((e) => e.split('').reversed.join()).toList().reversed.join(',');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
