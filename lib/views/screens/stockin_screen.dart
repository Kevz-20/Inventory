import 'dart:io';

import 'package:flutter/material.dart';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Stock In', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (vm.successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.successMessage!,
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            if (vm.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
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
              optionsBuilder: (TextEditingValue value) {
                if (value.text.isEmpty) return const Iterable<String>.empty();

                return vm.productNames.where(
                  (name) =>
                      name.toLowerCase().contains(value.text.toLowerCase()),
                );
              },
              displayStringForOption: (option) => option,
              fieldViewBuilder:
                  (context, fieldController, focusNode, onSubmit) {
                    vm.autocompleteFieldController = fieldController;

                    final bool isError =
                        vm.showValidationErrors && fieldController.text.isEmpty;

                    return SizedBox(
                      height: 60,
                      child: TextField(
                        controller: fieldController,
                        focusNode: focusNode,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.edit,
                            color: AppColors.primary,
                          ),
                          labelText: 'Pangalan sa produkto',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
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
                              color: isError ? Colors.red : AppColors.primary,
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
                final product = vm.allProducts.firstWhere(
                  (p) => p.name == value,
                );
                vm.selectedProduct = product;

                vm.productController.text = product.name;
                vm.setCategory(product.category);
                vm.purchasePriceController.text = product.purchasePrice
                    .toString();
                vm.sellingPriceController.text = product.sellingPrice
                    .toString();
                vm.quantityController.text = product.quantity.toString();
                vm.productImage = product.image != null
                    ? File(product.image!)
                    : null;
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            _inputTextField(
              prefix: SizedBox(
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
              label: 'Presyo sa pagpalit',
              controller: vm.purchasePriceController,
              showError: vm.showValidationErrors,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _inputTextField(
              prefix: const Icon(Icons.calculate, color: AppColors.primary),
              label: 'Presyo sa pagbaligya',
              controller: vm.sellingPriceController,
              showError: vm.showValidationErrors,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _inputTextField(
              prefix: const Icon(Icons.shopping_cart, color: AppColors.primary),
              label: 'Gidaghanon',
              controller: vm.quantityController,
              showError: vm.showValidationErrors,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Upload Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _pickProductImage(context, vm),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: vm.productImage != null
                        ? Image.file(vm.productImage!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ],
            ),
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

  Future<void> _pickDate(BuildContext context, StockInViewModel vm) async {
    final DateTime? picked = await showDatePicker(
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
    if (picked != null && picked != vm.selectedDate) vm.pickDate(picked);
  }

  Future<void> _pickProductImage(
    BuildContext context,
    StockInViewModel vm,
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
                  vm.pickImage(ImageSource.gallery);
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
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
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
            borderSide: BorderSide(color: AppColors.primary, width: 1.2),
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
    required void Function(String?) onChanged,
    required bool showError,
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
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _inputTextField({
    Widget? prefix,
    required String label,
    required TextEditingController controller,
    required bool showError,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isError = showError && controller.text.isEmpty;

    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textPrimary,
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
}
