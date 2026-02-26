// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dswd_slp/core/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../app_router.dart';
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
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);

class _RecordSalesScreenState extends ConsumerState<RecordSalesScreen>
    with RouteAware {
  bool isCash = true;
  bool isProductMode = false;

  final ScrollController _categoryScrollController = ScrollController();
  final PageController _categoryPageController = PageController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(salesViewModelProvider);
      vm.resetQuantities();

      await vm.loadCategories();
      await vm.loadProducts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() async {
    final vm = ref.read(salesViewModelProvider);

    await vm.loadCategories();
    await vm.loadProducts();
    await vm.loadCustomers();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    searchController.dispose();
    _categoryScrollController.dispose();
    _categoryPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(salesViewModelProvider);

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

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

                            // ✅ Utang: Step guide + selected customer card
                            if (!isCash) ...[
                              const SizedBox(height: 10),
                              Text(
                                isProductMode
                                    ? "Step 3: Add products for utang"
                                    : "Step 1: Select Due Date • Step 2: Choose Customer",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                            ],

                            if (!isCash && vm.selectedCustomer != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
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
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Due Date: ${dueDate != null ? "${dueDate!.month}/${dueDate!.day}/${dueDate!.year}" : "Not selected"}',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: Colors.black.withOpacity(0.55),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            _searchBar(vm),

                            const SizedBox(height: 10),

                            if (isCash || (!isCash && isProductMode)) ...[
                             
                              const SizedBox(height: 8),
                              _categoryChips(vm),
                            ],
                          ],
                        ),
                      ),

                      Expanded(
                        child: isCash || isProductMode
                            ? _categoryProductView(vm)
                            : _utangList(),
                      ),
                    ],
                  ),
          ),

          // ✅ Upgraded bottom bar (items + total + checkout)
          _bottomBar(vm, bottomPadding),
        ],
      ),
    );
  }

  // ---------------------------- Helper Widgets ----------------------------

  Widget _cashUtangSwitch(SalesViewModel vm) {
    final double toggleWidth = MediaQuery.of(context).size.width - 32;
    final double sliderWidth = toggleWidth / 2;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
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
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),

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
                vm.loadCustomers();
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
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.2,
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
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        );

    InputDecoration inputDecoration(
      String hint,
      IconData icon,
      TextEditingController controller,
      VoidCallback onClear,
    ) =>
        InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
          prefixIcon: Icon(icon, size: 22, color: Colors.black87),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.clear,
                      size: 22, color: Colors.black54),
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
          const SizedBox(width: 10),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      );
    }
  }

  // ✅ Category Chips (better contrast + border)
  Widget _categoryChips(SalesViewModel vm) {
    if (!isCash && !isProductMode) return const SizedBox.shrink();

    const chipHeight = 45.0;
    const chipFontSize = 15.0;
    const chipRadius = 24.0;
    const verticalPadding = 4.0;
    const dotSize = 6.0;
    const dotSpacing = 6.0;

    final totalCategories = vm.categoryNames.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: chipHeight + verticalPadding * 2,
          child: ListView.separated(
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: totalCategories,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == vm.selectedCategoryIndex;

              return GestureDetector(
                onTap: () {
                  vm.selectCategory(index);
                  _categoryPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  height: chipHeight,
                  margin: EdgeInsets.symmetric(vertical: verticalPadding),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(chipRadius),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    vm.categoryNames[index],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: chipFontSize,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalCategories, (index) {
            final selected = index == vm.selectedCategoryIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? dotSize + 2 : dotSize,
              height: dotSize,
              margin: EdgeInsets.symmetric(horizontal: dotSpacing / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.grey.shade400,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ✅ Category PageView (unchanged behavior)
  Widget _categoryProductView(SalesViewModel vm) {
    return PageView.builder(
      controller: _categoryPageController,
      itemCount: vm.categoryNames.length,
      onPageChanged: (index) {
        vm.selectCategory(index);

        final screenWidth = MediaQuery.of(context).size.width;
        final scrollTo = (index * 110) - (screenWidth / 2) + 55;

        _categoryScrollController.animateTo(
          scrollTo.clamp(0, _categoryScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
        );
      },
      itemBuilder: (context, index) {
        final query = searchQuery.toLowerCase();
        final isAll = index == 0;

        final categoryName = vm.categoryNames[index].toLowerCase();
        final categoryId = vm.categoryIdByIndex(index);

        final filteredProducts = vm.products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(query);

          if (isAll) return matchesSearch;

          final matchesId = categoryId != null && p.categoryId == categoryId;
          final matchesName = p.category.toLowerCase() == categoryName;

          return (matchesId || matchesName) && matchesSearch;
        }).toList();

        if (filteredProducts.isEmpty) {
          return Center(
            child: Text(
              "No products in this category",
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredProducts.length,
          itemBuilder: (_, i) => _productCard(filteredProducts[i], vm),
        );
      },
    );
  }

  // ---------------------------- Product List & Card ----------------------------

  Widget _productList(SalesViewModel vm) {
    final displayedProducts = vm.filteredProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (displayedProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No products found',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayedProducts.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) => _productCard(displayedProducts[index], vm),
    );
  }

  // ✅ Product card UI improved (price emphasized, stock lighter)
  Widget _productCard(ProductModel product, SalesViewModel vm) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(product.sellingPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Stock: ${product.quantity}",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _quantitySelector(product, vm),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(vm.getSubtotal(product)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Subtotal",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _productImage(ProductModel product) {
    const double size = 60;

    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 30,
        color: Colors.black.withOpacity(0.35),
      ),
    );

    if (product.image == null || product.image!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(product.image!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).toInt(),
        cacheHeight: (size * MediaQuery.devicePixelRatioOf(context)).toInt(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return placeholder;
        },
        errorBuilder: (context, _, _) => placeholder,
      ),
    );
  }

  // ✅ Quantity selector improved (no typing + bigger buttons)
  Widget _quantitySelector(ProductModel product, SalesViewModel vm) {
    final controller = vm.controllers[product.id!]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(50),
        color: Colors.white,
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => vm.decrementQuantity(product),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.remove, size: 18),
            ),
          ),
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text(
              controller.text.isEmpty ? "0" : controller.text,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => vm.incrementQuantity(product),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- Utang List (kept behavior) ----------------------------

  Widget _utangList() {
    final vm = ref.watch(salesViewModelProvider);

    if (!isProductMode) {
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
            const SizedBox(height: 8),
            if (filteredCustomers.isNotEmpty)
              ...filteredCustomers.map((customer) => _customerItem(customer))
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No customers found",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due Date: ${dueDate != null ? "${dueDate!.month}/${dueDate!.day}/${dueDate!.year}" : "Not selected"}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _searchBar(vm),
                const SizedBox(height: 10),
                _categoryChips(vm),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _productList(vm)),
        ],
      );
    }
  }

  Widget _customerItem(Map<String, dynamic> customer) {
    final vm = ref.read(salesViewModelProvider);

    final double availableCredit =
        (customer['available_credit'] ?? 1000.0) as double;

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
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.12),
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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Available Credit: ₱${availableCredit.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.45)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dueDate != null
                    ? "Due Date: ${DateFormat('MMMM d, y').format(dueDate!)}"
                    : "Select Due Date",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: Colors.black.withOpacity(0.45)),
          ],
        ),
      ),
    );
  }

  // ✅ Upgraded bottom bar: shows Items + Total + Checkout button
  Widget _bottomBar(SalesViewModel vm, double bottomPadding) {
    final bool canCheckout = vm.hasSelectedProducts;

    int itemCount = 0;
    for (final e in vm.productQuantities.entries) {
      if ((e.value) > 0) itemCount += e.value;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Items: $itemCount",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(vm.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: canCheckout ? () => _showSummary(context, vm) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canCheckout ? AppColors.primary : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: canCheckout ? 2 : 0,
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text(
                "Checkout",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
        final selectedCustomer = vm.selectedCustomer;
        final double? availableCredit = !isCash && selectedCustomer != null
            ? ((selectedCustomer['available_credit'] ?? 0.0) as num).toDouble()
            : null;
        final bool exceedsAvailableCredit =
            availableCredit != null && vm.total > availableCredit;

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ Status header
                  Text(
                    isCash ? "CASH SALE" : "UTANG SALE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isCash ? AppColors.primary : AppColors.error,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sale Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),

                  if (!isCash && selectedCustomer != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "${selectedCustomer['first_name']} ${selectedCustomer['last_name']} • "
                      "${dueDate != null ? DateFormat('MMM d, y').format(dueDate!) : 'No due date'}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 12),

                  Expanded(
                    child: selectedProducts.isEmpty
                        ? Center(
                            child: Text(
                              'No products selected',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(0.55),
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
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  '${currencyFormatter.format(product.sellingPrice)} × $qty',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withOpacity(0.55),
                                  ),
                                ),
                                trailing: Text(
                                  currencyFormatter.format(subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(vm.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  if (!isCash && availableCredit != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Credit',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(availableCredit),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (exceedsAvailableCredit) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Amount exceeds available credit. Please reduce items.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],

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
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Validate customer and due date for Utang
                            if (!isCash) {
                              if (selectedCustomer == null || dueDate == null) {
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

                              if (selectedProducts.isEmpty) {
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

                              // Credit limit check
                              final double totalSale = vm.total;
                              final double creditLimit =
                                  (selectedCustomer['credit_limit'] ?? 0.0)
                                      as double;
                              final double currentBalance =
                                  (selectedCustomer['current_balance'] ?? 0.0)
                                      as double;
                              final double availableCredit =
                                  creditLimit - currentBalance;

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

                              await vm.loadCustomers();

                              vm.resetQuantities();
                              vm.selectedCustomer = null;
                              dueDate = null;
                              isProductMode = false;
                              searchController.clear();
                              searchQuery = '';

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
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
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