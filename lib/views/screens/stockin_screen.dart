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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================== CARD: BASIC INFO =====================
            _card(
              child: Column(
                children: [
                  _inputDate(vm),
                  const SizedBox(height: 12),
                  _inputDropdown(
                    icon: Icons.category,
                    label: 'Kategorya',
                    value: vm.selectedCategory,
                    items: vm.categories,
                    showError: vm.showValidationErrors,
                    onChanged: vm.setCategory,
                  ),
                  const SizedBox(height: 12),
                  _autocompleteProduct(vm),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===================== CARD: PRICING & QUANTITY =====================
            _card(
              child: Column(
                children: [
                  _inputNumberField(
                    label: 'Presyo sa pagpalit',
                    controller: vm.purchasePriceController,
                    showError: vm.showValidationErrors,
                    isPeso: true,
                  ),
                  const SizedBox(height: 12),
                  _inputNumberField(
                    label: 'Presyo sa pagbaligya',
                    controller: vm.sellingPriceController,
                    showError: vm.showValidationErrors,
                    isPeso: true,
                  ),
                  const SizedBox(height: 12),
                  _inputNumberField(
                    label: 'Gidaghanon',
                    controller: vm.quantityController,
                    showError: vm.showValidationErrors,
                    icon: Icons.shopping_cart_rounded,
                    isPeso: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===================== CARD: IMAGE =====================
            _sectionCard(
              title: "Product Image (Opsyonal)",
              icon: Icons.camera_alt_rounded,
              child: _imagePicker(vm, context),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),

      // ===================== BOTTOM BUTTON =====================
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
                  : () {
                      vm.triggerValidation();
                      vm.saveProduct(context); // ✅ same functionality
                    },
              child: vm.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }

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

  // ===================== UI HELPERS =====================

  Widget _card({required Widget child}) {
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

  // ✅ ONLY UPDATED PART: no TextEditingController created on rebuild
  Widget _inputDate(StockInViewModel vm) {
    return SizedBox(
      height: 58,
      child: TextFormField(
        readOnly: true,
        initialValue: vm.formattedDate,
        onTap: () async {
          final today = DateTime.now();
          final initialDate =
              vm.selectedDate.isAfter(today) ? today : vm.selectedDate;

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
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
          labelText: 'Date',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
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

    return SizedBox(
      height: 58,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isError ? Colors.red : Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: isError ? Colors.red : AppColors.primary),
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
      ),
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
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
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
                          horizontal: 14, vertical: 14),
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
          height: 58,
          child: TextField(
            controller: fieldController,
            focusNode: focusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Pangalan sa produkto',
              prefixIcon: const Icon(Icons.edit, color: AppColors.primary),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: (vm.showValidationErrors &&
                          vm.effectiveProductName.trim().isEmpty)
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: (vm.showValidationErrors &&
                          vm.effectiveProductName.trim().isEmpty)
                      ? Colors.red
                      : AppColors.primary,
                ),
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
      height: 58,
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
          fillColor: Colors.grey.shade50,
          prefixIcon: isPeso
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
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
                  : Colors.grey.shade300,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.photo_library,
                    size: 28,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    "Gallery",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    vm.pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 28,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    "Camera",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
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
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade50,
            ),
            child: vm.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      vm.productImage!,
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
                        "Tap para mag add og product image",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pickImage,
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
                onPressed: vm.productImage == null ? null : vm.removeImage,
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