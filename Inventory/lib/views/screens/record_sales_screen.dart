// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dswd_slp/core/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../app_router.dart';
import '../../models/product_model.dart';
import '../../models/product_selling_option.dart';
import '../../view_models/record_sales_view_model.dart';
import 'package:intl/intl.dart';

class RecordSalesScreen extends ConsumerStatefulWidget {
  const RecordSalesScreen({super.key});

  @override
  ConsumerState<RecordSalesScreen> createState() => _RecordSalesScreenState();
}

class _ProductImageRef {
  const _ProductImageRef({
    required this.path,
    required this.isFile,
  });

  final String path;
  final bool isFile;
}

final currencyFormatter = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);

class _RecordSalesScreenState extends ConsumerState<RecordSalesScreen>
    with RouteAware {
  static const Color _pageBg      = Color(0xFFF0F4FF);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _cardBgAlt   = Color(0xFFEEF2FF);
  static const Color _cardBorder  = Color(0xFFCDD5EE);
  static const Color _titleColor  = Color(0xFF1B3A7A);
  static const Color _subtitleColor = Color(0xFF5B6D96);
  static const Color _brandDeep   = Color(0xFF1B3A7A);
  static const Color _heroStart   = Color(0xFF1A3584);
  static const Color _heroEnd     = Color(0xFF4B8AF0);

  bool isCash = true;
  bool isProductMode = false;
  bool _isSwitchingSaleType = false;

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

  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
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
          dialogTheme: DialogThemeData(backgroundColor: Colors.grey.shade100),
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
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer: ${selectedCustomer['first_name']} ${selectedCustomer['last_name']}',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800),
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
                    foregroundColor: _titleColor,
                    side: BorderSide(color: _cardBorder),
                    backgroundColor: const Color(0xFFF7F9FF),
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
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    size: _r(context, 18),
                  ),
                  label: Text(
                    'Edit Due Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: _r(context, 13.5),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(buttonHeight),
                    foregroundColor: _titleColor,
                    side: BorderSide(color: _cardBorder),
                    backgroundColor: const Color(0xFFF7F9FF),
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
      backgroundColor: _pageBg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_r(context, 64)),
        child: AppBar(
          backgroundColor: _cardBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          toolbarHeight: _r(context, 64),
          leading: IconButton(
            icon: Image.asset(
              'lib/assets/arrowleft.png',
              width: _r(context, 22),
              height: _r(context, 22),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.arrow_back_ios_new_rounded,
                size: _r(context, 18),
                color: _brandDeep,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Record Sale',
            style: TextStyle(
              color: _titleColor,
              fontWeight: FontWeight.w900,
              fontSize: _r(context, 20),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _cardBorder),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: _pagePadding(context),
                        child: Container(
                          padding: EdgeInsets.all(_r(context, 14)),
                          decoration: _surfaceDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCash ? 'Cash Sale' : 'Utang Sale',
                                style: TextStyle(
                                  fontSize: _r(context, 21),
                                  fontWeight: FontWeight.w900,
                                  color: _titleColor,
                                ),
                              ),
                              SizedBox(height: _r(context, 14)),
                              _cashUtangSwitch(vm),
                              if (!isCash && vm.selectedCustomer != null)
                                Padding(
                                  padding: EdgeInsets.only(top: _r(context, 10)),
                                  child: _selectedUtangInfoCard(vm),
                                ),
                              SizedBox(height: _r(context, 10)),
                              _searchBar(vm),
                              SizedBox(height: _r(context, 10)),
                              if (isCash || (!isCash && isProductMode))
                                _categoryChips(vm),
                            ],
                          ),
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

  BoxDecoration _surfaceDecoration() {
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(_r(context, 20)),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF93A4CF).withOpacity(0.14),
          blurRadius: _r(context, 20),
          offset: Offset(0, _r(context, 10)),
        ),
      ],
    );
  }

  // ---------------------------- Helper Widgets ----------------------------

  Future<void> _handleSaleTypeToggle(SalesViewModel vm, bool nextIsCash) async {
    if (_isSwitchingSaleType || isCash == nextIsCash) return;

    setState(() {
      _isSwitchingSaleType = true;
      isCash = nextIsCash;
      isProductMode = false;
      if (nextIsCash) {
        vm.selectedCustomer = null;
        dueDate = null;
      }
    });

    vm.resetQuantities();

    if (nextIsCash) {
      await vm.loadProducts();
    } else {
      await vm.loadCustomers();
    }

    if (!mounted) return;
    setState(() {
      _isSwitchingSaleType = false;
    });
  }

  Widget _cashUtangSwitch(SalesViewModel vm) {
    final double toggleWidth =
        _screenWidth(context) - (_pagePadding(context).horizontal);
    final double sliderWidth = toggleWidth / 2;
    final height = _r(context, 50);

    return Container(
      height: height,
      padding: EdgeInsets.all(_r(context, 4)),
      decoration: BoxDecoration(
        color: _cardBgAlt.withOpacity(0.92),
        borderRadius: BorderRadius.circular(_r(context, 25)),
        border: Border.all(color: _cardBorder),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D53B8), Color(0xFF2B80EB)],
                ),
                borderRadius: BorderRadius.circular(_r(context, 25)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3268D8).withOpacity(0.24),
                    blurRadius: _r(context, 10),
                    offset: Offset(0, _r(context, 6)),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _switchButton("Cash", isCash, () => _handleSaleTypeToggle(vm, true)),
              _switchButton("Utang", !isCash, () => _handleSaleTypeToggle(vm, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchButton(String title, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: _isSwitchingSaleType ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: active ? Colors.white : _titleColor,
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
      border: Border.all(color: _cardBorder, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF93A4CF).withOpacity(0.12),
          blurRadius: _r(context, 12),
          offset: Offset(0, _r(context, 8)),
        ),
      ],
    );

    InputDecoration inputDecoration(
      String hint,
      IconData icon,
      TextEditingController controller,
      VoidCallback onClear,
    ) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _subtitleColor.withOpacity(0.85),
        fontSize: _r(context, 14),
      ),
      prefixIcon: Icon(icon, size: _r(context, 22), color: _titleColor),
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
        decoration: boxDecoration(_cardBg),
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
              decoration: boxDecoration(_cardBg),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D53B8), Color(0xFF2B80EB)],
                ),
                borderRadius: BorderRadius.circular(_r(context, 16)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3268D8).withOpacity(0.22),
                    blurRadius: _r(context, 12),
                    offset: Offset(0, _r(context, 8)),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_add_alt_1,
                color: Colors.white,
                size: _r(context, 22),
              ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF1D53B8), Color(0xFF2B80EB)],
                          )
                        : null,
                    color: selected ? null : _cardBg,
                    borderRadius: BorderRadius.circular(chipRadius),
                    border: Border.all(
                      color: selected ? Colors.transparent : _cardBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF93A4CF).withOpacity(
                          selected ? 0.22 : 0.10,
                        ),
                        blurRadius: _r(context, 12),
                        offset: Offset(0, _r(context, 8)),
                      ),
                    ],
                  ),
                  child: Text(
                    vm.categoryNames[index],
                    style: TextStyle(
                      color: selected ? Colors.white : _titleColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
                color: selected ? const Color(0xFF2B80EB) : Colors.grey.shade400,
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
        final scrollTo =
            (index * _r(context, 110)) - (screenWidth / 2) + _r(context, 55);

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
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _pagePadding(context).left,
              ),
              child: Text(
                'No products in this category',
                style: TextStyle(
                  fontSize: _r(context, 15),
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
                textAlign: TextAlign.center,
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
          padding: EdgeInsets.symmetric(
            horizontal: _pagePadding(context).left,
            vertical: _r(context, 20),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(_r(context, 18)),
            decoration: _surfaceDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: _r(context, 34),
                  color: _subtitleColor,
                ),
                SizedBox(height: _r(context, 10)),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: _r(context, 15),
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                  ),
                ),
                SizedBox(height: _r(context, 4)),
                Text(
                  'Try another category or search keyword.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _r(context, 12.5),
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                  ),
                ),
              ],
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

  Widget _productCard(ProductModel product, SalesViewModel vm) {
    final subtotal = vm.getSubtotal(product);
    final qty = vm.getQuantity(product);
    final hasSelection = subtotal > 0;
    final addedLabel = hasSelection ? 'Added: $qty ${product.baseUnit}' : null;
    final effectiveUnitPrice = vm.getEffectiveUnitPrice(product);
    final hasDefaultUnitPrice = effectiveUnitPrice > 0;
    final cardConversions = vm.unitConversionsFor(product);
    final cardPrimaryConversion = cardConversions.isEmpty
        ? null
        : cardConversions.reduce((a, b) =>
            a.baseQuantity < b.baseQuantity ? a : b);
    final cardHumanPrice = cardPrimaryConversion != null
        ? (cardPrimaryConversion.sellPrice != null && cardPrimaryConversion.sellPrice! > 0
            ? cardPrimaryConversion.sellPrice!
            : effectiveUnitPrice * cardPrimaryConversion.baseQuantity)
        : effectiveUnitPrice;
    final cardHumanUnit =
        cardPrimaryConversion?.unitName ?? product.baseUnit;

    // Accent bar colour � green=ok, orange=low(=10), red=out
    final accentColor = product.quantity <= 0
        ? const Color(0xFFD63031)
        : product.quantity <= 10
            ? const Color(0xFFE67E00)
            : const Color(0xFF00897B);

    return InkWell(
      borderRadius: BorderRadius.circular(_r(context, 20)),
      onTap: () => _showProductSellSheet(product, vm),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: _r(context, 6)),
        decoration: _surfaceDecoration(),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: _r(context, 5),
                color: accentColor,
              ),
              // Card content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_r(context, 14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(_r(context, 8)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8FF),
                              borderRadius: BorderRadius.circular(_r(context, 16)),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: _productImage(product),
                          ),
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
                          color: _titleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: _r(context, 4)),
                      Text(
                        hasDefaultUnitPrice
                            ? '${currencyFormatter.format(cardHumanPrice)} / $cardHumanUnit'
                            : 'Manual price',
                        style: TextStyle(
                          fontSize: _r(context, 14.5),
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF255FD5),
                        ),
                      ),
                      SizedBox(height: _r(context, 6)),
                      Row(
                        children: [
                          Flexible(
                            child: _infoPill('Stock: ${product.stockDisplay}'),
                          ),
                          if (addedLabel != null) ...[
                            SizedBox(width: _r(context, 12)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: _statusText(addedLabel),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _r(context, 12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        minWidth: _r(context, 92),
                        maxWidth: _r(context, 104),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: _r(context, 12),
                        vertical: _r(context, 12),
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF8FAFF), Color(0xFFEFF4FF)],
                        ),
                        borderRadius: BorderRadius.circular(_r(context, 18)),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(subtotal),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: _r(context, 15),
                              color: _titleColor,
                            ),
                          ),
                          SizedBox(height: _r(context, 2)),
                          Text(
                            "Subtotal",
                            style: TextStyle(
                              fontSize: _r(context, 11.5),
                              fontWeight: FontWeight.w700,
                              color: _subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],             // closes Column(right).children
                ),               // closes Column(right)
              ],                 // closes Row(main).children
            ),                   // closes Row(main)
          ],                     // closes Column(outer).children
        ),                       // closes Column(outer)
      ),                         // closes Padding
    ),                           // closes Expanded (in IntrinsicHeight Row)
  ],                             // closes IntrinsicHeight Row.children
  ),                             // closes IntrinsicHeight Row
  ),                             // closes IntrinsicHeight
  ),                             // closes Container
  );                             // closes InkWell
  }

  Widget _infoPill(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _r(context, 8),
        vertical: _r(context, 5),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(_r(context, 999)),
        border: Border.all(color: _cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _r(context, 11.5),
          fontWeight: FontWeight.w700,
          color: _subtitleColor,
        ),
      ),
    );
  }

  Widget _statusText(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: _r(context, 12.5),
        fontWeight: FontWeight.w900,
        color: const Color(0xFFE46F1F),
      ),
    );
  }

  Widget _productImage(ProductModel product) {
    final double size = _isTablet(context)
        ? (_isLandscape(context) ? _r(context, 66) : _r(context, 72))
        : _r(context, 60);

    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_r(context, 10)),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: _r(context, 30),
        color: Colors.black.withOpacity(0.35),
      ),
    );

    final imageRef = _resolveProductImageRef(product);
    if (imageRef == null) {
      return placeholder;
    }

    if (imageRef.isFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_r(context, 10)),
        child: Image.file(
          File(imageRef.path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => placeholder,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_r(context, 10)),
      child: Image.asset(
        imageRef.path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => placeholder,
      ),
    );
  }

  _ProductImageRef? _resolveProductImageRef(ProductModel product) {
    final raw = product.image?.trim();
    if (raw == null || raw.isEmpty) return null;

    if (raw.startsWith('file://')) {
      final filePath = raw.replaceFirst('file://', '');
      if (filePath.isNotEmpty) {
        return _ProductImageRef(path: filePath, isFile: true);
      }
    }

    if (_looksLikeFilePath(raw)) {
      return _ProductImageRef(path: raw, isFile: true);
    }

    if (raw.startsWith('lib/assets/')) {
      return _ProductImageRef(path: raw, isFile: false);
    }

    final normalized = raw.replaceAll('\\', '/');
    const marker = 'product_images/';
    final markerIndex = normalized.lastIndexOf(marker);
    if (markerIndex >= 0) {
      final fileName = normalized.substring(markerIndex + marker.length);
      if (fileName.isNotEmpty) {
        return _ProductImageRef(
          path: 'lib/assets/product_images/$fileName',
          isFile: false,
        );
      }
    }

    return null;
  }

  bool _looksLikeFilePath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.startsWith('/') ||
        normalized.startsWith('file:/') ||
        RegExp(r'^[A-Za-z]:/').hasMatch(normalized);
  }

  Future<void> _showProductSellSheet(
    ProductModel product,
    SalesViewModel vm,
  ) async {
    final sellingOptions = vm.sellingOptionsFor(product);
    final displayedUnitPrice = vm.getEffectiveUnitPrice(product);
    final hasDefaultUnitPrice = displayedUnitPrice > 0;

    // Find the best human-friendly unit for price display (e.g. ₱60/kilo not ₱0.06/gram)
    final priceConversions = vm.unitConversionsFor(product);
    final primaryConversion = priceConversions.isEmpty
        ? null
        : priceConversions.reduce((a, b) =>
            a.baseQuantity < b.baseQuantity ? a : b);
    final humanPrice = primaryConversion != null
        ? displayedUnitPrice * primaryConversion.baseQuantity
        : displayedUnitPrice;
    final humanUnit = primaryConversion?.unitName ?? product.baseUnit;

    // Helpers: compute total qty/price from preset counts
    int computePresetQty(Map<String, int> counts) {
      return counts.entries.fold(0, (s, e) {
        final idx = sellingOptions.indexWhere((o) => o.label == e.key);
        if (idx < 0) return s;
        return s + ((sellingOptions[idx].baseQuantity ?? 0) * e.value);
      });
    }

    double computePresetPrice(Map<String, int> counts) {
      return counts.entries.fold(0.0, (s, e) {
        final idx = sellingOptions.indexWhere((o) => o.label == e.key);
        if (idx < 0) return s;
        return s + (sellingOptions[idx].price * e.value);
      });
    }

    // Initialize state — separate base qty (stepper) from preset counts
    final initialPresetCounts = Map<String, int>.from(
      vm.appliedSellingOptionCountMap(product),
    );
    final initialTotalQty = vm.getQuantity(product);
    int localBaseQty =
        (initialTotalQty - computePresetQty(initialPresetCounts))
            .clamp(0, product.quantity);
    final localPresetCounts = <String, int>{...initialPresetCounts};

    final initialSubtotal = vm.getSubtotal(product);
    final expectedAuto =
        (localBaseQty * displayedUnitPrice) +
        computePresetPrice(initialPresetCounts);
    bool isManualPricing =
        initialTotalQty > 0 && (initialSubtotal - expectedAuto).abs() > 0.009;
    bool isAmountMode = false;
    double localManualAmount = initialSubtotal;
    double localByAmount = 0;

    final baseQtyController = TextEditingController(
      text: localBaseQty > 0 ? localBaseQty.toString() : '',
    );
    final amountController = TextEditingController(
      text: initialSubtotal > 0 ? initialSubtotal.toStringAsFixed(2) : '',
    );
    final byAmountController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Derived values — recomputed on every rebuild
            int presetQty() => computePresetQty(localPresetCounts);
            double presetPrice() => computePresetPrice(localPresetCounts);
            int byAmountDeduction() {
              if (displayedUnitPrice <= 0 || localByAmount <= 0) return 0;
              return (localByAmount / displayedUnitPrice)
                  .floor()
                  .clamp(0, product.quantity);
            }

            final baseUnit = product.baseUnit.toLowerCase().trim();
            final isVolumeUnit = baseUnit == 'ml' ||
                baseUnit == 'milliliter' ||
                baseUnit == 'millilitre' ||
                baseUnit == 'gram' ||
                baseUnit == 'grams' ||
                baseUnit == 'g';
            final showByAmountToggle = hasDefaultUnitPrice && isVolumeUnit;

            int manualDeduction() {
              if (!isVolumeUnit || displayedUnitPrice <= 0 || localManualAmount <= 0) return 0;
              return (localManualAmount / displayedUnitPrice)
                  .floor()
                  .clamp(0, product.quantity);
            }

            int totalQty() {
              if (isAmountMode) return byAmountDeduction();
              if (isManualPricing && isVolumeUnit && displayedUnitPrice > 0) return manualDeduction();
              return localBaseQty + presetQty();
            }

            // Smart breakdown: try to fill localBaseQty with preset prices
            // e.g. qty=3 with preset "3 pcs=₱5" → prices as ₱5, not 3×₱2
            List<({String label, double total})> smartBaseBreakdown() {
              int remaining = localBaseQty;
              final result = <({String label, double total})>[];
              for (final preset in sellingOptions) {
                final pqty = preset.baseQuantity ?? 0;
                if (pqty <= 0 || remaining < pqty) continue;
                final times = remaining ~/ pqty;
                result.add((
                  label: '${preset.label} \u00d7$times',
                  total: preset.price * times,
                ));
                remaining -= times * pqty;
              }
              if (remaining > 0 && hasDefaultUnitPrice) {
                result.add((
                  label: '$remaining ${product.baseUnit} \u00d7 ${currencyFormatter.format(displayedUnitPrice)}',
                  total: remaining * displayedUnitPrice,
                ));
              }
              return result;
            }

            double autoSubtotal() {
              final baseTotal = smartBaseBreakdown().fold(0.0, (s, e) => s + e.total);
              return baseTotal + presetPrice();
            }

            double finalSubtotal() => isAmountMode
                ? localByAmount
                : (isManualPricing ? localManualAmount : autoSubtotal());

            final sellingOptionNames = sellingOptions
                .map((o) => o.label.trim().toLowerCase())
                .toSet();
            final visibleConversions = vm
                .unitConversionsFor(product)
                .where((c) =>
                    !sellingOptionNames.contains(c.unitName.trim().toLowerCase()))
                .take(4)
                .toList();

            void syncBaseQtyField() {
              baseQtyController.text =
                  localBaseQty <= 0 ? '' : localBaseQty.toString();
              baseQtyController.selection = TextSelection.fromPosition(
                TextPosition(offset: baseQtyController.text.length),
              );
            }

            void syncAmountField() {
              final s = finalSubtotal();
              amountController.text =
                  s <= 0 ? '' : s.toStringAsFixed(2);
              amountController.selection = TextSelection.fromPosition(
                TextPosition(offset: amountController.text.length),
              );
            }

            void setBaseQty(int qty) {
              final max = (product.quantity - presetQty()).clamp(0, product.quantity);
              setSheetState(() {
                localBaseQty = qty.clamp(0, max);
                if (!isManualPricing) syncAmountField();
                syncBaseQtyField();
              });
            }

            void addPreset(ProductSellingOption option) {
              if (totalQty() + (option.baseQuantity ?? 0) > product.quantity) {
                return;
              }
              setSheetState(() {
                localPresetCounts[option.label] =
                    (localPresetCounts[option.label] ?? 0) + 1;
                if (!isManualPricing) syncAmountField();
              });
            }

            void removePreset(ProductSellingOption option) {
              final count = localPresetCounts[option.label] ?? 0;
              if (count <= 0) return;
              setSheetState(() {
                if (count == 1) {
                  localPresetCounts.remove(option.label);
                } else {
                  localPresetCounts[option.label] = count - 1;
                }
                if (!isManualPricing) syncAmountField();
              });
            }

            final hasActivity = (isAmountMode && localByAmount > 0) ||
                (!isAmountMode &&
                    (totalQty() > 0 ||
                        (isManualPricing && localManualAmount > 0)));

            return SafeArea(
              top: false,
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  _r(context, 10),
                  _r(context, 12),
                  _r(context, 10),
                  _r(context, 10),
                ),
                padding: EdgeInsets.fromLTRB(
                  _r(context, 16),
                  _r(context, 12),
                  _r(context, 16),
                  _r(context, 16) + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_r(context, 28)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: _r(context, 24),
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: _r(context, 46),
                          height: _r(context, 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7E1F7),
                            borderRadius: BorderRadius.circular(_r(context, 99)),
                          ),
                        ),
                      ),
                      SizedBox(height: _r(context, 16)),

                      // Product header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(_r(context, 6)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(_r(context, 18)),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: _productImage(product),
                          ),
                          SizedBox(width: _r(context, 12)),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(_r(context, 12)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(_r(context, 20)),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: _r(context, 18),
                                                color: _titleColor,
                                              ),
                                            ),
                                            SizedBox(height: _r(context, 4)),
                                            Text(
                                              hasDefaultUnitPrice
                                                  ? '${currencyFormatter.format(humanPrice)} / $humanUnit'
                                                  : 'No default price',
                                              style: TextStyle(
                                                fontSize: _r(context, 14),
                                                fontWeight: FontWeight.w800,
                                                color: _subtitleColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Manual price toggle — always visible
                                      Padding(
                                        padding: EdgeInsets.only(left: _r(context, 8)),
                                        child: GestureDetector(
                                          onTap: () {
                                            setSheetState(() {
                                              isManualPricing = !isManualPricing;
                                              if (isManualPricing) isAmountMode = false;
                                              if (!isManualPricing) {
                                                syncAmountField();
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: _r(context, 12),
                                              vertical: _r(context, 9),
                                            ),
                                            decoration: BoxDecoration(
                                              color: isManualPricing
                                                  ? const Color(0xFF255FD5)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(_r(context, 999)),
                                              border: Border.all(
                                                color: isManualPricing
                                                    ? const Color(0xFF255FD5)
                                                    : _cardBorder,
                                              ),
                                              boxShadow: isManualPricing
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF255FD5).withOpacity(0.18),
                                                        blurRadius: _r(context, 10),
                                                        offset: Offset(0, _r(context, 4)),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isManualPricing
                                                      ? Icons.edit_off_outlined
                                                      : Icons.edit_outlined,
                                                  size: _r(context, 16),
                                                  color: isManualPricing ? Colors.white : _titleColor,
                                                ),
                                                SizedBox(width: _r(context, 6)),
                                                Text(
                                                  isManualPricing
                                                      ? 'Use Auto Price'
                                                      : 'Use Manual Total',
                                                  style: TextStyle(
                                                    fontSize: _r(context, 12),
                                                    fontWeight: FontWeight.w800,
                                                    color: isManualPricing ? Colors.white : _titleColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: _r(context, 8)),
                                  _infoPill('Available: ${product.stockDisplay}'),
                                  SizedBox(height: _r(context, 8)),
                                  _sheetHelperText(
                                    'Use the stock unit for direct deduction, saved sale buttons for common bundles, or manual total if you need to override the price.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // By ₱ / By Qty mode toggle — only for mL/gram products with a price
                      if (showByAmountToggle) ...[
                        SizedBox(height: _r(context, 12)),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() {
                                  isAmountMode = false;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: EdgeInsets.symmetric(
                                    vertical: _r(context, 10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isAmountMode
                                        ? const Color(0xFF255FD5)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(_r(context, 12)),
                                    border: Border.all(
                                      color: !isAmountMode
                                          ? const Color(0xFF255FD5)
                                          : _cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'By Quantity',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: _r(context, 13),
                                      fontWeight: FontWeight.w800,
                                      color: !isAmountMode
                                          ? Colors.white
                                          : _subtitleColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: _r(context, 8)),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() {
                                  isAmountMode = true;
                                  isManualPricing = false;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: EdgeInsets.symmetric(
                                    vertical: _r(context, 10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAmountMode
                                        ? const Color(0xFF255FD5)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(_r(context, 12)),
                                    border: Border.all(
                                      color: isAmountMode
                                          ? const Color(0xFF255FD5)
                                          : _cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'Customer Pays by Amount',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: _r(context, 13),
                                      fontWeight: FontWeight.w800,
                                      color: isAmountMode
                                          ? Colors.white
                                          : _subtitleColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _r(context, 10)),
                        _sheetHelperText(
                          'Best for liquids and timbang items like mantika or rice. Enter the peso amount and the app will estimate how much stock to deduct.',
                        ),
                      ],

                      SizedBox(height: _r(context, 18)),

                      // Amount mode input — enter ₱ amount, system derives qty
                      if (isAmountMode) ...[
                        _sheetSectionLabel('Pila ang bayad sa customer?'),
                        SizedBox(height: _r(context, 8)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: _r(context, 16),
                            vertical: _r(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(_r(context, 16)),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '₱',
                                style: TextStyle(
                                  fontSize: _r(context, 24),
                                  fontWeight: FontWeight.w900,
                                  color: _titleColor,
                                ),
                              ),
                              SizedBox(width: _r(context, 8)),
                              Expanded(
                                child: TextField(
                                  controller: byAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  autofocus: true,
                                  style: TextStyle(
                                    fontSize: _r(context, 28),
                                    fontWeight: FontWeight.w900,
                                    color: _titleColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                                    LengthLimitingTextInputFormatter(8),
                                  ],
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      fontSize: _r(context, 28),
                                      fontWeight: FontWeight.w900,
                                      color: _subtitleColor.withOpacity(0.4),
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final amount = double.tryParse(value.trim()) ?? 0;
                                    setSheetState(() => localByAmount = amount);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _r(context, 10)),
                        // Deduction preview
                        Builder(builder: (context) {
                          final deduction = byAmountDeduction();
                          final exceedsStock = displayedUnitPrice > 0 &&
                              localByAmount > 0 &&
                              (localByAmount / displayedUnitPrice).floor() >
                                  product.quantity;
                          if (localByAmount <= 0) return const SizedBox.shrink();
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _r(context, 14),
                              vertical: _r(context, 10),
                            ),
                            decoration: BoxDecoration(
                              color: exceedsStock
                                  ? const Color(0xFFFFF3F0)
                                  : const Color(0xFFEEF7F0),
                              borderRadius: BorderRadius.circular(_r(context, 12)),
                              border: Border.all(
                                color: exceedsStock
                                    ? const Color(0xFFFFB3A7)
                                    : const Color(0xFF81C995),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  exceedsStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: _r(context, 16),
                                  color: exceedsStock
                                      ? const Color(0xFFD63031)
                                      : const Color(0xFF2E7D32),
                                ),
                                SizedBox(width: _r(context, 8)),
                                Expanded(
                                  child: Text(
                                    exceedsStock
                                        ? 'Not enough stock. Max: ${product.quantity} ${product.baseUnit}'
                                        : '≈ $deduction ${product.baseUnit} ang ibabawas',
                                    style: TextStyle(
                                      fontSize: _r(context, 13),
                                      fontWeight: FontWeight.w700,
                                      color: exceedsStock
                                          ? const Color(0xFFD63031)
                                          : const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Individual qty stepper (shown when product has a unit price OR no presets)
                      if (!isAmountMode && (hasDefaultUnitPrice || sellingOptions.isEmpty)) ...[
                        _sheetSectionLabel(
                          sellingOptions.isNotEmpty
                              ? 'Sell by ${product.baseUnit}'
                              : 'Quantity to sell',
                        ),
                        SizedBox(height: _r(context, 8)),
                        if (sellingOptions.isNotEmpty) ...[
                          _sheetHelperText(
                            'Use this for direct piece-by-piece or unit-by-unit selling. Example: 1 stick, 2 pcs, 500 mL, or 1 kilo worth of stock.',
                          ),
                          SizedBox(height: _r(context, 8)),
                        ],
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: _r(context, 8),
                            vertical: _r(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(_r(context, 22)),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            children: [
                              _qtyStepperButton(
                                icon: Icons.remove,
                                enabled: localBaseQty > 0,
                                onTap: () => setBaseQty(localBaseQty - 1),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: _r(context, 6)),
                                  padding: EdgeInsets.symmetric(horizontal: _r(context, 8)),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(_r(context, 16)),
                                    border: Border.all(color: _cardBorder),
                                  ),
                                  child: TextField(
                                    controller: baseQtyController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: _r(context, 18),
                                      fontWeight: FontWeight.w900,
                                      color: _titleColor,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                        fontSize: _r(context, 18),
                                        fontWeight: FontWeight.w700,
                                        color: _subtitleColor,
                                      ),
                                      isDense: true,
                                    ),
                                    onChanged: (value) =>
                                        setBaseQty(int.tryParse(value.trim()) ?? 0),
                                  ),
                                ),
                              ),
                              _qtyStepperButton(
                                icon: Icons.add,
                                enabled: totalQty() < product.quantity,
                                onTap: () => setBaseQty(localBaseQty + 1),
                              ),
                            ],
                          ),
                        ),
                        // Conversion shortcuts (only when no presets)
                        if (visibleConversions.isNotEmpty) ...[
                          SizedBox(height: _r(context, 10)),
                          Wrap(
                            spacing: _r(context, 8),
                            runSpacing: _r(context, 8),
                            children: visibleConversions.map((conversion) {
                              return ActionChip(
                                label: Text(() {
                                  final nameLower = conversion.unitName.trim().toLowerCase();
                                  final qtyStr = conversion.baseQuantity.toString();
                                  final unitLower = product.baseUnit.trim().toLowerCase();
                                  // Skip suffix if the label already encodes the quantity
                                  // e.g. "3 pcs" already tells you it's 3 pcs
                                  final alreadyEncoded = nameLower.contains(qtyStr) ||
                                      nameLower.endsWith(unitLower) ||
                                      nameLower.endsWith('pcs') ||
                                      nameLower.endsWith('pieces');
                                  return alreadyEncoded
                                      ? conversion.unitName
                                      : '${conversion.unitName} (${conversion.baseQuantity} ${product.baseUnit})';
                                }()),
                                onPressed: () => setBaseQty(
                                  (localBaseQty + conversion.baseQuantity)
                                      .clamp(0, product.quantity).toInt(),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],

                      // Preset chips — each has its own fixed price, tap to add/remove
                      if (sellingOptions.isNotEmpty) ...[
                        SizedBox(height: _r(context, 14)),
                        _sheetSectionLabel('Saved sale buttons'),
                        SizedBox(height: _r(context, 8)),
                        _sheetHelperText(
                          'Use these for common sales like 3 pcs / 20, half dozen, 1 gallon, kaha, case, or ream.',
                        ),
                        SizedBox(height: _r(context, 8)),
                        Wrap(
                          spacing: _r(context, 8),
                          runSpacing: _r(context, 8),
                          children: sellingOptions.map((option) {
                            final count = localPresetCounts[option.label] ?? 0;
                            final canAdd =
                                totalQty() + (option.baseQuantity ?? 0) <=
                                    product.quantity;
                            return GestureDetector(
                              onTap: canAdd ? () => addPreset(option) : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: EdgeInsets.symmetric(
                                  horizontal: _r(context, 14),
                                  vertical: _r(context, 10),
                                ),
                                decoration: BoxDecoration(
                                  color: count > 0
                                      ? const Color(0xFFEEF4FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(_r(context, 14)),
                                  border: Border.all(
                                    color: count > 0
                                        ? const Color(0xFF2D5BE3)
                                        : _cardBorder,
                                    width: count > 0 ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          option.label,
                                          style: TextStyle(
                                            fontSize: _r(context, 14),
                                            fontWeight: FontWeight.w800,
                                            color: count > 0
                                                ? _titleColor
                                                : _subtitleColor,
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter.format(option.price),
                                          style: TextStyle(
                                            fontSize: _r(context, 13),
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF255FD5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (count > 0) ...[
                                      SizedBox(width: _r(context, 8)),
                                      GestureDetector(
                                        onTap: () => removePreset(option),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: _r(context, 6),
                                            vertical: _r(context, 2),
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2D5BE3),
                                            borderRadius: BorderRadius.circular(_r(context, 99)),
                                          ),
                                          child: Text(
                                            '\u00d7$count',
                                            style: TextStyle(
                                              fontSize: _r(context, 11),
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Manual price field
                      if (isManualPricing) ...[
                        SizedBox(height: _r(context, 14)),
                        _sheetSectionLabel('Manual total amount'),
                        SizedBox(height: _r(context, 8)),
                        _sheetHelperText(
                          'Use this only when you need to override the saved price, such as a special deal or manual wholesale total.',
                        ),
                        SizedBox(height: _r(context, 8)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: _r(context, 10)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(_r(context, 16)),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: _r(context, 14),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                              LengthLimitingTextInputFormatter(8),
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter total amount',
                            ),
                            onChanged: (value) {
                              final amount =
                                  double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
                              setSheetState(() {
                                localManualAmount = amount <= 0 ? 0 : amount;
                              });
                            },
                          ),
                        ),
                        if (isVolumeUnit && displayedUnitPrice > 0 && localManualAmount > 0) ...[
                          SizedBox(height: _r(context, 10)),
                          Builder(builder: (context) {
                            final deduction = manualDeduction();
                            final exceedsStock = deduction > product.quantity;
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _r(context, 14),
                                vertical: _r(context, 10),
                              ),
                              decoration: BoxDecoration(
                                color: exceedsStock
                                    ? const Color(0xFFFFF3F0)
                                    : const Color(0xFFEEF7F0),
                                borderRadius: BorderRadius.circular(_r(context, 12)),
                                border: Border.all(
                                  color: exceedsStock
                                      ? const Color(0xFFFFB3A7)
                                      : const Color(0xFF81C995),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    exceedsStock
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: _r(context, 16),
                                    color: exceedsStock
                                        ? const Color(0xFFD63031)
                                        : const Color(0xFF2E7D32),
                                  ),
                                  SizedBox(width: _r(context, 8)),
                                  Expanded(
                                    child: Text(
                                      exceedsStock
                                          ? 'Not enough stock. Max: ${product.quantity} ${product.baseUnit}'
                                          : '≈ $deduction ${product.baseUnit} ang ibabawas',
                                      style: TextStyle(
                                        fontSize: _r(context, 13),
                                        fontWeight: FontWeight.w700,
                                        color: exceedsStock
                                            ? const Color(0xFFD63031)
                                            : const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],

                      // Breakdown badges (auto mode only)
                      if (!isAmountMode &&
                          !isManualPricing &&
                          (localBaseQty > 0 || localPresetCounts.isNotEmpty)) ...[
                        SizedBox(height: _r(context, 10)),
                        Wrap(
                          spacing: _r(context, 6),
                          runSpacing: _r(context, 6),
                          children: [
                            // Smart breakdown of individual qty (uses preset prices where possible)
                            ...smartBaseBreakdown().map((e) =>
                              _sellBreakdownBadge(
                                '${e.label} = ${currencyFormatter.format(e.total)}',
                              ),
                            ),
                            // Explicitly tapped preset chips
                            ...localPresetCounts.entries.map((e) {
                              final idx = sellingOptions.indexWhere((o) => o.label == e.key);
                              if (idx < 0) return const SizedBox.shrink();
                              final opt = sellingOptions[idx];
                              return _sellBreakdownBadge(
                                '${e.key} \u00d7${e.value} = ${currencyFormatter.format(opt.price * e.value)}',
                              );
                            }),
                          ],
                        ),
                      ],

                      SizedBox(height: _r(context, 18)),

                      // Subtotal row
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(_r(context, 14)),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF8FBFF), Color(0xFFEFF4FF)],
                          ),
                          borderRadius: BorderRadius.circular(_r(context, 18)),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    fontSize: _r(context, 14),
                                    fontWeight: FontWeight.w800,
                                    color: _subtitleColor,
                                  ),
                                ),
                                if (totalQty() > 0)
                                  Text(
                                    '${totalQty()} ${product.baseUnit} total',
                                    style: TextStyle(
                                      fontSize: _r(context, 11),
                                      fontWeight: FontWeight.w600,
                                      color: _subtitleColor,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              currencyFormatter.format(finalSubtotal()),
                              style: TextStyle(
                                fontSize: _r(context, 18),
                                fontWeight: FontWeight.w900,
                                color: _titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _r(context, 16)),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                FocusScope.of(sheetCtx).unfocus();
                                Navigator.pop(sheetCtx);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size.fromHeight(_r(context, 52)),
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_r(context, 16)),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          SizedBox(width: _r(context, 10)),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: hasActivity
                                  ? () {
                                      FocusScope.of(sheetCtx).unfocus();
                                      vm.setProductSelection(
                                        product,
                                        qty: totalQty(),
                                        subtotal: finalSubtotal(),
                                        appliedOptionCounts: localPresetCounts,
                                      );
                                      Navigator.pop(sheetCtx);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.fromHeight(_r(context, 52)),
                                backgroundColor: const Color(0xFF255FD5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_r(context, 16)),
                                ),
                              ),
                              child: const Text('Add to Sale'),
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
      },
    );
  }

  Widget _sellBreakdownBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _r(context, 10),
        vertical: _r(context, 4),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(_r(context, 99)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: _r(context, 12),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF255FD5),
        ),
      ),
    );
  }

  Widget _sheetHelperText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: _r(context, 12),
        color: _subtitleColor,
        height: 1.35,
      ),
    );
  }

  Widget _sheetSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: _r(context, 13),
        color: _titleColor,
      ),
    );
  }

  Widget _qtyStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(_r(context, 16)),
      child: Container(
        height: _r(context, 42),
        width: _r(context, 42),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF1F4FB),
          borderRadius: BorderRadius.circular(_r(context, 16)),
          border: Border.all(color: _cardBorder),
        ),
        child: Icon(
          icon,
          size: _r(context, 18),
          color: enabled ? _titleColor : _subtitleColor.withOpacity(0.45),
        ),
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
            padding: EdgeInsets.symmetric(
              horizontal: _pagePadding(context).left,
            ),
            child: _selectedUtangInfoCard(vm),
          ),
          SizedBox(height: _r(context, 10)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _pagePadding(context).left,
            ),
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
          color: _cardBg,
          borderRadius: BorderRadius.circular(_r(context, 16)),
          border: Border.all(color: _cardBorder.withOpacity(0.75)),
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
                      color: _titleColor,
                    ),
                  ),
                  SizedBox(height: _r(context, 4)),
                  Text(
                    "Available Credit: ?${availableCredit.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: _r(context, 13.5),
                      color: _subtitleColor,
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
          color: _cardBg,
          borderRadius: BorderRadius.circular(_r(context, 16)),
          border: Border.all(color: _cardBorder, width: 1.1),
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
                color: Colors.white.withOpacity(0.8),
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

  void _showCurrentSaleSheet(SalesViewModel vm) {
    final selectedProducts = vm.products.where((p) {
      final id = p.id;
      if (id == null) return false;
      return (vm.productQuantities[id] ?? 0) > 0;
    }).toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: EdgeInsets.fromLTRB(
              _r(context, 10),
              _r(context, 12),
              _r(context, 10),
              _r(context, 10),
            ),
            padding: EdgeInsets.fromLTRB(
              _r(context, 16),
              _r(context, 12),
              _r(context, 16),
              _r(context, 16),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_r(context, 28)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: _r(context, 24),
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: _r(context, 46),
                    height: _r(context, 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7E1F7),
                      borderRadius: BorderRadius.circular(_r(context, 99)),
                    ),
                  ),
                ),
                SizedBox(height: _r(context, 14)),
                Row(
                  children: [
                    Container(
                      width: _r(context, 42),
                      height: _r(context, 42),
                      decoration: BoxDecoration(
                        color: const Color(0xFF255FD5).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(_r(context, 14)),
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        size: _r(context, 22),
                        color: const Color(0xFF255FD5),
                      ),
                    ),
                    SizedBox(width: _r(context, 10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Sale',
                            style: TextStyle(
                              fontSize: _r(context, 18),
                              fontWeight: FontWeight.w900,
                              color: _titleColor,
                            ),
                          ),
                          Text(
                            '${selectedProducts.length} ka produkto ang napili',
                            style: TextStyle(
                              fontSize: _r(context, 12.5),
                              fontWeight: FontWeight.w700,
                              color: _subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _r(context, 14)),
                if (selectedProducts.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: _r(context, 18)),
                    child: Center(
                      child: Text(
                        'Wala pay napiling item.',
                        style: TextStyle(
                          fontSize: _r(context, 13.5),
                          fontWeight: FontWeight.w700,
                          color: _subtitleColor,
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selectedProducts.length,
                      separatorBuilder: (_, index) =>
                          SizedBox(height: _r(context, 10)),
                      itemBuilder: (_, index) {
                        final product = selectedProducts[index];
                        final qty = vm.getQuantity(product);
                        final subtotal = vm.getSubtotal(product);
                        final appliedOptions =
                            vm.appliedSellingOptionsFor(product);
                        final details = appliedOptions.isNotEmpty
                            ? appliedOptions
                                .map(
                                  (entry) =>
                                      '${entry.option.label} x${entry.count}',
                                )
                                .join('  �  ')
                            : 'Manual qty: $qty ${product.baseUnit}';

                        return Container(
                          padding: EdgeInsets.all(_r(context, 14)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(_r(context, 18)),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: _r(context, 14.5),
                                        fontWeight: FontWeight.w900,
                                        color: _titleColor,
                                      ),
                                    ),
                                    SizedBox(height: _r(context, 4)),
                                    Text(
                                      details,
                                      style: TextStyle(
                                        fontSize: _r(context, 12.5),
                                        fontWeight: FontWeight.w700,
                                        color: _subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: _r(context, 10)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(subtotal),
                                    style: TextStyle(
                                      fontSize: _r(context, 14.5),
                                      fontWeight: FontWeight.w900,
                                      color: _titleColor,
                                    ),
                                  ),
                                  SizedBox(height: _r(context, 8)),
                                  SizedBox(
                                    height: _r(context, 34),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(sheetCtx);
                                        _showProductSellSheet(product, vm);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: _cardBorder),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            _r(context, 12),
                                          ),
                                        ),
                                      ),
                                      child: const Text('Edit'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: _r(context, 14)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_r(context, 14)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(_r(context, 18)),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: _r(context, 14),
                          fontWeight: FontWeight.w800,
                          color: _subtitleColor,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(vm.total),
                        style: TextStyle(
                          fontSize: _r(context, 18),
                          fontWeight: FontWeight.w900,
                          color: _titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomBar(SalesViewModel vm, double bottomPadding) {
    final bool canCheckout = vm.hasSelectedProducts;

    int itemCount = 0;
    for (final e in vm.productQuantities.entries) {
      if (e.value > 0) itemCount += 1;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        _pagePadding(context).left,
        _r(context, 14),
        _pagePadding(context).right,
        _r(context, 14) + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF).withOpacity(0.96),
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(_r(context, 16)),
              onTap: itemCount > 0 ? () => _showCurrentSaleSheet(vm) : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: _r(context, 10),
                  horizontal: _r(context, 12),
                ),
                decoration: _surfaceDecoration().copyWith(
                  borderRadius: BorderRadius.circular(_r(context, 16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Products: $itemCount",
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
                    if (itemCount > 0) ...[
                      SizedBox(height: _r(context, 2)),
                      Text(
                        'View items',
                        style: TextStyle(
                          fontSize: _r(context, 11.5),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF255FD5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: _r(context, 12)),
          Expanded(
            child: GestureDetector(
              onTap: canCheckout ? () => _showSummary(context, vm) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _r(context, 56),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: canCheckout
                      ? const LinearGradient(
                          colors: [_heroStart, _heroEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: canCheckout ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(_r(context, 16)),
                  boxShadow: canCheckout
                      ? [
                          BoxShadow(
                            color: _heroStart.withOpacity(0.30),
                            blurRadius: _r(context, 14),
                            offset: Offset(0, _r(context, 5)),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: _r(context, 16),
                    fontWeight: FontWeight.w900,
                    color: canCheckout ? Colors.white : Colors.grey.shade500,
                  ),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_r(context, 30)),
        ),
      ),
      builder: (_) {
        final selectedCustomer = vm.selectedCustomer;
        final double? availableCredit = !isCash && selectedCustomer != null
            ? ((selectedCustomer['available_credit'] ?? 0.0) as num).toDouble()
            : null;
        final bool exceedsAvailableCredit =
            availableCredit != null && vm.total > availableCredit;
        final messenger = ScaffoldMessenger.of(context);

        return SafeArea(
          child: SizedBox(
            height: _isLandscape(context)
                ? MediaQuery.of(context).size.height * 0.9
                : MediaQuery.of(context).size.height * 0.8,
            child: Container(
              margin: EdgeInsets.fromLTRB(
                _r(context, 12),
                _r(context, 8),
                _r(context, 12),
                _r(context, 12),
              ),
              padding: EdgeInsets.fromLTRB(
                _r(context, 18),
                _r(context, 14),
                _r(context, 18),
                _r(context, 18),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_r(context, 30)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: _r(context, 28),
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: _r(context, 48),
                    height: _r(context, 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7E1F7),
                      borderRadius: BorderRadius.circular(_r(context, 99)),
                    ),
                  ),
                  SizedBox(height: _r(context, 16)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: _r(context, 18),
                      vertical: _r(context, 14),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_r(context, 24)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCash
                            ? const [
                                Color(0xFF173D86),
                                Color(0xFF1D79D8),
                                Color(0xFF28C4D5),
                              ]
                            : const [
                                Color(0xFF7A2331),
                                Color(0xFFB63D58),
                                Color(0xFFE36A7C),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCash
                                  ? const Color(0xFF1B4A9A)
                                  : const Color(0xFF9D3250))
                              .withValues(alpha: 0.22),
                          blurRadius: _r(context, 20),
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: _r(context, 42),
                          height: _r(context, 42),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(_r(context, 18)),
                          ),
                          child: Icon(
                            isCash
                                ? Icons.point_of_sale_rounded
                                : Icons.credit_card_rounded,
                            color: Colors.white,
                            size: _r(context, 20),
                          ),
                        ),
                        SizedBox(height: _r(context, 8)),
                        Text(
                          isCash ? "CASH SALE" : "UTANG SALE",
                          style: TextStyle(
                            fontSize: _r(context, 11),
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.88),
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: _r(context, 3)),
                        Text(
                          'Sale Summary',
                          style: TextStyle(
                            fontSize: _r(context, 18),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: _r(context, 4)),
                        Text(
                          '${selectedProducts.length} item${selectedProducts.length == 1 ? '' : 's'} selected',
                          style: TextStyle(
                            fontSize: _r(context, 12),
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                        if (!isCash && selectedCustomer != null) ...[
                          SizedBox(height: _r(context, 6)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _r(context, 10),
                              vertical: _r(context, 6),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(_r(context, 999)),
                            ),
                            child: Text(
                              "${selectedCustomer['first_name']} ${selectedCustomer['last_name']} � "
                              "${dueDate != null ? DateFormat('MMM d, y').format(dueDate!) : 'No due date'}",
                              style: TextStyle(
                                fontSize: _r(context, 11.5),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: _r(context, 16)),
                  Expanded(
                    child: selectedProducts.isEmpty
                        ? Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(_r(context, 22)),
                              border: Border.all(
                                color: const Color(0xFFCDD5EE),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No products selected',
                                style: TextStyle(
                                  fontSize: _r(context, 14.5),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5B6D96),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(_r(context, 22)),
                              border: Border.all(
                                color: const Color(0xFFCDD5EE),
                              ),
                            ),
                            child: ListView.separated(
                            padding: EdgeInsets.all(_r(context, 12)),
                            itemCount: selectedProducts.length,
                            separatorBuilder: (_, index) =>
                                SizedBox(height: _r(context, 10)),
                            itemBuilder: (_, index) {
                              final product = selectedProducts[index];
                              final qty = vm.getQuantity(product);
                              final subtotal = vm.getSubtotal(product);
                              final appliedOptions =
                                  vm.appliedSellingOptionsFor(product);

                              return Container(
                                padding: EdgeInsets.all(_r(context, 14)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    _r(context, 18),
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFCDD5EE),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: _r(context, 42),
                                      height: _r(context, 42),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2F6BFF,
                                        ).withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(
                                          _r(context, 14),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_rounded,
                                        color: const Color(0xFF2D5BE3),
                                        size: _r(context, 22),
                                      ),
                                    ),
                                    SizedBox(width: _r(context, 12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: _r(context, 15.5),
                                              color: const Color(0xFF1B3A7A),
                                            ),
                                          ),
                                          SizedBox(height: _r(context, 4)),
                                          Text(
                                            appliedOptions.isNotEmpty
                                                ? appliedOptions
                                                    .map(
                                                      (entry) =>
                                                          '${entry.option.label} x${entry.count}',
                                                    )
                                                    .join('  �  ')
                                                : vm.getEffectiveUnitPrice(product) > 0
                                                    ? '$qty ${product.baseUnit} x ${currencyFormatter.format(vm.getEffectiveUnitPrice(product))}/${product.baseUnit}'
                                                    : '$qty ${product.baseUnit} � manual price',
                                            style: TextStyle(
                                              fontSize: _r(context, 13),
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF5B6D96),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: _r(context, 8)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _r(context, 10),
                                        vertical: _r(context, 8),
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2F6BFF,
                                        ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(
                                          _r(context, 14),
                                        ),
                                      ),
                                      child: Text(
                                        currencyFormatter.format(subtotal),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: _r(context, 14.5),
                                          color: const Color(0xFF1B3A7A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          ),
                  ),
                  SizedBox(height: _r(context, 14)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(_r(context, 16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(_r(context, 20)),
                      border: Border.all(
                        color: const Color(0xFFCDD5EE),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: _r(context, 14.5),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: const Color(0xFF1B3A7A),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyFormatter.format(vm.total),
                                style: TextStyle(
                                  fontSize: _r(context, 22),
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1B3A7A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isCash && availableCredit != null) ...[
                          SizedBox(height: _r(context, 12)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Credit',
                                style: TextStyle(
                                  fontSize: _r(context, 13.5),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5B6D96),
                                ),
                              ),
                              Text(
                                currencyFormatter.format(availableCredit),
                                style: TextStyle(
                                  fontSize: _r(context, 15),
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1B3A7A),
                                ),
                              ),
                            ],
                          ),
                          if (exceedsAvailableCredit) ...[
                            SizedBox(height: _r(context, 8)),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(_r(context, 12)),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD84040,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  _r(context, 14),
                                ),
                              ),
                              child: Text(
                                'Amount exceeds available credit. Please reduce items.',
                                style: TextStyle(
                                  fontSize: _r(context, 13),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFD84040),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: _r(context, 16)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(_r(context, 54)),
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _r(context, 20),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: _r(context, 16),
                              color: AppColors.error,
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
                                messenger.showSnackBar(
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
                                messenger.showSnackBar(
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
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Customer\'s available credit is ?${availableCredit2.toStringAsFixed(2)}. '
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

                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Sale successfully recorded!',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Checkout failed: $e'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.fromHeight(_r(context, 54)),
                            backgroundColor: const Color(0xFF173D86),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _r(context, 20),
                              ),
                            ),
                            elevation: 0,
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
