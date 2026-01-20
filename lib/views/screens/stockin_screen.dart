import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../view_models/stock_in_view_model.dart';
import '../widgets/header.dart';

class StockInScreen extends ConsumerWidget {
  const StockInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            InkWell(
              onTap: () => _pickDate(context, vm),
              child: _inputRow(
                icon: Icons.calendar_today,
                label: 'Date',
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

            Autocomplete<String>(
              optionsBuilder: (value) {
                if (value.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return vm.productNames.where(
                  (name) => name
                      .toLowerCase()
                      .startsWith(value.text.toLowerCase()),
                );
              },
              fieldViewBuilder:
                  (context, fieldController, focusNode, onSubmit) {
                vm.autocompleteFieldController = fieldController;
                final isError =
                    vm.showValidationErrors && fieldController.text.isEmpty;

                return SizedBox(
                  height: 60,
                  child: TextField(
                    controller: fieldController,
                    focusNode: focusNode,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon:
                          const Icon(Icons.edit, color: AppColors.primary),
                      labelText: 'Pangalan sa produkto',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isError
                              ? Colors.red
                              : Colors.grey.shade400,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isError
                              ? Colors.red
                              : AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                    onChanged: (text) {
                      vm.productController.text = text;
                      vm.productController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: text.length),
                      );
                    },
                  ),
                );
              },
              onSelected: (value) {
                final product =
                    vm.allProducts.firstWhere((p) => p.name == value);
                vm.selectedProduct = product;
                vm.productController.text = product.name;
                vm.setCategory(product.category);
                vm.purchasePriceController.text =
                    product.purchasePrice.toString();
                vm.sellingPriceController.text =
                    product.sellingPrice.toString();
                vm.quantityController.text = product.quantity.toString();
                vm.productImage = product.image != null
                    ? File(product.image!)
                    : null;
              },
            ),

            const SizedBox(height: 15),

            _inputTextField(
              prefix: _pesoPrefix(),
              label: 'Presyo sa pagpalit',
              controller: vm.purchasePriceController,
              showError: vm.showValidationErrors,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 15),

            _inputTextField(
              prefix:
                  const Icon(Icons.calculate, color: AppColors.primary),
              label: 'Presyo sa pagbaligya',
              controller: vm.sellingPriceController,
              showError: vm.showValidationErrors,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}'),
                ),
              ],
            ),

            const SizedBox(height: 15),

            _inputTextField(
              prefix:
                  const Icon(Icons.shopping_cart, color: AppColors.primary),
              label: 'Gidaghanon',
              controller: vm.quantityController,
              showError: vm.showValidationErrors,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 15),

            _imagePicker(context, vm),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}

Widget _pesoPrefix() {
  return const SizedBox(
    width: 48,
    child: Center(
      child: Text(
        '₱',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

Widget _inputTextField({
  Widget? prefix,
  required String label,
  required TextEditingController controller,
  required bool showError,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
}) {
  final isError = showError && controller.text.isEmpty;

  return SizedBox(
    height: 60,
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefix,
        labelText: label,
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

Widget _inputRow({
  required IconData icon,
  required String label,
  required String value,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 60,
    child: TextFormField(
      readOnly: true,
      onTap: onTap,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
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
  required void Function(String?) onChanged,
  required bool showError,
}) {
  final isError = showError && value == null;

  return DropdownButtonFormField<String>(
  initialValue: value, // ✅ use this instead of 'value'
  isExpanded: true,
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: AppColors.primary),
      labelText: label,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isError ? Colors.red : Colors.grey.shade400,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: isError ? Colors.red : AppColors.primary),
      ),
    ),
    items: items
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    onChanged: onChanged,
  );
}

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
    decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: iconColor))),
      ],
    ),
  );
}

Widget _imagePicker(BuildContext context, StockInViewModel vm) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Upload Image',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => _pickProductImage(context, vm),
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

Future<void> _pickDate(BuildContext context, StockInViewModel vm) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: vm.selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  if (picked != null) vm.pickDate(picked);
}

Future<void> _pickProductImage(
  BuildContext context,
  StockInViewModel vm,
) async {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              onPressed: () {
                vm.pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              onPressed: () {
                vm.pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
