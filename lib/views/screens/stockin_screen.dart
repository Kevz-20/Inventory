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

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

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
              icon: Icons.currency_rupee,
              isPeso: true,
            ),
            const SizedBox(height: 15),
            _inputNumberField(
              label: 'Presyo sa pagbaligya',
              controller: vm.sellingPriceController,
              showError: vm.showValidationErrors,
              icon: Icons.currency_rupee,
              isPeso: true,
            ),
            const SizedBox(height: 15),
            _inputNumberField(
              label: 'Gidaghanon',
              controller: vm.quantityController,
              showError: vm.showValidationErrors,
              icon: Icons.shopping_cart,
            ),
            const SizedBox(height: 15),
            _imagePicker(vm, context),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
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
                  vm.saveProduct(context); // ✅ pass context
                },
          child: vm.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _inputDate(StockInViewModel vm) {
    return SizedBox(
      height: 60,
      child: TextField(
        readOnly: true,
        onTap: () async {
          final today = DateTime.now();
          final initialDate = vm.selectedDate.isAfter(today)
              ? today
              : vm.selectedDate;

          final picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2020),
            lastDate: today,
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            ),
          );

          if (picked != null) vm.pickDate(picked);
        },
        controller: TextEditingController(text: vm.formattedDate),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(
            Icons.calendar_today,
            color: AppColors.primary,
          ),
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
          borderSide: BorderSide(
            color: isError ? Colors.red : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isError ? Colors.red : AppColors.primary,
          ),
        ),
      ),
      dropdownColor: Colors.white,
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

  Widget _autocompleteProduct(StockInViewModel vm) {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        return vm.productNames.where(
          (name) => name.toLowerCase().startsWith(value.text.toLowerCase()),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      await Future.delayed(const Duration(milliseconds: 50));
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
      fieldViewBuilder: (context, fieldController, focusNode, onSubmit) {
        vm.autocompleteFieldController = fieldController;

        return SizedBox(
          height: 60,
          child: TextField(
            controller: fieldController,
            focusNode: focusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Pangalan sa produkto',
              prefixIcon: const Icon(Icons.edit, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (value) {
              vm.productController.text = value;
              if (vm.selectedProduct != null &&
                  vm.selectedProduct!.name.toLowerCase() !=
                      value.toLowerCase()) {
                vm.selectedProduct = null;
              }
            },
          ),
        );
      },
      onSelected: (value) async {
        final product = vm.allProducts.firstWhere((p) => p.name == value);
        vm.selectedProduct = product;

        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 50));

        vm.productController.text = product.name;
        vm.autocompleteFieldController?.text = product.name;

        vm.setCategory(product.category);
        vm.purchasePriceController.text = product.purchasePrice.toString();
        vm.sellingPriceController.text = product.sellingPrice.toString();
        vm.quantityController.text = product.quantity.toString();
        vm.productImage = product.image != null ? File(product.image!) : null;
      },
    );
  }

  Widget _inputNumberField({
    required String label,
    required TextEditingController controller,
    required bool showError,
    IconData? icon,
    bool isPeso = false,
  }) {
    final allowDecimal = isPeso;

    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: allowDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          if (allowDecimal) ...[
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            DecimalThousandsSeparatorInputFormatter(),
          ] else ...[
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorInputFormatter(),
          ],
        ],
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: isPeso
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : icon != null
              ? Icon(icon, color: AppColors.primary)
              : null,
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: showError && controller.text.isEmpty
                  ? Colors.red
                  : Colors.grey.shade400,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: showError && controller.text.isEmpty
                  ? Colors.red
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker(StockInViewModel vm, BuildContext context) {
    Future<void> pickImage() async {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            clipBehavior: Clip.hardEdge,
            child: vm.productImage != null
                ? Image.file(vm.productImage!, fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                  ),
          ),
        ),
        if (vm.productImage != null)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                  label: const Text(
                    'Retake',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton.icon(
                  onPressed: vm.removeImage,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ----------------- Thousands Separator Formatters -----------------
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(',', '');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;
    if (text.isEmpty) return const TextEditingValue();

    final parts = text.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    String formattedInt = '';
    if (intPart.isNotEmpty) {
      final chars = intPart.split('').reversed.toList();
      final chunks = <String>[];
      for (var i = 0; i < chars.length; i += 3) {
        chunks.add(chars.skip(i).take(3).join());
      }
      formattedInt = chunks
          .map((e) => e.split('').reversed.join())
          .toList()
          .reversed
          .join(',');
    }

    final result = '$formattedInt$decPart';
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class DecimalThousandsSeparatorInputFormatter extends TextInputFormatter {
  final RegExp _amountPattern = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return const TextEditingValue();
    if (!_amountPattern.hasMatch(raw)) return oldValue;

    final hasDot = raw.contains('.');
    final parts = raw.split('.');
    final intPartRaw = parts.first;
    final fracPart = hasDot ? (parts.length > 1 ? parts[1] : '') : '';

    final formattedInt = _formatIntegerWithComma(intPartRaw);
    final formatted = hasDot ? '$formattedInt.$fracPart' : formattedInt;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _formatIntegerWithComma(String digits) {
  if (digits.isEmpty) return '';
  final chars = digits.split('').reversed.toList();
  final chunks = <String>[];
  for (var i = 0; i < chars.length; i += 3) {
    chunks.add(chars.skip(i).take(3).join());
  }
  return chunks
      .map((e) => e.split('').reversed.join())
      .toList()
      .reversed
      .join(',');
}
