import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dswd_slp/core/app_colors.dart';
import '../../models/product_model.dart';
import '../../view_models/record_sales_view_model.dart';
import '../widgets/header.dart';

class RecordSalesScreen extends ConsumerStatefulWidget {
  const RecordSalesScreen({super.key});

  @override
  ConsumerState<RecordSalesScreen> createState() => _RecordSalesScreenState();
}

class _RecordSalesScreenState extends ConsumerState<RecordSalesScreen> {
  bool isCash = true;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final vm = ref.read(salesViewModelProvider);
    vm.resetQuantities();
    vm.reloadProducts();
  });
}


  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(salesViewModelProvider); // triggers SalesViewModel

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Halin', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cashUtangSwitch(vm),
                            const SizedBox(height: 16),
                            _searchBar(vm),
                            const SizedBox(height: 12),
                            _categoryChips(vm),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: isCash
                            ? _cashList(vm)
                            : _utangList(), // scrollable list
                      ),
                    ],
                  ),
          ),
          _bottomBar(vm),
        ],
      ),
    );
  }

  Widget _cashUtangSwitch(SalesViewModel vm) => Row(
  children: [
    _switchButton("Cash", isCash, () {
      setState(() => isCash = true);
      vm.resetQuantities();  // <-- reset quantities here
      vm.reloadProducts();
    }),
    const SizedBox(width: 10),
    _switchButton("Utang", !isCash, () {
      setState(() => isCash = false);
      vm.resetQuantities();  // <-- also reset here
    }),
  ],
);

  Widget _switchButton(String title, bool active, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );

  Widget _cashList(SalesViewModel vm) {
    final displayedProducts = vm.filteredProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (displayedProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No products found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayedProducts.length,
      itemBuilder: (context, index) {
        final product = displayedProducts[index];
        return _productCard(product, vm);
      },
    );
  }

  Widget _utangList() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dueDateCard(),
        const SizedBox(height: 12),
        _customerInput(),
        const SizedBox(height: 12),
        _customerItem("Drake Kan", 900),
        const SizedBox(height: 8),
        _customerItem("Kiel Fen", 1000),
      ],
    ),
  );

  Widget _searchBar(SalesViewModel vm) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(51),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() => searchQuery = value);
      },
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: "Search products",
        icon: Icon(Icons.search, size: 22, color: Colors.black),
        hintStyle: TextStyle(color: Colors.black),
        contentPadding: EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  Widget _categoryChips(SalesViewModel vm) => SizedBox(
    height: 50,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 0, right: 8),
      itemCount: SalesViewModel.categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final selected = index == vm.selectedCategoryIndex;
        return GestureDetector(
          onTap: () => vm.selectCategory(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              SalesViewModel.categories[index],
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _productCard(ProductModel product, SalesViewModel vm) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(51),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        _productImage(product),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "Price: ₱${product.sellingPrice}",
                style: const TextStyle(color: Colors.black87),
              ),
              Text(
                "Stock: ${product.quantity}",
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _quantitySelector(product, vm),
            const SizedBox(height: 6),
            Text(
              "Subtotal: ₱${vm.getSubtotal(product)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _productImage(ProductModel product) {
    if (product.image == null || product.image!.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 30,
          color: Colors.grey,
        ),
      );
    }
    return Image.file(
      File(product.image!),
      width: 60,
      height: 60,
      fit: BoxFit.cover,
    );
  }

Widget _quantitySelector(ProductModel product, SalesViewModel vm) {
  final controller = vm.controllers[product.id!]!;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[400]!),
      borderRadius: BorderRadius.circular(50),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () {
            vm.decrementQuantity(product);
          },
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 40,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  int qty = int.tryParse(value) ?? 0;
                  vm.updateQuantity(product, qty);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              );
            },
          ),
        ),
        IconButton(
          onPressed: () {
            vm.incrementQuantity(product);
          },
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    ),
  );
}






// ADDING SHOW SUMMARY FOR ALL PRODUCTS #kevin 01-20-26
void _showSummary(BuildContext context, SalesViewModel vm) {
  final selectedProducts = vm.products.where((p) {
    final id = p.id;
    if (id == null) return false;
    return (vm.productQuantities[id] ?? 0) > 0;
  }).toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Sale Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Expanded list of selected products
                Expanded(
                  child: selectedProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No products selected',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: selectedProducts.length,
                          itemBuilder: (_, index) {
                            final product = selectedProducts[index];
                            final qty = vm.getQuantity(product);
                            final subtotal = vm.getSubtotal(product);

                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text('₱${product.sellingPrice} × $qty'),
                              trailing: Text(
                                '₱${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₱${vm.total}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Cancel & Confirm buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the summary modal

                          if (isCash) {
                            // Handle cash sale
                            vm.checkout();        // Save the sale
                            vm.resetQuantities(); // Reset quantities

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Sale successfully recorded!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.success, // <-- use your success color here
                              ),
                            );
                          } else {
                            // Handle utang flow (if needed)
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // <-- Confirm button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Widget _dueDateCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: const [
        Expanded(
          child: Text(
            "Due Date: November 30, 2025",
            style: TextStyle(fontSize: 16),
          ),
        ),
        Icon(Icons.calendar_month, size: 24, color: Colors.grey),
      ],
    ),
  );

  Widget _customerInput() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: const [
        Expanded(child: Text("Customer Name", style: TextStyle(fontSize: 16))),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.add, size: 18, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _customerItem(String name, double limit) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text("Limit: ₱$limit", style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _bottomBar(SalesViewModel vm) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
    ],
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total: ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: "₱${vm.total}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: vm.hasSelectedProducts
              ? () => _showSummary(context, vm)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            isCash ? "Record" : "Continue",
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    ],
  ),
);


}
