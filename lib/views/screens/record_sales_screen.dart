// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dswd_slp/core/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../view_models/record_sales_view_model.dart';
import '../widgets/header.dart';
import 'package:intl/intl.dart';

class RecordSalesScreen extends ConsumerStatefulWidget {
  const RecordSalesScreen({super.key});

  @override
  ConsumerState<RecordSalesScreen> createState() => _RecordSalesScreenState();
}

final currencyFormatter = NumberFormat.currency(
  locale: 'en_PH', // Philippine locale
  symbol: '₱', // Peso symbol
  decimalDigits: 2, // show 2 decimal places
);

class _RecordSalesScreenState extends ConsumerState<RecordSalesScreen> {
  bool isCash = true;
  bool isProductMode = false;

  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
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
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(salesViewModelProvider);

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

                            if (!isCash && vm.selectedCustomer != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  width: double.infinity,
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Customer: ${vm.selectedCustomer!['first_name']} ${vm.selectedCustomer!['last_name']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Due Date: ${dueDate != null ? "${dueDate!.month}/${dueDate!.day}/${dueDate!.year}" : "Not selected"}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            _searchBar(vm),
                            const SizedBox(height: 8),
                            _categoryChips(vm),
                          ],
                        ),
                      ),
                      Expanded(
                        child: isCash || isProductMode
                            ? _productList(vm)
                            : _utangList(),
                      ),
                    ],
                  ),
          ),
          _bottomBar(vm),
        ],
      ),
    );
  }

  // ---------------------------- Helper Widgets ----------------------------

  Widget _cashUtangSwitch(SalesViewModel vm) {
  final double toggleWidth = MediaQuery.of(context).size.width - 32; // account for horizontal padding
  final double sliderWidth = toggleWidth / 2;

  return Container(
    height: 50,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.grey.shade300.withOpacity(0.3),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Stack(
      children: [
        // 🔹 Sliding background pill
        AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: isCash ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: sliderWidth,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),

        // 🔹 Toggle buttons
        Row(
          children: [
            _switchButton("Cash", isCash, () {
              setState(() {
                isCash = true;
                isProductMode = false;
                vm.selectedCustomer = null;
                dueDate = null;
              });
              vm.resetQuantities();
              vm.loadProducts();
            }),
            _switchButton("Utang", !isCash, () {
              setState(() {
                isCash = false;
                isProductMode = false;
              });
              vm.resetQuantities();
            }),
          ],
        ),
      ],
    ),
  );
}

  Widget _switchButton(String title, bool active, VoidCallback onTap) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          child: Text(title),
        ),
      ),
    ),
  );
}

  Widget _searchBar(SalesViewModel vm) {
    const double height = 55;

    BoxDecoration boxDecoration(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade400, width: 1),
    );

    InputDecoration inputDecoration(
      String hint,
      IconData icon,
      TextEditingController controller,
      VoidCallback onClear,
    ) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, size: 22, color: Colors.black),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      suffixIcon: controller.text.isNotEmpty
          ? GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.clear, size: 22, color: Colors.black54),
            )
          : null,
    );

    if (isCash || (!isCash && isProductMode)) {
      return Container(
        height: height,
        decoration: boxDecoration(Colors.white),
        alignment: Alignment.center,
        child: TextField(
          controller: searchController,
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: inputDecoration(
            "Search products",
            Icons.search,
            searchController,
            () {
              setState(() {
                searchController.clear();
                searchQuery = '';
              });
            },
          ),
          textAlignVertical: TextAlignVertical.center,
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: height,
              decoration: boxDecoration(Colors.white),
              alignment: Alignment.center,
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    isProductMode = false;
                  });
                },
                decoration: inputDecoration(
                  "Search customer",
                  Icons.person,
                  searchController,
                  () {
                    setState(() {
                      searchController.clear();
                      searchQuery = '';
                    });
                  },
                ),
                textAlignVertical: TextAlignVertical.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final result = await context.push<bool>('/new_customer');
              if (result == true) {
                final vm = ref.read(salesViewModelProvider);
                await vm.loadCustomers();
                setState(() {
                  searchController.clear();
                  searchQuery = '';
                });
              }
            },
            child: Container(
              height: height,
              width: height,
              alignment: Alignment.center,
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

  // Category Chips
  Widget _categoryChips(SalesViewModel vm) {
    if (!isCash) return const SizedBox.shrink();

    const chipHeight = 45.0;
    const chipFontSize = 15.0;
    const chipRadius = 24.0;
    const verticalPadding = 4.0;
    const dotSize = 6.0;
    const dotSpacing = 6.0;

    final totalCategories = SalesViewModel.categories.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chips
        SizedBox(
          height: chipHeight + verticalPadding * 2,
          child: ListView.separated(
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: chipRadius),
            itemCount: totalCategories,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == vm.selectedCategoryIndex;
              return GestureDetector(
                onTap: () => vm.selectCategory(index),
                child: Container(
                  height: chipHeight,
                  margin: EdgeInsets.symmetric(vertical: verticalPadding),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(chipRadius),
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
                      fontSize: chipFontSize,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalCategories, (index) {
            final selected = index == vm.selectedCategoryIndex;
            return Container(
              width: dotSize,
              height: dotSize,
              margin: EdgeInsets.symmetric(horizontal: dotSpacing / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.grey.shade400 : Colors.grey.shade400,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _productList(SalesViewModel vm) {
    final displayedProducts = vm.filteredProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (displayedProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No products found',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayedProducts.length,
      itemBuilder: (context, index) =>
          _productCard(displayedProducts[index], vm),
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
                "Price: ${currencyFormatter.format(product.sellingPrice)}",
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
              "Subtotal: ${currencyFormatter.format(vm.getSubtotal(product))}",
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
            onPressed: () => vm.decrementQuantity(product),
            icon: const Icon(Icons.remove, size: 18),
          ),
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 40, // minimum width (same as before)
                maxWidth: 80, // optional cap so it doesn’t get crazy wide
              ),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (text) {
                  int qty = int.tryParse(text) ?? 0;
                  qty = qty.clamp(0, product.quantity);
                  if (controller.text != qty.toString()) {
                    controller.text = qty.toString();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                  vm.productQuantities[product.id!] = qty;
                  vm.calculateTotal();
                },
              ),
            ),
          ),
          IconButton(
            onPressed: () => vm.incrementQuantity(product),
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _utangList() {
  final vm = ref.watch(salesViewModelProvider);

  if (!isProductMode) {
    // Filter customers by search query
    final filteredCustomers = vm.customers.where((customer) {
      final name = '${customer['first_name']} ${customer['last_name']}';
      return name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _dueDateCard(),
          const SizedBox(height: 4),
          if (filteredCustomers.isNotEmpty)
            ...filteredCustomers.map((customer) => _customerItem(customer))
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No customers found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  } else {
    // When a customer is selected, show products for credit sale
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${vm.selectedCustomer?['first_name']} ${vm.selectedCustomer?['last_name']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Due Date: ${dueDate != null ? "${dueDate!.month}/${dueDate!.day}/${dueDate!.year}" : "Not selected"}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _searchBar(vm),
              const SizedBox(height: 6),
              _categoryChips(vm),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _productList(vm)),
      ],
    );
  }
}

Widget _customerItem(Map<String, dynamic> customer) {
  final vm = ref.read(salesViewModelProvider);

  // ✅ Correctly get available credit from DB field
  final double availableCredit = (customer['available_credit'] ?? 1000.0) as double;

  return GestureDetector(
    onTap: () {
      if (dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a due date first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        vm.selectedCustomer = customer;
        isProductMode = true;
        searchController.clear();
        searchQuery = '';
      });
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${customer['first_name']} ${customer['last_name']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available Credit: ₱${availableCredit.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}


  Widget _dueDateCard() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: dueDate ?? now,
          firstDate: now,
          lastDate: DateTime(now.year + 5),
          initialDatePickerMode: DatePickerMode.day,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.grey.shade100,
              ),
            ),
            child: child!,
          ),
        );

        if (pickedDate != null) {
          setState(() => dueDate = pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade400, // same as search bar
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dueDate != null
                    ? "Due Date: ${DateFormat('MMMM d, y').format(dueDate!)}"
                    : "Select Due Date",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(SalesViewModel vm) {
    final bool canCheckout = vm.hasSelectedProducts;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: canCheckout ? () => _showSummary(context, vm) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCheckout
                    ? AppColors.primary
                    : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: canCheckout ? 2 : 0,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Checkout", style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSummary(BuildContext context, SalesViewModel vm) {
    final selectedProducts = vm.products.where((p) {
      final id = p.id;
      if (id == null) return false;
      return (vm.productQuantities[id] ?? 0) > 0;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Sale Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: selectedProducts.isEmpty
                        ? const Center(
                            child: Text(
                              'No products selected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedProducts.length,
                            itemBuilder: (_, index) {
                              final product = selectedProducts[index];
                              final qty = vm.getQuantity(product);
                              final subtotal = vm.getSubtotal(product);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold, // 🔥 BOLD PRODUCT
                                    fontSize: 17,
                                  ),
                                ),
                                subtitle: Text(
                                  '₱${product.sellingPrice} × $qty',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                                trailing: Text(
                                  currencyFormatter.format(subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(vm.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final selectedCustomer = vm.selectedCustomer;

                                  // If Utang, validate customer and due date
                                  if (!isCash) {
                                    if (selectedCustomer == null || dueDate == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select a customer and due date for utang.'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Ensure at least one product is selected
                                    if (selectedProducts.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select at least one product for utang.'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // --- NEW: Credit limit check centralized (optional if ViewModel handles it) ---
                                    final double totalSale = vm.total;
                                    final double creditLimit = (selectedCustomer['credit_limit'] ?? 0.0) as double;
                                    final double currentBalance = (selectedCustomer['current_balance'] ?? 0.0) as double;
                                    final double availableCredit = creditLimit - currentBalance;

                                    if (totalSale > availableCredit) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Customer\'s available credit is ₱${availableCredit.toStringAsFixed(2)}. '
                                            'You cannot exceed this limit.',
                                          ),
                                          duration: const Duration(seconds: 3),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  // Close summary sheet
                                  Navigator.pop(context);

                                  try {
                                    // Checkout
                                    if (isCash) {
                                      await vm.checkout(); // Cash checkout
                                    } else {
                                      await vm.checkout(
                                        isCash: false,
                                        customerId: selectedCustomer!['id'],
                                        dueDate: dueDate!,
                                      );
                                    }

                                    // Reload customers to refresh available credit after checkout
                                    await vm.loadCustomers();

                                    // Reset UI & state
                                    vm.resetQuantities();
                                    vm.selectedCustomer = null;
                                    dueDate = null;
                                    isProductMode = false;
                                    searchController.clear();
                                    searchQuery = '';

                                    // Success message
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
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
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
}
