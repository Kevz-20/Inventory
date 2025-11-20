import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../view_models/stock_in_view_model.dart';
import '../widgets/header.dart';

class StockInScreen extends ConsumerWidget {
  const StockInScreen({super.key});

  Future<void> _pickDate(BuildContext context, StockInViewModel vm) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != vm.selectedDate) {
      vm.pickDate(picked);
    }
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(stockInViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Stock In', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InkWell(
              onTap: () => _pickDate(context, vm),
              child: _inputRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: vm.formattedDate,
              ),
            ),
            const SizedBox(height: 15),
            _inputDropdown(
              icon: Icons.category,
              label: 'Category',
              value: vm.selectedCategory,
              items: vm.categories,
              onChanged: vm.setCategory,
            ),
            const SizedBox(height: 15),
            _inputTextField(
              icon: Icons.edit,
              label: 'Pangalan sa produkto',
              controller: vm.productController,
            ),
            const SizedBox(height: 15),
            _inputTextField(
              icon: Icons.attach_money,
              label: 'Presyo sa pagpalit',
              controller: vm.purchasePriceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _inputTextField(
              icon: Icons.calculate,
              label: 'Presyo sa pagbaligya',
              controller: vm.sellingPriceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _inputTextField(
              icon: Icons.shopping_cart,
              label: 'Gidaghanon',
              controller: vm.quantityController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
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
          onPressed: () {},
          child: const Text('Save', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _inputRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return SizedBox(
      height: 60,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label),
            Expanded(
              child: Center(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
  }) {
    return SizedBox(
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 1.2),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            labelText: label,
            border: InputBorder.none,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _inputTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
            borderSide: BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}
