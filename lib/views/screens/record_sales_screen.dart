import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dswd_slp/core/app_colors.dart';
import '../../models/product_model.dart';
import '../../view_models/record_sales_view_model.dart';
import '../widgets/header.dart';
import 'new_customer.dart';


class RecordSalesScreen extends ConsumerStatefulWidget {
  const RecordSalesScreen({super.key});

  @override
  ConsumerState<RecordSalesScreen> createState() => _RecordSalesScreenState();
}

class _RecordSalesScreenState extends ConsumerState<RecordSalesScreen> {
  bool isCash = true;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? dueDate;

  @override
  void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final vm = ref.read(salesViewModelProvider);
    vm.resetQuantities();
    vm.loadProducts();
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
      vm.loadProducts();
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

  Widget _utangList() {
  final vm = ref.watch(salesViewModelProvider);

  // Filter customers based on search query
  final filteredCustomers = vm.customers.where((customer) {
  final name = '${customer['first_name']} ${customer['last_name']}';
  return name.toLowerCase().contains(searchQuery.toLowerCase());
  }).toList();

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dueDateCard(),
        const SizedBox(height: 12),
        _customerInput(),
        const SizedBox(height: 12),
        if (filteredCustomers.isNotEmpty)
          ...filteredCustomers.map((customer) {
            return Column(
              children: [
                _customerItem(customer),
                const SizedBox(height: 8),
              ],
            );
          }).toList()
        else
          const Text(
            "No customers found",
            style: TextStyle(color: Colors.black54),
          ),
      ],
    ),
  );
}



 Widget _searchBar(SalesViewModel vm) {
  if (isCash) {
    // Normal product search
    return Container(
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
          hintText: "Search products",
          icon: Icon(Icons.search, size: 22, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
      ),
    );
  } else {
    // Utang mode: Customer search + Add button
    return Row(
      children: [
        Expanded(
          child: Container(
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
                hintText: "Search customer",
                icon: Icon(Icons.person, size: 22, color: Colors.black),
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewCustomerPage()),
            );

            if (result == true) {
              final vm = ref.read(salesViewModelProvider); // get the view model instance
              await vm.loadCustomers(); // reload customers after adding
              setState(() {
                searchController.clear(); // optional: clear search to show new customer
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}



 Widget _categoryChips(SalesViewModel vm) {
  // Hide categories if not cash
  if (!isCash) return const SizedBox.shrink();

  return SizedBox(
    height: 50,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 0, right: 8),
      itemCount: SalesViewModel.categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
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
}



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
                      '₱${vm.total.toStringAsFixed(2)}',
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
                        onPressed: () async {
                          final selectedCustomer = vm.selectedCustomer;

                          if (!isCash && (selectedCustomer == null || dueDate == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a customer and due date for utang.'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context); // Close the summary modal

                          try {
                            if (isCash) {
                              await vm.checkout();        // Cash sale
                            } else {
                              await vm.checkout(
                                isCash: false,
                                customerId: selectedCustomer!['id'],
                                dueDate: dueDate!,
                              );
                            }

                            vm.resetQuantities(); // Reset quantities
                            vm.selectedCustomer = null; // Reset selected customer
                            dueDate = null; // Reset due date
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Sale successfully recorded!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Checkout failed: $e'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // Confirm button color
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



 Widget _dueDateCard() {
  return GestureDetector(
    onTap: () async {
      final now = DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: dueDate ?? now,
        firstDate: now, // prevent past dates
        lastDate: DateTime(now.year + 5), // max 5 years ahead
      );

      if (pickedDate != null) {
        setState(() {
          dueDate = pickedDate;
        });
      }
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dueDate != null
                  ? "Due Date: ${dueDate!.month}/${dueDate!.day}/${dueDate!.year}"
                  : "Select Due Date",
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const Icon(Icons.calendar_month, size: 24, color: Colors.grey),
        ],
      ),
    ),
  );
}


 Widget _customerInput() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Text(
            "Customer Name",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}


  Widget _customerItem(Map<String, dynamic> customer) {
  final name = '${customer['first_name']} ${customer['last_name']}';
  final limit = customer['limit'] ?? 0.0;

  return GestureDetector(
  onTap: () {
    final vm = ref.read(salesViewModelProvider);
    vm.selectedCustomer = customer;

    // Switch to product selection
    setState(() {
      isCash = true; // show product list
    });
  }, // <-- COMMA ADDED HERE
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text("Limit: ₱$limit", style: const TextStyle(color: Colors.grey)),
      ],
    ),
  ),
);
}


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
            vm.selectedCustomer != null && !isCash
                ? "Continue" // still selecting customer
                : "Record Sale", // ready to record utang or cash sale
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    ],
  ),
);


}
