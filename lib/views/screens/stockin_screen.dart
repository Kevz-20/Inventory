import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  final TextEditingController productController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  int currentIndex = 0;

  final List<String> categories = ['Fruits', 'Vegetables', 'Snacks', 'Drinks'];

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Stock In'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InkWell(
              onTap: _pickDate,
              child: _inputRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value:
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
            ),
            const SizedBox(height: 15),

            _inputDropdown(
              icon: Icons.category,
              label: 'Category',
              value: selectedCategory,
              items: categories,
              onChanged: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 15),

            _inputTextField(
              icon: Icons.edit,
              label: 'Pangalan sa produkto',
              controller: productController,
            ),
            const SizedBox(height: 15),

            _inputTextField(
              icon: Icons.attach_money,
              label: 'Presyo sa pagpalit',
              controller: purchasePriceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            _inputTextField(
              icon: Icons.calculate,
              label: 'Presyo sa pagbaligya',
              controller: sellingPriceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            _inputTextField(
              icon: Icons.shopping_cart,
              label: 'Gidaghanon',
              controller: quantityController,
              keyboardType: TextInputType.number,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _inputDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary),
          labelText: label,
          border: InputBorder.none,
        ),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _inputTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
