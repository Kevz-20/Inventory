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

  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? dueDate;

  void _updateArrowVisibility() {
    if (!_categoryScrollController.hasClients) return;
    final position = _categoryScrollController.position;

    setState(() {
      _showLeftArrow = position.pixels > 0;
      _showRightArrow = position.pixels < position.maxScrollExtent;
    });
  }

  @override
  void initState() {
    super.initState();

    _categoryScrollController.addListener(_updateArrowVisibility);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(salesViewModelProvider);
      vm.resetQuantities();
      vm.loadProducts();

      // Initial arrow check
      _updateArrowVisibility();
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

                            const SizedBox(height: 16),
                            _searchBar(vm),
                            const SizedBox(height: 12),
                            _categoryChips(vm),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
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

  Widget _cashUtangSwitch(SalesViewModel vm) => Row(
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
      const SizedBox(width: 10),
      _switchButton("Utang", !isCash, () {
        setState(() {
          isCash = false;
          isProductMode = false;
        });
        vm.resetQuantities();
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

  Widget _searchBar(SalesViewModel vm) {
    if (isCash || (!isCash && isProductMode)) {
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
                  setState(() {
                    searchQuery = value;
                    isProductMode = false;
                  });
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

  // ------------------------- CATEGORY CHIPS WITH ARROWS -------------------------

  Widget _categoryChips(SalesViewModel vm) {
    if (!isCash) return const SizedBox.shrink();

    const arrowWidth = 10.0;
    const chipHeight = 40.0;
    const chipFontSize = 15.0;

    return SizedBox(
      height: chipHeight,
      child: Row(
        children: [
          // Left arrow
          SizedBox(
            width: arrowWidth,
            child: _showLeftArrow
                ? IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      _categoryScrollController.animateTo(
                        (_categoryScrollController.offset - 120).clamp(
                          0.0,
                          _categoryScrollController.position.maxScrollExtent,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),

          // Categories
          Expanded(
            child: ListView.separated(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: SalesViewModel.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == vm.selectedCategoryIndex;

                return GestureDetector(
                  onTap: () => vm.selectCategory(index),
                  child: Container(
                    height: chipHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        fontSize: chipFontSize,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Right arrow
          SizedBox(
            width: arrowWidth,
            child: _showRightArrow
                ? IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      _categoryScrollController.animateTo(
                        (_categoryScrollController.offset + 120).clamp(
                          0.0,
                          _categoryScrollController.position.maxScrollExtent,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
      final filteredCustomers = vm.customers.where((customer) {
        final name = '${customer['first_name']} ${customer['last_name']}';
        return name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10,
        ), // 👈 very small bottom only
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dueDateCard(),
            const SizedBox(height: 4), // 👈 reduced from 12
            if (filteredCustomers.isNotEmpty)
              ...filteredCustomers.map(
                (customer) => _customerItem(
                  customer,
                ), // 👈 removed extra Column + SizedBox
              )
            else
              const Center(
                child: Text(
                  "No customers found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // Product selection after customer is picked
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _searchBar(vm),
                const SizedBox(height: 12),
                _categoryChips(vm),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _productList(vm)),
        ],
      );
    }
  }

  Widget _dueDateCard() {
    final isSelected = dueDate != null;

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: dueDate ?? now,
          firstDate: now,
          lastDate: DateTime(now.year + 5),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary, // header + selected date
                  onPrimary: Colors.white, // text on selected date
                  onSurface: AppColors.textPrimary, // calendar text
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: Colors.grey.shade100,
                ),
                datePickerTheme: DatePickerThemeData(
                  todayForegroundColor: MaterialStateProperty.all(
                    AppColors.primary,
                  ),
                  todayBorder: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          setState(() => dueDate = pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14), // slightly tighter
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1, // thinner = cleaner
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25), // green glow
                    blurRadius: 6,
                    spreadRadius: 1, // 👈 glow outside, not spacing
                    offset: Offset.zero, // 👈 no downward gap
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: isSelected ? AppColors.primary : Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSelected
                    ? "Due Date: ${dueDate!.month}/${dueDate!.day}/${dueDate!.year}"
                    : "Select Due Date",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.black54,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _customerItem(Map<String, dynamic> customer) {
    final vm = ref.read(salesViewModelProvider);

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
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
              child: Text(
                "${customer['first_name']} ${customer['last_name']}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
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
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final selectedCustomer = vm.selectedCustomer;

                            if (!isCash &&
                                (selectedCustomer == null || dueDate == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a customer and due date for utang.',
                                  ),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (!isCash && selectedProducts.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select at least one product for utang.',
                                  ),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context);

                            try {
                              if (isCash) {
                                await vm.checkout();
                              } else {
                                await vm.checkout(
                                  isCash: false,
                                  customerId: selectedCustomer!['id'],
                                  dueDate: dueDate!,
                                );
                              }

                              vm.resetQuantities();
                              vm.selectedCustomer = null;
                              dueDate = null;
                              isProductMode = false;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Sale successfully recorded!',
                                  ),
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
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
