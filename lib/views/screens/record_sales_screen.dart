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
import 'package:flutter/services.dart';

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

      // ✅ Just refresh data, DON'T reset UI state
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

  double _scaleFromWidth(double w) {
    // baseline phone 360 → up to ~1.30 on large tablet widths
    return (w / 360).clamp(1.0, 1.30);
  }

  double _maxContentWidthFor(double screenWidth) {
    // ✅ Feel “full” on tablets, but still centered and clean.
    // Portrait tablets ~800–900 wide: allow up to 980.
    // Landscape tablets: allow a bit more.
    if (screenWidth >= 1000) return 1100.0;
    if (screenWidth >= 700) return 980.0;
    return double.infinity;
  }

  // ---------------------------- Due Date Picker ----------------------------

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
    if (pickedDate != null) setState(() => dueDate = pickedDate);
  }

  Widget _selectedUtangInfoCard(SalesViewModel vm, double s) {
    final selectedCustomer = vm.selectedCustomer;
    if (selectedCustomer == null) return const SizedBox.shrink();

    final titleSize = (16 * s).clamp(16.0, 19.0);
    final subSize = (13.5 * s).clamp(13.0, 16.0);
    final btnH = (44 * s).clamp(44.0, 54.0);
    final pad = (12 * s).clamp(12.0, 16.0);
    final radius = (16 * s).clamp(16.0, 20.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer: ${selectedCustomer['first_name']} ${selectedCustomer['last_name']}',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Due Date: ${dueDate != null ? "${dueDate!.month}/${dueDate!.day}/${dueDate!.year}" : "Not selected"}',
            style: TextStyle(
              fontSize: subSize,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: (10 * s).clamp(10.0, 14.0)),
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
                  icon: Icon(Icons.person_outline, size: (18 * s).clamp(18.0, 22.0)),
                  label: Text(
                    'Edit Customer',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: (13.5 * s).clamp(13.0, 16.0)),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(btnH),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular((14 * s).clamp(14.0, 18.0)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: (10 * s).clamp(10.0, 14.0)),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: Icon(Icons.calendar_month_outlined, size: (18 * s).clamp(18.0, 22.0)),
                  label: Text(
                    'Edit Due Date',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: (13.5 * s).clamp(13.0, 16.0)),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(btnH),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular((14 * s).clamp(14.0, 18.0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------- BUILD ----------------------------

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(salesViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final screenW = MediaQuery.of(context).size.width;
    final maxContentWidth = _maxContentWidthFor(screenW);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Halin', showBackButton: true),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: LayoutBuilder(
            builder: (context, c) {
              final s = _scaleFromWidth(c.maxWidth);

              return Column(
                children: [
                  Expanded(
                    child: vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (16 * s).clamp(16.0, 22.0),
                                  vertical: (10 * s).clamp(10.0, 14.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _cashUtangSwitch(vm, c.maxWidth, s),
                                    if (!isCash && vm.selectedCustomer != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: (8 * s).clamp(8.0, 12.0)),
                                        child: _selectedUtangInfoCard(vm, s),
                                      ),
                                    SizedBox(height: (10 * s).clamp(10.0, 14.0)),
                                    _searchBar(vm, s),
                                    SizedBox(height: (10 * s).clamp(10.0, 14.0)),
                                    if (isCash || (!isCash && isProductMode)) ...[
                                      SizedBox(height: (8 * s).clamp(8.0, 12.0)),
                                      _categoryChips(vm, s, c.maxWidth),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                child: isCash || isProductMode
                                    ? _categoryProductView(vm, s, c.maxWidth)
                                    : _utangList(s),
                              ),
                            ],
                          ),
                  ),
                  if (isCash || (!isCash && isProductMode))
                    _bottomBar(vm, bottomPadding, s),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------- Toggle (Responsive) ----------------------------

  Widget _cashUtangSwitch(SalesViewModel vm, double width, double s) {
    final h = (50 * s).clamp(50.0, 66.0);
    final pad = (4 * s).clamp(4.0, 7.0);
    final sliderWidth = (width - pad * 2) / 2;

    return Container(
      height: h,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(0.3),
        borderRadius: BorderRadius.circular(h / 2),
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
              margin: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(h / 2),
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
              _switchButton("Cash", isCash, s, () async {
                setState(() {
                  isCash = true;
                  isProductMode = false;
                  vm.selectedCustomer = null;
                  dueDate = null;
                });
                vm.resetQuantities();
                await vm.loadProducts();
              }),
              _switchButton("Utang", !isCash, s, () async {
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

  Widget _switchButton(String title, bool active, double s, VoidCallback onTap) {
    final font = (16 * s).clamp(16.0, 20.0);
    final letter = (0.2 * s).clamp(0.2, 0.4);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: font,
              letterSpacing: letter,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  // ---------------------------- Search Bar (Responsive) ----------------------------

  Widget _searchBar(SalesViewModel vm, double s) {
    final h = (55 * s).clamp(54.0, 66.0);
    final radius = (16 * s).clamp(16.0, 20.0);

    BoxDecoration boxDecoration(Color color) => BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
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
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: (14 * s).clamp(14.0, 16.0)),
          prefixIcon: Icon(icon, size: (22 * s).clamp(22.0, 26.0), color: Colors.black87),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: (14 * s).clamp(14.0, 18.0)),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.clear, size: (22 * s).clamp(22.0, 26.0), color: Colors.black54),
                )
              : null,
        );

    if (isCash || (!isCash && isProductMode)) {
      return Container(
        height: h,
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
              height: h,
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
          SizedBox(width: (10 * s).clamp(10.0, 14.0)),
          GestureDetector(
            onTap: () async {
              final result = await context.push<bool>('/new_customer');
              if (result == true) {
                final vm2 = ref.read(salesViewModelProvider);
                await vm2.loadCustomers();
                setState(() {
                  searchController.clear();
                  searchQuery = '';
                });
              }
            },
            child: Container(
              height: h,
              width: h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: (22 * s).clamp(22.0, 26.0)),
            ),
          ),
        ],
      );
    }
  }

  // ---------------------------- Chips (Responsive) ----------------------------

  Widget _categoryChips(SalesViewModel vm, double s, double availableW) {
    if (!isCash && !isProductMode) return const SizedBox.shrink();

    final chipH = (45 * s).clamp(44.0, 56.0);
    final chipFont = (15 * s).clamp(14.0, 17.0);
    final chipRadius = (24 * s).clamp(22.0, 30.0);
    final vPad = (4 * s).clamp(4.0, 7.0);
    final dot = (6 * s).clamp(6.0, 8.0);
    final dotSpace = (6 * s).clamp(6.0, 10.0);

    final totalCategories = vm.categoryNames.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: chipH + vPad * 2,
          child: ListView.separated(
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: totalCategories,
            separatorBuilder: (_, _) => SizedBox(width: (8 * s).clamp(8.0, 12.0)),
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
                  height: chipH,
                  margin: EdgeInsets.symmetric(vertical: vPad),
                  padding: EdgeInsets.symmetric(horizontal: (16 * s).clamp(14.0, 22.0)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(chipRadius),
                    border: Border.all(
                      color: selected ? Colors.transparent : Colors.grey.shade300,
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
                      fontSize: chipFont,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: (8 * s).clamp(8.0, 12.0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalCategories, (index) {
            final selected = index == vm.selectedCategoryIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? dot + 2 : dot,
              height: dot,
              margin: EdgeInsets.symmetric(horizontal: dotSpace / 2),
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

  // ---------------------------- PageView ----------------------------

  Widget _categoryProductView(SalesViewModel vm, double s, double availableW) {
    return PageView.builder(
      controller: _categoryPageController,
      itemCount: vm.categoryNames.length,
      onPageChanged: (index) {
        vm.selectCategory(index);

        // ✅ use available width, not full screen width
        final scrollTo = (index * (110 * s)) - (availableW / 2) + (55 * s);

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
                fontSize: (14.5 * s).clamp(14.0, 16.5),
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: (16 * s).clamp(16.0, 22.0),
            vertical: (8 * s).clamp(8.0, 12.0),
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (_, i) => _productCard(filteredProducts[i], vm, s, availableW),
        );
      },
    );
  }

  // ---------------------------- Product Card (Responsive, improved layout) ----------------------------

  Widget _productCard(ProductModel product, SalesViewModel vm, double s, double availableW) {
    final isTablet = availableW >= 700;

    final nameSize = (16 * s).clamp(16.0, 19.0);
    final priceSize = (15 * s).clamp(15.0, 18.0);
    final stockSize = (12.5 * s).clamp(12.0, 14.5);
    final subtotalSize = (15 * s).clamp(14.5, 18.0);

    final pad = (12 * s).clamp(12.0, 16.0);
    final gap = (12 * s).clamp(10.0, 16.0);
    final radius = (16 * s).clamp(16.0, 20.0);

    return Container(
      margin: EdgeInsets.symmetric(vertical: (6 * s).clamp(6.0, 10.0)),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
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
          _productImage(product, s),
          SizedBox(width: gap),

          // LEFT: product info
          Expanded(
            flex: isTablet ? 5 : 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: nameSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: (4 * s).clamp(4.0, 6.0)),
                Text(
                  currencyFormatter.format(product.sellingPrice),
                  style: TextStyle(fontSize: priceSize, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: (2 * s).clamp(2.0, 4.0)),
                Text(
                  "Stock: ${product.quantity}",
                  style: TextStyle(
                    fontSize: stockSize,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // CENTER: quantity selector (red area)
          Expanded(
            flex: isTablet ? 4 : 5,
            child: Align(
              alignment: Alignment.center,
              child: _quantitySelector(product, vm, s),
            ),
          ),

          // RIGHT: subtotal (centered)
          SizedBox(
            width: isTablet ? (130 * s).clamp(120.0, 170.0) : (105 * s).clamp(98.0, 130.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currencyFormatter.format(vm.getSubtotal(product)),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: subtotalSize,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: (3 * s).clamp(3.0, 5.0)),
                Text(
                  "Subtotal",
                  style: TextStyle(
                    fontSize: (11.5 * s).clamp(11.5, 13.5),
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(ProductModel product, double s) {
    final size = (60 * s).clamp(56.0, 74.0);
    final radius = (10 * s).clamp(10.0, 14.0);

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: (30 * s).clamp(28.0, 38.0),
        color: Colors.black.withOpacity(0.35),
      ),
    );

    if (product.image == null || product.image!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
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

  Widget _quantitySelector(ProductModel product, SalesViewModel vm, double s) {
    final controller = vm.controllers[product.id!]!;

    final icon = (18 * s).clamp(18.0, 22.0);
    final pad = (8 * s).clamp(8.0, 11.0);
    final fieldW = (44 * s).clamp(44.0, 64.0);
    final font = (14 * s).clamp(14.0, 16.5);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (6 * s).clamp(6.0, 10.0),
        vertical: (2 * s).clamp(2.0, 4.0),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => vm.decrementQuantity(product),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Icon(Icons.remove, size: icon),
            ),
          ),
          SizedBox(
            width: fieldW,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: font),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: (8 * s).clamp(8.0, 10.0)),
              ),
              onChanged: (value) => vm.setTypedQuantity(product, value),
              onEditingComplete: () {
                if (controller.text.trim().isEmpty) vm.setTypedQuantity(product, '0');
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => vm.incrementQuantity(product),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Icon(Icons.add, size: icon),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- Utang List ----------------------------

  Widget _utangList(double s) {
    final vm = ref.watch(salesViewModelProvider);

    if (!isProductMode) {
      final filteredCustomers = vm.customers.where((customer) {
        final name = '${customer['first_name']} ${customer['last_name']}';
        return name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          (16 * s).clamp(16.0, 22.0),
          0,
          (16 * s).clamp(16.0, 22.0),
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dueDateCard(s),
            SizedBox(height: (8 * s).clamp(8.0, 12.0)),
            if (filteredCustomers.isNotEmpty)
              ...filteredCustomers.map((customer) => _customerItem(customer, s))
            else
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: (20 * s).clamp(20.0, 30.0)),
                  child: Text(
                    "No customers found",
                    style: TextStyle(
                      fontSize: (14.5 * s).clamp(14.0, 16.5),
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
            padding: EdgeInsets.symmetric(horizontal: (16 * s).clamp(16.0, 22.0)),
            child: _selectedUtangInfoCard(vm, s),
          ),
          SizedBox(height: (10 * s).clamp(10.0, 14.0)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: (16 * s).clamp(16.0, 22.0)),
            child: Column(
              children: [
                _searchBar(vm, s),
                SizedBox(height: (10 * s).clamp(10.0, 14.0)),
                // for utang product mode we still show chips
                LayoutBuilder(builder: (context, c) => _categoryChips(vm, s, c.maxWidth)),
              ],
            ),
          ),
          SizedBox(height: (6 * s).clamp(6.0, 10.0)),
          Expanded(child: _productList(vm, s)),
        ],
      );
    }
  }

  Widget _productList(SalesViewModel vm, double s) {
    final displayedProducts = vm.filteredProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (displayedProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: (20 * s).clamp(20.0, 30.0)),
          child: Text(
            'No products found',
            style: TextStyle(
              fontSize: (14.5 * s).clamp(14.0, 16.5),
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: (16 * s).clamp(16.0, 22.0),
        vertical: (8 * s).clamp(8.0, 12.0),
      ),
      itemCount: displayedProducts.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) {
        // available width from screen for fallback
        final availableW = MediaQuery.of(context).size.width;
        return _productCard(displayedProducts[index], vm, s, availableW);
      },
    );
  }

  Widget _customerItem(Map<String, dynamic> customer, double s) {
    final vm = ref.read(salesViewModelProvider);
    final availableCredit = (customer['available_credit'] ?? 1000.0) as double;

    final titleSize = (16 * s).clamp(16.0, 19.0);
    final subSize = (13.5 * s).clamp(13.0, 16.0);

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
          vertical: (14 * s).clamp(14.0, 18.0),
          horizontal: (16 * s).clamp(16.0, 20.0),
        ),
        margin: EdgeInsets.symmetric(vertical: (6 * s).clamp(6.0, 10.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular((16 * s).clamp(16.0, 20.0)),
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
              radius: (18 * s).clamp(18.0, 22.0),
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            SizedBox(width: (12 * s).clamp(12.0, 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${customer['first_name']} ${customer['last_name']}",
                    style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: (4 * s).clamp(4.0, 6.0)),
                  Text(
                    "Available Credit: ₱${availableCredit.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: subSize,
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

  Widget _dueDateCard(double s) {
    final radius = (16 * s).clamp(16.0, 20.0);

    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (14 * s).clamp(14.0, 18.0),
          vertical: (12 * s).clamp(12.0, 16.0),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.grey.shade300, width: 1),
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
              padding: EdgeInsets.all((8 * s).clamp(8.0, 10.0)),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular((10 * s).clamp(10.0, 14.0)),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: (20 * s).clamp(20.0, 24.0),
                color: Colors.black.withOpacity(0.55),
              ),
            ),
            SizedBox(width: (10 * s).clamp(10.0, 14.0)),
            Expanded(
              child: Text(
                dueDate != null
                    ? "Due Date: ${DateFormat('MMMM d, y').format(dueDate!)}"
                    : "Select Due Date",
                style: TextStyle(
                  fontSize: (15 * s).clamp(15.0, 18.0),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: (20 * s).clamp(20.0, 24.0), color: Colors.black.withOpacity(0.45)),
          ],
        ),
      ),
    );
  }

  // ---------------------------- Bottom Bar (Responsive) ----------------------------

  Widget _bottomBar(SalesViewModel vm, double bottomPadding, double s) {
    final canCheckout = vm.hasSelectedProducts;

    int itemCount = 0;
    for (final e in vm.productQuantities.entries) {
      if (e.value > 0) itemCount += e.value;
    }

    final padH = (16 * s).clamp(16.0, 22.0);
    final padV = (14 * s).clamp(14.0, 18.0);
    final radius = (16 * s).clamp(16.0, 20.0);

    return Container(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: (10 * s).clamp(10.0, 14.0),
                horizontal: (12 * s).clamp(12.0, 16.0),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Items: $itemCount",
                    style: TextStyle(
                      fontSize: (12.5 * s).clamp(12.5, 14.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                  SizedBox(height: (4 * s).clamp(4.0, 6.0)),
                  Text(
                    currencyFormatter.format(vm.total),
                    style: TextStyle(
                      fontSize: (18 * s).clamp(18.0, 22.0),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: (12 * s).clamp(12.0, 16.0)),
          Expanded(
            child: ElevatedButton(
              onPressed: canCheckout ? () => _showSummary(context, vm) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCheckout ? AppColors.primary : Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                elevation: canCheckout ? 2 : 0,
                minimumSize: Size.fromHeight((56 * s).clamp(56.0, 68.0)),
              ),
              child: Text(
                "Checkout",
                style: TextStyle(
                  fontSize: (16 * s).clamp(16.0, 19.0),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- Summary Bottom Sheet (UNCHANGED) ----------------------------

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

                              final totalSale = vm.total;
                              final creditLimit = (selectedCustomer['credit_limit'] ?? 0.0) as double;
                              final currentBalance = (selectedCustomer['current_balance'] ?? 0.0) as double;
                              final availableCredit2 = creditLimit - currentBalance;

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