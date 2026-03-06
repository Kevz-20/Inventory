// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      if (!mounted) return;
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
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final vm = ref.read(salesViewModelProvider);

      await vm.loadCategories();
      await vm.loadProducts();
      await vm.loadCustomers();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    searchController.dispose();
    _categoryScrollController.dispose();
    _categoryPageController.dispose();
    super.dispose();
  }

  // ---------------------------- Responsive Helpers ----------------------------

  double _screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool _isTablet(BuildContext context) => _screenWidth(context) >= 700;

  double _responsiveScale(BuildContext context) {
    final width = _screenWidth(context);
    if (width < 360) return 0.90;
    if (width < 400) return 0.95;
    if (width < 700) return 1.00;
    if (width < 1000) return 1.12;
    return 1.22;
  }

  double _r(BuildContext context, double value) {
    final scaled = value * _responsiveScale(context);
    final min = value * 0.85;
    final max = value * 1.30;
    return scaled.clamp(min, max);
  }

  EdgeInsets _pagePadding(BuildContext context) {
    if (_isTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: _isLandscape(context) ? 24 : 20,
        vertical: 10,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: _isLandscape(context) ? 14 : 16,
      vertical: 10,
    );
  }

  Future<void> _pickDueDate() async {
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

    if (!mounted) return;
    if (pickedDate != null) {
      setState(() => dueDate = pickedDate);
    }
  }

  Widget _selectedUtangInfoCard(SalesViewModel vm) {
    final selectedCustomer = vm.selectedCustomer;
    if (selectedCustomer == null) return const SizedBox.shrink();

    final cardPadding = _r(context, 12);
    final titleSize = _r(context, 16);
    final subtitleSize = _r(context, 13.5);
    final buttonHeight = _r(context, 44);
    final gap = _r(context, 10);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_r(context, 16)),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: _r(context, 10),
            offset: Offset(0, _r(context, 6)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer: ${selectedCustomer['first_name']} ${selectedCustomer['last_name']}',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: _r(context, 4)),
          Text(
            'Due Date: ${dueDate != null ? "${dueDate!.month}/${dueDate!.day}/${dueDate!.year}" : "Not selected"}',
            style: TextStyle(
              fontSize: subtitleSize,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: _r(context, 10)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      isProductMode = false;
                      vm.selectedCustomer = null;
                      searchController.clear();
                      searchQuery = '';
                    });
                    vm.loadCustomers();
                  },
                  icon: Icon(Icons.person_outline, size: _r(context, 18)),
                  label: Text(
                    'Edit Customer',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: _r(context, 13.5),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_r(context, 14)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: _r(context, 8)),
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon:
                      Icon(Icons.calendar_month_outlined, size: _r(context, 18)),
                  label: Text(
                    'Edit Due Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: _r(context, 13.5),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_r(context, 14)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: _r(context, 8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                        padding: _pagePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cashUtangSwitch(vm),
                            if (!isCash && vm.selectedCustomer != null)
                              Padding(
                                padding:
                                    EdgeInsets.only(top: _r(context, 8.0)),
                                child: _selectedUtangInfoCard(vm),
                              ),
                            SizedBox(height: _r(context, 10)),
                            _searchBar(vm),
                            SizedBox(height: _r(context, 10)),
                            if (isCash || (!isCash && isProductMode)) ...[
                              SizedBox(height: _r(context, 8)),
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
          if (isCash || (!isCash && isProductMode))
            _bottomBar(vm, bottomPadding),
        ],
      ),
    );
  }

  // ---------------------------- Helper Widgets ----------------------------

  Widget _cashUtangSwitch(SalesViewModel vm) {
    final double toggleWidth = _screenWidth(context) - (_pagePadding(context).horizontal);
    final double sliderWidth = toggleWidth / 2;
    final height = _r(context, 50);

    return Container(
      height: height,
      padding: EdgeInsets.all(_r(context, 4)),
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(0.3),
        borderRadius: BorderRadius.circular(_r(context, 25)),
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
              margin: EdgeInsets.all(_r(context, 4)),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(_r(context, 25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: _r(context, 10),
                    offset: Offset(0, _r(context, 6)),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _switchButton("Cash", isCash, () async {
                setState(() {
                  isCash = true;
                  isProductMode = false;
                  vm.selectedCustomer = null;
                  dueDate = null;
                });

                vm.resetQuantities();
                await vm.loadProducts();
              }),
              _switchButton("Utang", !isCash, () async {
                setState(() {
                  isCash = false;
                  isProductMode = false;
                });

                vm.resetQuantities();
                await vm.loadCustomers();
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
              fontSize: _r(context, 16),
              letterSpacing: 0.2,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  Widget _searchBar(SalesViewModel vm) {
    final double height = _r(context, 55);

    BoxDecoration boxDecoration(Color color) => BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_r(context, 16)),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: _r(context, 8),
              offset: Offset(0, _r(context, 6)),
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
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.45),
            fontSize: _r(context, 14),
          ),
          prefixIcon: Icon(icon, size: _r(context, 22), color: Colors.black87),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: _r(context, 14)),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.clear,
                    size: _r(context, 22),
                    color: Colors.black54,
                  ),
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
          style: TextStyle(fontSize: _r(context, 14.5)),
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
                style: TextStyle(fontSize: _r(context, 14.5)),
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
          SizedBox(width: _r(context, 10)),
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
                borderRadius: BorderRadius.circular(_r(context, 16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: _r(context, 12),
                    offset: Offset(0, _r(context, 8)),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: _r(context, 24)),
            ),
          ),
        ],
      );
    }
  }

  Widget _categoryChips(SalesViewModel vm) {
    if (!isCash && !isProductMode) return const SizedBox.shrink();

    final chipHeight = _r(context, 45.0);
    final chipFontSize = _r(context, 15.0);
    final chipRadius = _r(context, 24.0);
    final verticalPadding = _r(context, 4.0);
    final dotSize = _r(context, 6.0);
    final dotSpacing = _r(context, 6.0);

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
            separatorBuilder: (_, _) => SizedBox(width: _r(context, 8)),
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
                  padding: EdgeInsets.symmetric(horizontal: _r(context, 16)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(chipRadius),
                    border: Border.all(
                      color:
                          selected ? Colors.transparent : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: _r(context, 10),
                        offset: Offset(0, _r(context, 6)),
                      ),
                    ],
                  ),
                  child: Text(
                    vm.categoryNames[index],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: chipFontSize,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: _r(context, 8)),
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

  Widget _categoryProductView(SalesViewModel vm) {
    return PageView.builder(
      controller: _categoryPageController,
      itemCount: vm.categoryNames.length,
      onPageChanged: (index) {
        vm.selectCategory(index);

        final screenWidth = MediaQuery.of(context).size.width;
        final scrollTo = (index * _r(context, 110)) - (screenWidth / 2) + _r(context, 55);

        if (_categoryScrollController.hasClients) {
          _categoryScrollController.animateTo(
            scrollTo.clamp(
              0,
              _categoryScrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
          );
        }
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
                fontSize: _r(context, 14.5),
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: _pagePadding(context).left,
            vertical: _r(context, 8),
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (_, i) => _productCard(filteredProducts[i], vm),
        );
      },
    );
  }

  Widget _productList(SalesViewModel vm) {
    final displayedProducts = vm.filteredProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (displayedProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: _r(context, 20)),
          child: Text(
            'No products found',
            style: TextStyle(
              fontSize: _r(context, 14.5),
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: _pagePadding(context).left,
        vertical: _r(context, 8),
      ),
      itemCount: displayedProducts.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) =>
          _productCard(displayedProducts[index], vm),
    );
  }

  Widget _productCard(ProductModel product, SalesViewModel vm) => Container(
        margin: EdgeInsets.symmetric(vertical: _r(context, 6)),
        padding: EdgeInsets.all(_r(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_r(context, 16)),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: _r(context, 12),
              offset: Offset(0, _r(context, 8)),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _productImage(product),
            SizedBox(width: _r(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: _r(context, 16),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _r(context, 4)),
                  Text(
                    currencyFormatter.format(product.sellingPrice),
                    style: TextStyle(
                      fontSize: _r(context, 15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: _r(context, 2)),
                  Text(
                    "Stock: ${product.quantity}",
                    style: TextStyle(
                      fontSize: _r(context, 12.5),
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _r(context, 8)),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: _isTablet(context) ? _r(context, 130) : _r(context, 110),
                maxWidth: _isLandscape(context)
                    ? _r(context, 170)
                    : (_isTablet(context) ? _r(context, 150) : _r(context, 130)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _quantitySelector(product, vm),
                  SizedBox(height: _r(context, 8)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currencyFormatter.format(vm.getSubtotal(product)),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: _r(context, 14.5),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    "Subtotal",
                    style: TextStyle(
                      fontSize: _r(context, 11.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _productImage(ProductModel product) {
    final double size = _isTablet(context)
        ? (_isLandscape(context) ? _r(context, 66) : _r(context, 72))
        : _r(context, 60);

    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(_r(context, 10)),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: _r(context, 30),
        color: Colors.black.withOpacity(0.35),
      ),
    );

    if (product.image == null || product.image!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_r(context, 10)),
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

  Widget _quantitySelector(ProductModel product, SalesViewModel vm) {
    final controller = vm.controllers[product.id!]!;
    final iconSize = _r(context, 18);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _r(context, 6),
        vertical: _r(context, 2),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(_r(context, 50)),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(_r(context, 50)),
            onTap: () => vm.decrementQuantity(product),
            child: Padding(
              padding: EdgeInsets.all(_r(context, 8)),
              child: Icon(Icons.remove, size: iconSize),
            ),
          ),
          SizedBox(
            width: _isTablet(context) ? _r(context, 52) : _r(context, 44),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: _r(context, 14),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: _r(context, 8)),
              ),
              onChanged: (value) {
                vm.setTypedQuantity(product, value);
              },
              onEditingComplete: () {
                if (controller.text.trim().isEmpty) {
                  vm.setTypedQuantity(product, '0');
                }
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(_r(context, 50)),
            onTap: () => vm.incrementQuantity(product),
            child: Padding(
              padding: EdgeInsets.all(_r(context, 8)),
              child: Icon(Icons.add, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- Utang List ----------------------------

  Widget _utangList() {
    final vm = ref.watch(salesViewModelProvider);

    if (!isProductMode) {
      final filteredCustomers = vm.customers.where((customer) {
        final name = '${customer['first_name']} ${customer['last_name']}';
        return name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          _pagePadding(context).left,
          0,
          _pagePadding(context).right,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dueDateCard(),
            SizedBox(height: _r(context, 8)),
            if (filteredCustomers.isNotEmpty)
              ...filteredCustomers.map((customer) => _customerItem(customer))
            else
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: _r(context, 20)),
                  child: Text(
                    "No customers found",
                    style: TextStyle(
                      fontSize: _r(context, 14.5),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _pagePadding(context).left),
            child: _selectedUtangInfoCard(vm),
          ),
          SizedBox(height: _r(context, 10)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _pagePadding(context).left),
            child: Column(
              children: [
                _searchBar(vm),
                SizedBox(height: _r(context, 10)),
                _categoryChips(vm),
              ],
            ),
          ),
          SizedBox(height: _r(context, 6)),
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
        padding: EdgeInsets.symmetric(
          vertical: _r(context, 14),
          horizontal: _r(context, 16),
        ),
        margin: EdgeInsets.symmetric(vertical: _r(context, 6)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_r(context, 16)),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: _r(context, 10),
              offset: Offset(0, _r(context, 8)),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: _r(context, 18),
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: _r(context, 20),
              ),
            ),
            SizedBox(width: _r(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${customer['first_name']} ${customer['last_name']}",
                    style: TextStyle(
                      fontSize: _r(context, 16),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _r(context, 4)),
                  Text(
                    "Available Credit: ₱${availableCredit.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: _r(context, 13.5),
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.black.withOpacity(0.45),
              size: _r(context, 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dueDateCard() {
    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _r(context, 14),
          vertical: _r(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_r(context, 16)),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: _r(context, 10),
              offset: Offset(0, _r(context, 8)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(_r(context, 8)),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(_r(context, 10)),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: _r(context, 20),
                color: Colors.black.withOpacity(0.55),
              ),
            ),
            SizedBox(width: _r(context, 10)),
            Expanded(
              child: Text(
                dueDate != null
                    ? "Due Date: ${DateFormat('MMMM d, y').format(dueDate!)}"
                    : "Select Due Date",
                style: TextStyle(
                  fontSize: _r(context, 15),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: _r(context, 20),
              color: Colors.black.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(SalesViewModel vm, double bottomPadding) {
    final bool canCheckout = vm.hasSelectedProducts;

    int itemCount = 0;
    for (final e in vm.productQuantities.entries) {
      if ((e.value) > 0) itemCount += e.value;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        _pagePadding(context).left,
        _r(context, 14),
        _pagePadding(context).right,
        _r(context, 14) + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: _r(context, 10),
                horizontal: _r(context, 12),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(_r(context, 16)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Items: $itemCount",
                    style: TextStyle(
                      fontSize: _r(context, 12.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                  SizedBox(height: _r(context, 4)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currencyFormatter.format(vm.total),
                      style: TextStyle(
                        fontSize: _r(context, 18),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: _r(context, 12)),
          Expanded(
            child: ElevatedButton(
              onPressed: canCheckout ? () => _showSummary(context, vm) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canCheckout ? AppColors.primary : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_r(context, 16)),
                ),
                elevation: canCheckout ? 2 : 0,
                minimumSize: Size.fromHeight(_r(context, 56)),
              ),
              child: Text(
                "Checkout",
                style: TextStyle(
                  fontSize: _r(context, 16),
                  fontWeight: FontWeight.w900,
                ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_r(context, 16)),
        ),
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
            height: _isLandscape(context)
                ? MediaQuery.of(context).size.height * 0.9
                : MediaQuery.of(context).size.height * 0.8,
            child: Padding(
              padding: EdgeInsets.all(_r(context, 16)),
              child: Column(
                children: [
                  Text(
                    isCash ? "CASH SALE" : "UTANG SALE",
                    style: TextStyle(
                      fontSize: _r(context, 12),
                      fontWeight: FontWeight.w900,
                      color: isCash ? AppColors.primary : AppColors.error,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: _r(context, 6)),
                  Text(
                    'Sale Summary',
                    style: TextStyle(
                      fontSize: _r(context, 20),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!isCash && selectedCustomer != null) ...[
                    SizedBox(height: _r(context, 8)),
                    Text(
                      "${selectedCustomer['first_name']} ${selectedCustomer['last_name']} • "
                      "${dueDate != null ? DateFormat('MMM d, y').format(dueDate!) : 'No due date'}",
                      style: TextStyle(
                        fontSize: _r(context, 13),
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: _r(context, 12)),
                  Expanded(
                    child: selectedProducts.isEmpty
                        ? Center(
                            child: Text(
                              'No products selected',
                              style: TextStyle(
                                fontSize: _r(context, 14.5),
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: _r(context, 4),
                                  vertical: _r(context, 4),
                                ),
                                title: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: _r(context, 16),
                                  ),
                                ),
                                subtitle: Text(
                                  '${currencyFormatter.format(product.sellingPrice)} × $qty',
                                  style: TextStyle(
                                    fontSize: _r(context, 13.5),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withOpacity(0.55),
                                  ),
                                ),
                                trailing: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyFormatter.format(subtotal),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: _r(context, 15),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Divider(height: _r(context, 24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: _r(context, 14.5),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currencyFormatter.format(vm.total),
                          style: TextStyle(
                            fontSize: _r(context, 20),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isCash && availableCredit != null) ...[
                    SizedBox(height: _r(context, 10)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Credit',
                          style: TextStyle(
                            fontSize: _r(context, 13.5),
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(availableCredit),
                          style: TextStyle(
                            fontSize: _r(context, 15),
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (exceedsAvailableCredit) ...[
                      SizedBox(height: _r(context, 6)),
                      Text(
                        'Amount exceeds available credit. Please reduce items.',
                        style: TextStyle(
                          fontSize: _r(context, 13),
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                  SizedBox(height: _r(context, 16)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(_r(context, 52)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_r(context, 20)),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: _r(context, 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: _r(context, 12)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
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

                              final double totalSale = vm.total;
                              final double creditLimit =
                                  (selectedCustomer['credit_limit'] ?? 0.0)
                                      as double;
                              final double currentBalance =
                                  (selectedCustomer['current_balance'] ?? 0.0)
                                      as double;
                              final double availableCredit2 =
                                  creditLimit - currentBalance;

                              if (totalSale > availableCredit2) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Customer\'s available credit is ₱${availableCredit2.toStringAsFixed(2)}. '
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
                                  content:
                                      const Text('Sale successfully recorded!'),
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
                            minimumSize: Size.fromHeight(_r(context, 52)),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_r(context, 20)),
                            ),
                          ),
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: _r(context, 16),
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