// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../models/product_selling_option.dart';
import '../../models/product_unit_conversion.dart';
import '../../providers/restock_product_provider.dart';
import '../../view_models/stock_in_view_model.dart';


class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _fieldBg = Color(0xFFF8FAFF);
  static const Color _cardBorder = Color(0xFFCDD5EE);
  static const Color _titleColor = Color(0xFF1B3A7A);
  static const Color _subtitleColor = Color(0xFF5B6D96);
  static const Color _accentBlue = Color(0xFF2D5BE3);
  late final ScrollController _scrollController;
  final TextEditingController _unitFactorController = TextEditingController();
  String _lastUnitForFactor = '';
  bool _showUnitOptions = false;
  bool _showQuickOptions = false;
  bool _restockPopulated = false;


  String _currentStockType(StockInViewModel vm) {
    final base = vm.baseUnitLabel.trim().toLowerCase();
    if (!vm.useAdvancedUnitSetup || base == 'pcs') return 'piece';
    if (base == 'gram' || base == 'grams' || base == 'g') return 'weight';
    if (base == 'ml' || base == 'milliliter' || base == 'millilitre') {
      return 'liquid';
    }
    if (base == 'half' || base == 'tungaon') return 'pack';
    return 'piece';
  }

  String _sellingPriceLabel(StockInViewModel vm) {
    switch (_currentStockType(vm)) {
      case 'weight':
        return 'Default selling price per kilo';
      case 'liquid':
        return 'Default selling price per liter';
      case 'piece':
      default:
        return 'Default selling price per piece';
    }
  }

  String _boughtAsHelperText(StockInViewModel vm) {
    switch (_currentStockType(vm)) {
      case 'weight': return 'e.g. kilo, sack, pack';
      case 'liquid': return 'e.g. liter, gallon, bottle';
      case 'pack':   return 'e.g. sachet, box, dozen';
      case 'piece':
      default:       return 'e.g. box, tray, dozen';
    }
  }

  String _stockTypeDescription(String type) {
    switch (type) {
      case 'weight': return 'Para sa bugas, asukal, asin, o sibuyas. Gibaligya per kilo, gisulod per gram.';
      case 'liquid': return 'Para sa mantika, suka, toyo, o gas. Gibaligya per liter, gisulod per mL.';
      case 'pack':   return 'Para sa 3-in-1, sabon, shampoo sachet. Ang "tungaon" (half) mao ang gamay nga bahin.';
      case 'piece':
      default:       return 'Para sa itlog, tinapay, candy, o bawang. Gibilang per piraso.';
    }
  }

  String _formatCostPerUnitDisplay(double value) {
    if (value <= 0) return '-';
    if (value >= 1) return 'PHP ${value.toStringAsFixed(2)}';
    if (value >= 0.1) return 'PHP ${value.toStringAsFixed(3)}';
    return 'PHP ${value.toStringAsFixed(4)}';
  }

  String _costPerUnitLabel(StockInViewModel vm) {
    final unit = vm.baseUnitLabel.trim();
    if (unit.isEmpty) return 'Cost per unit';

    final normalized = unit.toLowerCase();
    if (normalized == 'pcs' ||
        normalized == 'pc' ||
        normalized == 'piece' ||
        normalized == 'pieces') {
      return 'Cost per piece';
    }
    return 'Cost per $unit';
  }

  void _applyStockTypePreset(StockInViewModel vm, String preset) {
    switch (preset) {
      case 'piece':
        vm.setUseAdvancedUnitSetup(false);
        break;
      case 'weight':
        vm.setUseAdvancedUnitSetup(true);
        vm.setBaseUnit('gram');
        vm.setPurchaseUnit('kilo');
        final kiloConversion = vm.unitConversions.where(
          (item) => item.unitName.trim().toLowerCase() == 'kilo',
        );
        if (kiloConversion.isEmpty) {
          vm.conversionNameController.text = 'kilo';
          vm.conversionQuantityController.text = '1000';
          vm.addUnitConversion();
        } else if (kiloConversion.first.baseQuantity != 1000) {
          vm.updateUnitConversion(
            kiloConversion.first,
            unitName: 'kilo',
            baseQuantity: 1000,
          );
        }
        break;
      case 'liquid':
        vm.setUseAdvancedUnitSetup(true);
        vm.setBaseUnit('mL');
        vm.setPurchaseUnit('liter');
        final literConversion = vm.unitConversions.where(
          (item) => item.unitName.trim().toLowerCase() == 'liter',
        );
        if (literConversion.isEmpty) {
          vm.conversionNameController.text = 'liter';
          vm.conversionQuantityController.text = '1000';
          vm.addUnitConversion();
        } else if (literConversion.first.baseQuantity != 1000) {
          vm.updateUnitConversion(
            literConversion.first,
            unitName: 'liter',
            baseQuantity: 1000,
          );
        }
        break;
      case 'pack':
        vm.setUseAdvancedUnitSetup(true);
        vm.setBaseUnit('half');
        vm.setPurchaseUnit('sachet');
        final sachetConversion = vm.unitConversions.where(
          (item) => item.unitName.trim().toLowerCase() == 'sachet',
        );
        if (sachetConversion.isEmpty) {
          vm.conversionNameController.text = 'sachet';
          vm.conversionQuantityController.text = '2';
          vm.addUnitConversion();
        } else if (sachetConversion.first.baseQuantity != 2) {
          vm.updateUnitConversion(
            sachetConversion.first,
            unitName: 'sachet',
            baseQuantity: 2,
          );
        }
        break;
    }
  }


  String? _suggestedBaseQuantity(
    StockInViewModel vm,
    String unit,
  ) {
    final normalizedUnit = unit.trim().toLowerCase();
    final base = vm.baseUnitLabel.trim().toLowerCase();

    if (normalizedUnit == 'kilo' &&
        (base == 'gram' || base == 'grams' || base == 'g')) {
      return '1000';
    }

    if (normalizedUnit == 'liter' &&
        (base == 'ml' || base == 'milliliter' || base == 'millilitre')) {
      return '1000';
    }

    if (normalizedUnit == 'gallon' &&
        (base == 'ml' || base == 'milliliter' || base == 'millilitre')) {
      return '4000';
    }

    if (normalizedUnit == 'dozen' && base == 'pcs') {
      return '12';
    }

    return null;
  }

  void _applySuggestedVariant(
    StockInViewModel vm,
    String unit,
  ) {
    vm.conversionNameController.text = unit;
    final suggestedQty = _suggestedBaseQuantity(vm, unit);
    if (suggestedQty != null) {
      vm.conversionQuantityController.text = suggestedQty;
    } else {
      vm.conversionQuantityController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _unitFactorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(stockInViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    if (!vm.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Restock flow: populate once when VM is ready
    final restockProduct = ref.read(restockProductProvider);
    if (restockProduct != null && !_restockPopulated) {
      _restockPopulated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Clear provider after frame — never modify providers during build
        ref.read(restockProductProvider.notifier).state = null;
        await vm.populateFromSelectedProduct(restockProduct);
        if (!mounted) return;
        setState(() {
          _showUnitOptions = vm.useAdvancedUnitSetup || vm.unitConversions.isNotEmpty;
          _showQuickOptions = vm.sellingOptions.isNotEmpty;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) vm.autocompleteFieldController?.text = restockProduct.name;
        });
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _showUnitOptions = _showUnitOptions || vm.useAdvancedUnitSetup || vm.unitConversions.isNotEmpty;
        _showQuickOptions = _showQuickOptions || vm.sellingOptions.isNotEmpty;
        final w = constraints.maxWidth;

        // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ same scaling pattern as your other pages
        final double scale = (w / 390).clamp(0.90, 1.20);

        final double padH = (16 * scale).clamp(14, 22);
        final double padTop = (14 * scale).clamp(10, 18);
        final double padBottom = (16 * scale).clamp(12, 20);

        final double cardPad = (14 * scale).clamp(12, 18);
        final double radius16 = (16 * scale).clamp(14, 20);
        final double radius14 = (14 * scale).clamp(12, 18);
        final double radius12 = (12 * scale).clamp(10, 16);

        final double fieldH = (58 * scale).clamp(54, 66);
        final double btnH = (52 * scale).clamp(48, 58);
        final double imgH = (220 * scale).clamp(170, 260);

        final double valueFs = (14 * scale).clamp(13, 16);
        final double optionFs = (15 * scale).clamp(13.5, 16.5);
        final double bottomBtnFs = (16 * scale).clamp(14.5, 18);

        final double gap12 = (12 * scale).clamp(10, 14);
        final double gap14 = (14 * scale).clamp(12, 18);
        final double gap10 = (10 * scale).clamp(8, 12);

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Image.asset(
                'lib/assets/arrowleft.png',
                width: (22 * scale).clamp(20.0, 26.0),
                height: (22 * scale).clamp(20.0, 26.0),
                fit: BoxFit.contain,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Stock In',
              style: TextStyle(
                color: _titleColor,
                fontWeight: FontWeight.w900,
                fontSize: (20 * scale).clamp(18.0, 24.0),
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFCDD5EE)),
            ),
          ),

          body: Stack(
            children: [
              ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(AppColors.scrollbar),
                  thickness: WidgetStateProperty.all(5),
                  radius: const Radius.circular(8),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _card(
                      padding: cardPad,
                      radius: radius16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardLabel(
                            'Product details',
                            scale: scale,
                          ),
                          SizedBox(height: gap12),
                          _inputDate(
                            vm,
                            height: fieldH,
                            radius: radius12,
                            valueFs: valueFs,
                          ),
                          SizedBox(height: gap12),

                          // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ Category Picker (Bottom Sheet)
                          _categoryPickerField(
                            vm,
                            scale: scale,
                            radius: radius12,
                            valueFs: valueFs,
                          ),

                          SizedBox(height: gap12),
                          _autocompleteProduct(
                            vm,
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            optionFs: optionFs,
                            valueFs: valueFs,
                          ),
                          if (vm.isExistingProductSelected) ...[
                            SizedBox(height: gap12),
                            _savedSetupNotice(
                              vm,
                              scale: scale,
                              radius: radius12,
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: gap14),

                    _card(
                      padding: cardPad,
                      radius: radius16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardLabel('Stock amounts', scale: scale),
                          SizedBox(height: gap12),
                          _stockTypePresetRow(
                            vm,
                            scale: scale,
                            radius: radius12,
                          ),
                          SizedBox(height: gap12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: (12 * scale).clamp(10, 14),
                              vertical: (10 * scale).clamp(8, 12),
                            ),
                            decoration: BoxDecoration(
                              color: _accentBlue.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(radius12),
                              border: Border.all(
                                color: _accentBlue.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              _stockTypeDescription(_currentStockType(vm)),
                              style: TextStyle(
                                fontSize: (12.5 * scale).clamp(11.5, 14),
                                fontWeight: FontWeight.w600,
                                color: _accentBlue,
                              ),
                            ),
                          ),
                          SizedBox(height: gap12),
                          LayoutBuilder(
                            builder: (context, amountsConstraints) {
                              final useTwoColumns = amountsConstraints.maxWidth >= 560;
                              final showSellingPriceField =
                                  _currentStockType(vm) != 'liquid';

                              final qtyField = _inputNumberField(
                                label: 'Pila kabuok?',
                                controller: vm.quantityController,
                                showError: vm.showValidationErrors,
                                icon: Icons.shopping_cart_rounded,
                                isPeso: false,
                                allowDecimal: vm.useAdvancedUnitSetup,
                                onChanged: (_) => setState(() {}),
                                scale: scale,
                                height: fieldH,
                                radius: radius12,
                                valueFs: valueFs,
                              );

                              final topFields = [
                                _inputNumberField(
                                  label: 'Tagpila tanan?',
                                  controller: vm.purchasePriceController,
                                  showError: vm.showValidationErrors,
                                  isPeso: true,
                                  onChanged: (_) => setState(() {}),
                                  scale: scale,
                                  height: fieldH,
                                  radius: radius12,
                                  valueFs: valueFs,
                                ),
                                qtyField,
                              ];

                              Widget topRow;
                              if (!useTwoColumns) {
                                topRow = Column(
                                  children: [
                                    topFields[0],
                                    SizedBox(height: gap12),
                                    topFields[1],
                                  ],
                                );
                              } else {
                                topRow = Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(child: topFields[0]),
                                    SizedBox(width: gap12),
                                    Expanded(child: topFields[1]),
                                  ],
                                );
                              }

                              // Sync factor controller when purchase unit changes
                              final currentPurchaseUnit = vm.purchaseUnitLabel;
                              final currentBaseUnit = vm.baseUnitLabel;
                              final showFactorField = vm.useAdvancedUnitSetup &&
                                  currentPurchaseUnit.toLowerCase() != currentBaseUnit.toLowerCase();
                              if (_lastUnitForFactor != currentPurchaseUnit) {
                                _lastUnitForFactor = currentPurchaseUnit;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  final factor = vm.quantityFactorFor(currentPurchaseUnit);
                                  _unitFactorController.text = factor > 1 ? factor.toString() : '';
                                });
                              }

                              final sukodAndPrice = (vm.useAdvancedUnitSetup || showSellingPriceField)
                                  ? Column(
                                      children: [
                                        SizedBox(height: gap12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (vm.useAdvancedUnitSetup) ...[
                                              Expanded(
                                                child: _purchaseUnitPickerField(
                                                  vm,
                                                  scale: scale,
                                                  radius: radius12,
                                                  valueFs: valueFs,
                                                ),
                                              ),
                                              SizedBox(width: gap12),
                                            ],
                                            if (showSellingPriceField)
                                              Expanded(
                                                child: _inputNumberField(
                                                  label: _sellingPriceLabel(vm),
                                                  controller: vm.sellingPriceController,
                                                  showError: vm.showValidationErrors,
                                                  isPeso: true,
                                                  onChanged: (_) => setState(() {}),
                                                  scale: scale,
                                                  height: fieldH,
                                                  radius: radius12,
                                                  valueFs: valueFs,
                                                ),
                                              )
                                            else if (showFactorField)
                                              Expanded(
                                                child: _inputNumberField(
                                                  label: '${currentBaseUnit} per ${currentPurchaseUnit}',
                                                  controller: _unitFactorController,
                                                  showError: false,
                                                  icon: Icons.straighten_rounded,
                                                  onChanged: (text) {
                                                    final qty = int.tryParse(text.replaceAll(',', '')) ?? 0;
                                                    if (qty > 0) vm.setUnitFactor(currentPurchaseUnit, qty);
                                                    setState(() {});
                                                  },
                                                  scale: scale,
                                                  height: fieldH,
                                                  radius: radius12,
                                                  valueFs: valueFs,
                                                ),
                                              )
                                            else
                                              const Spacer(),
                                          ],
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink();

                              return Column(
                                children: [
                                  topRow,
                                  sukodAndPrice,
                                ],
                              );
                            },
                          ),
                          SizedBox(height: gap12),
                          _costPerUnitBox(
                            vm,
                            scale: scale,
                            radius: radius12,
                          ),
                          if (vm.isExistingProductSelected) ...[
                            SizedBox(height: gap12),
                            _averageCostNote(
                              scale: scale,
                              radius: radius12,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (vm.shouldShowSetupEditors) ...[
                      SizedBox(height: gap14),
                      _card(
                        padding: cardPad,
                        radius: radius16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('Unit variants', scale: scale),
                            SizedBox(height: gap12),
                            Text(
                              'Optional: add bigger sizes you buy or sell, like pack, tray, case, sack, or kilo.',
                              style: TextStyle(
                                fontSize: (13 * scale).clamp(12, 14.5),
                                fontWeight: FontWeight.w600,
                                color: _subtitleColor,
                              ),
                            ),
                            SizedBox(height: gap12),
                            _advancedOptionRow(
                              title: 'Wholesale',
                              description:
                                  'Add bigger sizes for this item, like pack, tray, case, sack, or kilo.',
                              isOn: _showUnitOptions,
                              scale: scale,
                              onTap: () {
                                setState(() {
                                  _showUnitOptions = !_showUnitOptions;
                                  vm.setUseAdvancedUnitSetup(_showUnitOptions);
                                });
                              },
                            ),
                            if (_showUnitOptions) ...[
                              SizedBox(height: gap12),
                              _baseUnitPickerField(
                                vm,
                                scale: scale,
                                radius: radius12,
                                valueFs: valueFs,
                              ),
                              SizedBox(height: gap12),
                              _unitConversionSection(
                                vm,
                                scale: scale,
                                radius: radius12,
                                valueFs: valueFs,
                                gap12: gap12,
                              ),
                            ],
                            SizedBox(height: gap12),
                            _advancedOptionRow(
                              title: 'Retail / Tingi',
                              description:
                                  'Save common sale shortcuts so checkout is faster later.',
                              isOn: _showQuickOptions,
                              scale: scale,
                              onTap: () {
                                setState(() {
                                  _showQuickOptions = !_showQuickOptions;
                                });
                              },
                            ),
                            if (_showQuickOptions) ...[
                              SizedBox(height: gap12),
                              _sellingOptionsSection(
                                vm,
                                scale: scale,
                                radius: radius12,
                                valueFs: valueFs,
                                gap12: gap12,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: gap14),
                      _card(
                        padding: cardPad,
                        radius: radius16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('Product photo (optional)', scale: scale),
                            SizedBox(height: gap12),
                            _imagePicker(
                              vm,
                              context,
                              scale: scale,
                              radius: radius14,
                              imageHeight: imgH,
                              gap10: gap10,
                              valueFs: valueFs,
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: (90 * scale).clamp(70, 110)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ===================== BOTTOM BUTTON =====================
          bottomNavigationBar: Padding(
            padding: EdgeInsets.fromLTRB(
              padH,
              (12 * scale).clamp(10, 14),
              padH,
              (12 * scale).clamp(10, 14) + bottomPadding,
            ),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(radius14),
              shadowColor: Colors.black.withOpacity(0.15),
              child: SizedBox(
                height: btnH,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radius14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: vm.isLoading
                      ? null
                      : () {
                          vm.triggerValidation();
                          vm.saveProduct(context);
                        },
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontSize: bottomBtnFs,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ CATEGORY PICKER FIELD (BOTTOM SHEET) - responsive only
  // ============================================================
  Widget _categoryPickerField(
    StockInViewModel vm, {
    required double scale,
    required double radius,
    required double valueFs,
  }) {
    final isError = vm.showValidationErrors && (vm.selectedCategory == null);

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () async {
        final selected = await _showCategoryBottomSheet(
          context: context,
          categories: vm.categoryNames,
          selected: vm.selectedCategory,
          scale: scale,
        );

        if (selected == null) return;

        if (selected == '__add_new__') {
          await _showAddCategoryDialog(context, vm, scale: scale);
          return;
        }

        vm.setCategoryByName(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: Icon(
            Icons.category,
            color: _accentBlue,
            size: (22 * scale).clamp(20, 26),
          ),
          labelText: 'Kategorya',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: isError ? Colors.red : _cardBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: isError ? Colors.red : _accentBlue,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                vm.selectedCategory ?? 'Pili ug Kategorya',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: valueFs,
                  fontWeight: FontWeight.w800,
                  color: vm.selectedCategory == null
                      ? _subtitleColor
                      : _titleColor,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _subtitleColor,
              size: (22 * scale).clamp(20, 26),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  CATEGORY BOTTOM SHEET (responsive only)
  // ============================================================
  Future<String?> _showCategoryBottomSheet({
    required BuildContext context,
    required List<String> categories,
    required String? selected,
    required double scale,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetCtx) {
        final search = ValueNotifier('');
        final maxHeight = MediaQuery.of(sheetCtx).size.height * 0.78;
        final s = scale.clamp(0.90, 1.20);

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                  color: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: (16 * s).clamp(14, 20),
                right: (16 * s).clamp(14, 20),
                top: (10 * s).clamp(8, 12),
                bottom: (16 * s).clamp(14, 20) +
                    MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Container(
                    height: 5,
                    width: (48 * s).clamp(44, 54),
                    decoration: BoxDecoration(
                      color: _cardBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),

                  Row(
                    children: [
                      Container(
                        height: (36 * s).clamp(34, 42),
                        width: (36 * s).clamp(34, 42),
                        decoration: BoxDecoration(
                          color: _accentBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: _accentBlue,
                          size: (20 * s).clamp(18, 24),
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(8, 12)),
                      Expanded(
                        child: Text(
                          'Pili ug Kategorya',
                          style: TextStyle(
                            fontSize: (16 * s).clamp(14, 18),
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),
                      ),

                      InkWell(
                        onTap: () => Navigator.pop(sheetCtx, '__add_new__'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: (12 * s).clamp(10, 14),
                            vertical: (9 * s).clamp(8, 10),
                          ),
                          decoration: BoxDecoration(
                            color: _accentBlue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _accentBlue.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add,
                                  size: (18 * s).clamp(16, 22),
                                  color: _accentBlue),
                              SizedBox(width: (6 * s).clamp(5, 8)),
                              Text(
                                'Add Kategorya',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _accentBlue,
                                  fontSize: (13 * s).clamp(12, 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),

                  ValueListenableBuilder<String>(
                    valueListenable: search,
                    builder: (_, value, _) => TextField(
                      onChanged: (v) => search.value = v,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search category...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: value.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => search.value = '',
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: (12 * s).clamp(10, 14),
                          vertical: (14 * s).clamp(12, 16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _accentBlue),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),

                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: search,
                      builder: (_, value, _) {
                        final q = value.trim().toLowerCase();
                        final filtered = q.isEmpty
                            ? categories
                            : categories
                                .where((e) => e.toLowerCase().contains(q))
                                .toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all((16 * s).clamp(14, 20)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: (56 * s).clamp(50, 66),
                                    width: (56 * s).clamp(50, 66),
                                    decoration: BoxDecoration(
                                      color: _fieldBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.search_off_rounded,
                                      color: _subtitleColor,
                                    ),
                                  ),
                                  SizedBox(height: (10 * s).clamp(8, 12)),
                                  Text(
                                    'Walay match nga category.',
                                    style: TextStyle(
                                      color: _subtitleColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: (13.5 * s).clamp(12.5, 15),
                                    ),
                                  ),
                                  SizedBox(height: (4 * s).clamp(3, 6)),
                                  Text(
                                    'Try lain nga keyword or add new category.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _subtitleColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: (12.8 * s).clamp(12, 14.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: (8 * s).clamp(6, 10)),
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final isSelected = item == selected;

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(sheetCtx, item),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (14 * s).clamp(12, 16),
                                  vertical: (12 * s).clamp(10, 14),
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _accentBlue.withOpacity(0.10)
                                      : _fieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? _accentBlue.withOpacity(0.35)
                                        : _cardBorder.withOpacity(0.8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: isSelected
                                              ? _accentBlue
                                              : _titleColor,
                                          fontSize: (14 * s).clamp(13, 16),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: _accentBlue,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: (8 * s).clamp(6, 10)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ ADD CATEGORY DIALOG (responsive only)
  // ============================================================
  Future<void> _showAddCategoryDialog(
    BuildContext context,
    StockInViewModel vm, {
    required double scale,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final value = ValueNotifier<String>('');
    final s = scale.clamp(0.90, 1.20);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: (18 * s).clamp(16, 24),
            vertical: (24 * s).clamp(20, 28),
          ),
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((24 * s).clamp(20, 28)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              (18 * s).clamp(16, 22),
              (18 * s).clamp(16, 22),
              (18 * s).clamp(16, 22),
              (16 * s).clamp(14, 20),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: (42 * s).clamp(38, 48),
                        width: (42 * s).clamp(38, 48),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accentBlue.withOpacity(0.18),
                              const Color(0xFF7CC8FF).withOpacity(0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            (14 * s).clamp(12, 18),
                          ),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: _accentBlue,
                          size: (22 * s).clamp(20, 26),
                        ),
                      ),
                      SizedBox(width: (12 * s).clamp(10, 14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pagdugang ug Bag-ong Kategorya",
                              style: TextStyle(
                                fontSize: (16 * s).clamp(14, 18),
                                fontWeight: FontWeight.w900,
                                color: _titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(dialogCtx),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: (36 * s).clamp(34, 40),
                          width: (36 * s).clamp(34, 40),
                          decoration: BoxDecoration(
                            color: _fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: _subtitleColor,
                            size: (20 * s).clamp(18, 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (16 * s).clamp(14, 18)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (12 * s).clamp(10, 14),
                      vertical: (10 * s).clamp(8, 12),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(
                        (14 * s).clamp(12, 18),
                      ),
                      border: Border.all(color: _cardBorder.withOpacity(0.9)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: _accentBlue,
                          size: (18 * s).clamp(16, 22),
                        ),
                        SizedBox(width: (8 * s).clamp(6, 10)),
                        Expanded(
                          child: Text(
                            "Pananglitan: Snacks, Inomnon, Pagkaon",
                            style: TextStyle(
                              color: _subtitleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: (12.8 * s).clamp(12, 14.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: (14 * s).clamp(12, 16)),
                  ValueListenableBuilder<String>(
                    valueListenable: value,
                    builder: (_, text, _) {
                      return TextFormField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        maxLength: 30,
                        decoration: InputDecoration(
                          counterText: "",
                          prefixIcon: Icon(
                            Icons.folder_open_rounded,
                            color: _accentBlue,
                            size: (20 * s).clamp(18, 24),
                          ),
                          labelText: "Ngalan sa Kategorya",
                          hintText: "e.g. Frozen Foods",
                          filled: true,
                          fillColor: _fieldBg,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: (14 * s).clamp(12, 16),
                            vertical: (16 * s).clamp(14, 18),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((14 * s).clamp(12, 18)),
                            borderSide: BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((14 * s).clamp(12, 18)),
                            borderSide: const BorderSide(color: _accentBlue, width: 1.4),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((14 * s).clamp(12, 18)),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((14 * s).clamp(12, 18)),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
                          ),
                        ),
                        onChanged: (v) => value.value = v,
                        onFieldSubmitted: (_) {
                          if (formKey.currentState?.validate() != true) return;
                          Navigator.pop(dialogCtx, controller.text);
                        },
                        validator: (v) {
                          final name = (v ?? '').trim();
                          if (name.isEmpty) return "Please enter a category name.";

                          final exists = vm.categoryNames.any(
                            (c) => c.trim().toLowerCase() == name.toLowerCase(),
                          );
                          if (exists) return "Category already exists.";

                          return null;
                        },
                      );
                    },
                  ),
                  SizedBox(height: (10 * s).clamp(8, 12)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _titleColor,
                            backgroundColor: _fieldBg,
                            side: BorderSide(color: _cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular((14 * s).clamp(12, 18)),
                            ),
                            padding: EdgeInsets.symmetric(vertical: (13 * s).clamp(11, 15)),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: (13.5 * s).clamp(12.5, 15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(8, 12)),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: value,
                          builder: (_, text, _) {
                            final canAdd = text.trim().isNotEmpty;
                            return ElevatedButton(
                              onPressed: canAdd
                                  ? () {
                                      if (formKey.currentState?.validate() != true) {
                                        return;
                                      }
                                      Navigator.pop(dialogCtx, controller.text);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentBlue,
                                disabledBackgroundColor: _accentBlue.withOpacity(0.30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular((14 * s).clamp(12, 18)),
                                ),
                                padding: EdgeInsets.symmetric(vertical: (13 * s).clamp(11, 15)),
                                elevation: 0,
                              ),
                              child: Text(
                                "Add",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: (13.5 * s).clamp(12.5, 15),
                                ),
                              ),
                            );
                          },
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

    final name = (result ?? '').trim();
    if (name.isEmpty) return;

    await vm.addNewCategory(name);
    vm.setCategoryByName(name);
  }

  Widget _card({
    required Widget child,
    required double padding,
    required double radius,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardLabel(String text, {required double scale}) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: (12.5 * scale).clamp(12, 14),
        fontWeight: FontWeight.w800,
        color: _subtitleColor,
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _costPerUnitBox(
    StockInViewModel vm, {
    required double scale,
    required double radius,
  }) {
    final cost =
        double.tryParse(vm.purchasePriceController.text.replaceAll(',', '').trim()) ??
            0;
    final qty = vm.useAdvancedUnitSetup
        ? vm.convertedPurchaseQuantity
        : int.tryParse(vm.quantityController.text.replaceAll(',', '').trim()) ?? 0;
    final hasValue = cost > 0 && qty > 0;
    final perUnit = hasValue ? cost / qty : 0.0;

    final unitDisplay = vm.baseUnitLabel.trim();
    final equivalentStock = hasValue
        ? '${qty % 1 == 0 ? qty.toInt() : qty} $unitDisplay'
        : '—';

    final divider = Divider(height: 1, color: _cardBorder);

    Widget previewRow(String label, String value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: (8 * scale).clamp(6, 10)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: (12.5 * scale).clamp(11.5, 14),
                  fontWeight: FontWeight.w600,
                  color: _subtitleColor,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: (13.5 * scale).clamp(12.5, 15),
                fontWeight: FontWeight.w800,
                color: _titleColor,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (16 * scale).clamp(14, 18),
        vertical: (14 * scale).clamp(12, 16),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _costPerUnitLabel(vm),
                  style: TextStyle(
                    fontSize: (13.5 * scale).clamp(12.5, 15),
                    fontWeight: FontWeight.w700,
                    color: _subtitleColor,
                  ),
                ),
              ),
              Text(
                hasValue ? _formatCostPerUnitDisplay(perUnit) : '—',
                style: TextStyle(
                  fontSize: (18 * scale).clamp(16, 22),
                  fontWeight: FontWeight.w900,
                  color: _titleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockTypePresetRow(
    StockInViewModel vm, {
    required double scale,
    required double radius,
  }) {
    final current = _currentStockType(vm);

    Widget chip(
      String value,
      IconData icon,
      String label,
      String example,
    ) {
      final selected = current == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () {
            setState(() {
              _applyStockTypePreset(vm, value);
              _showUnitOptions = value != 'piece';
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (10 * scale).clamp(8, 12),
              vertical: (12 * scale).clamp(10, 14),
            ),
            decoration: BoxDecoration(
              color: selected ? _accentBlue.withValues(alpha: 0.10) : Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? _accentBlue.withValues(alpha: 0.35)
                    : _cardBorder.withValues(alpha: 0.9),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: (20 * scale).clamp(18, 24),
                  color: selected ? _accentBlue : _subtitleColor,
                ),
                SizedBox(height: (4 * scale).clamp(3, 5)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (12.5 * scale).clamp(11.5, 14),
                    fontWeight: FontWeight.w800,
                    color: selected ? _accentBlue : _titleColor,
                  ),
                ),
                SizedBox(height: (2 * scale).clamp(2, 3)),
                Text(
                  example,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (10 * scale).clamp(9, 11),
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final gap = SizedBox(width: (8 * scale).clamp(6, 10));
    final rowGap = SizedBox(height: (8 * scale).clamp(6, 10));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paano mo ibinibilang ito?',
          style: TextStyle(
            fontSize: (13 * scale).clamp(12, 14.5),
            fontWeight: FontWeight.w700,
            color: _subtitleColor,
          ),
        ),
        SizedBox(height: (8 * scale).clamp(6, 10)),
        Row(
          children: [
            chip(
              'piece',
              Icons.tag_rounded,
              'Piraso',
              'itlog, sibuyas,\nbawang, lamas',
            ),
            gap,
            chip(
              'weight',
              Icons.scale_outlined,
              'Tinimbang',
              'asin, asukal,\nbigas',
            ),
          ],
        ),
        rowGap,
        Row(
          children: [
            chip(
              'liquid',
              Icons.water_drop_outlined,
              'Likido',
              'mantika, suka,\ntoyo',
            ),
            gap,
            chip(
              'pack',
              Icons.inventory_2_outlined,
              'Sachet',
              '3-in-1, sabon,\nshampoo',
            ),
          ],
        ),
      ],
    );
  }

  Widget _averageCostNote({
    required double scale,
    required double radius,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (12 * scale).clamp(10, 14),
        vertical: (10 * scale).clamp(8, 12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(radius),
        border: Border(
          left: BorderSide(
            color: const Color(0xFFEF9F27),
            width: (3 * scale).clamp(3, 4),
          ),
        ),
      ),
      child: Text(
        'This product already has stock. New cost will be merged using average cost method.',
        style: TextStyle(
          fontSize: (12.8 * scale).clamp(12, 14.5),
          fontWeight: FontWeight.w700,
          color: _subtitleColor,
        ),
      ),
    );
  }

  Widget _savedSetupNotice(
    StockInViewModel vm, {
    required double scale,
    required double radius,
  }) {
    final product = vm.selectedProduct;
    if (product == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((12 * scale).clamp(10, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Using saved setup for ${product.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: (14 * scale).clamp(13, 16),
                    color: _titleColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => vm.setEditSavedSetup(!vm.editSavedSetup),
                child: Text(vm.editSavedSetup ? 'Done editing' : 'Edit setup'),
              ),
            ],
          ),
          SizedBox(height: (4 * scale).clamp(3, 6)),
          Text(
            vm.editSavedSetup
                ? 'Update units, quick buttons, or photo only if this product setup changed.'
                : 'You only need to enter how much stock came in and how much you paid.',
            style: TextStyle(
              fontSize: (12.5 * scale).clamp(12, 14),
              fontWeight: FontWeight.w600,
              color: _subtitleColor,
            ),
          ),
          SizedBox(height: (8 * scale).clamp(6, 10)),
          Wrap(
            spacing: (8 * scale).clamp(6, 10),
            runSpacing: (8 * scale).clamp(6, 10),
            children: [
              _summaryPill('Unit: ${vm.baseUnitLabel}', scale: scale),
              _summaryPill(
                'Quick buttons: ${vm.sellingOptions.length}',
                scale: scale,
              ),
              _summaryPill(
                'More units: ${vm.unitConversions.length}',
                scale: scale,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, {required double scale}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (10 * scale).clamp(8, 12),
        vertical: (6 * scale).clamp(5, 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: (12 * scale).clamp(11.5, 13.5),
          fontWeight: FontWeight.w800,
          color: _titleColor,
        ),
      ),
    );
  }

  Widget _baseUnitPickerField(
    StockInViewModel vm, {
    required double scale,
    required double radius,
    required double valueFs,
  }) {
    final isError =
        vm.showValidationErrors && vm.baseUnitController.text.trim().isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () async {
        final selected = await _showBaseUnitBottomSheet(
          context: context,
          units: vm.baseUnitOptions,
          selected: vm.baseUnitController.text.trim(),
          scale: scale,
          allowManageActions: true,
        );

        if (selected == null) return;
        if (selected == '__add_new__') {
          await _showAddBaseUnitDialog(context, vm, scale: scale);
          return;
        }
        if (selected.startsWith('edit::')) {
          final unitName = selected.replaceFirst('edit::', '');
          await _showEditBaseUnitDialog(
            context,
            vm,
            unitName,
            scale: scale,
          );
          return;
        }
        if (selected.startsWith('delete::')) {
          final unitName = selected.replaceFirst('delete::', '');
          await vm.deleteBaseUnitChoice(unitName);
          return;
        }

        vm.setBaseUnit(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: Icon(
            Icons.straighten_rounded,
            color: _accentBlue,
            size: (22 * scale).clamp(20, 26),
          ),
          labelText: 'Smallest unit',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: isError ? Colors.red : _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: isError ? Colors.red : _accentBlue),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                vm.baseUnitController.text.trim().isEmpty
                    ? 'Select unit'
                    : vm.baseUnitController.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: valueFs,
                  fontWeight: FontWeight.w800,
                  color: vm.baseUnitController.text.trim().isEmpty
                      ? _subtitleColor
                      : _titleColor,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _subtitleColor,
              size: (22 * scale).clamp(20, 26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purchaseUnitPickerField(
    StockInViewModel vm, {
    required double scale,
    required double radius,
    required double valueFs,
  }) {
    final isError =
        vm.showValidationErrors && vm.purchaseUnitController.text.trim().isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () => _showSukodSheet(vm, scale: scale),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: Icon(
            Icons.inventory_2_outlined,
            color: _accentBlue,
            size: (22 * scale).clamp(20, 26),
          ),
          labelText: 'Unsa nga sukod?',
          helperText: _boughtAsHelperText(vm),
          helperStyle: TextStyle(
            fontSize: (11 * scale).clamp(10, 12.5),
            color: _subtitleColor,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: isError ? Colors.red : _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: isError ? Colors.red : _accentBlue),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                vm.purchaseUnitController.text.trim().isEmpty
                    ? 'Select unit'
                    : vm.purchaseUnitController.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: valueFs,
                  fontWeight: FontWeight.w800,
                  color: vm.purchaseUnitController.text.trim().isEmpty
                      ? _subtitleColor
                      : _titleColor,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _subtitleColor,
              size: (22 * scale).clamp(20, 26),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSukodSheet(StockInViewModel vm, {required double scale}) async {
    final stockType = _currentStockType(vm);
    final existingUnits = vm.purchaseUnitOptions
        .where((u) => u.trim().toLowerCase() != vm.baseUnitLabel.trim().toLowerCase())
        .toList();

    // Quick-add suggestions per type (name → baseQuantity)
    final Map<String, double> suggestions = switch (stockType) {
      'weight' => {'kilo': 1000, 'sack': 50000, 'bag': 500},
      'liquid' => {'liter': 1000, 'gallon': 3785, 'bottle': 500},
      'pack'   => {'box': 24, 'dozen': 12, 'tray': 30},
      _        => {'box': 24, 'dozen': 12, 'tray': 30},
    };

    String? pendingNewUnit;
    final sizeCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Unsa nga sukod?',
                      style: TextStyle(
                        fontSize: (17 * scale).clamp(15, 19),
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: EdgeInsets.all((16 * scale).clamp(14, 20)),
                      children: [
                        // Existing units
                        if (existingUnits.isNotEmpty) ...[
                          Text(
                            'Existing units',
                            style: TextStyle(
                              fontSize: (12.5 * scale).clamp(11.5, 14),
                              fontWeight: FontWeight.w700,
                              color: _subtitleColor,
                            ),
                          ),
                          SizedBox(height: (8 * scale).clamp(6, 10)),
                          Wrap(
                            spacing: (8 * scale).clamp(6, 10),
                            runSpacing: (8 * scale).clamp(6, 10),
                            children: existingUnits.map((unit) {
                              final selected = vm.purchaseUnitController.text.trim().toLowerCase() == unit.trim().toLowerCase();
                              return GestureDetector(
                                onTap: () {
                                  vm.setPurchaseUnit(unit);
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (14 * scale).clamp(12, 16),
                                    vertical: (8 * scale).clamp(7, 10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected ? _accentBlue : _accentBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected ? _accentBlue : _accentBlue.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: (13.5 * scale).clamp(12.5, 15),
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : _accentBlue,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: (16 * scale).clamp(12, 20)),
                        ],

                        // Quick-add suggestions
                        Text(
                          'Dugangi',
                          style: TextStyle(
                            fontSize: (12.5 * scale).clamp(11.5, 14),
                            fontWeight: FontWeight.w700,
                            color: _subtitleColor,
                          ),
                        ),
                        SizedBox(height: (8 * scale).clamp(6, 10)),
                        Wrap(
                          spacing: (8 * scale).clamp(6, 10),
                          runSpacing: (8 * scale).clamp(6, 10),
                          children: suggestions.entries.map((entry) {
                            final alreadyExists = vm.unitConversions.any(
                              (c) => c.unitName.trim().toLowerCase() == entry.key.toLowerCase(),
                            );
                            if (alreadyExists) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () {
                                vm.conversionNameController.text = entry.key;
                                vm.conversionQuantityController.text = entry.value.toStringAsFixed(0);
                                vm.addUnitConversion();
                                vm.setPurchaseUnit(entry.key);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (14 * scale).clamp(12, 16),
                                  vertical: (8 * scale).clamp(7, 10),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  '+ ${entry.key} (${entry.value.toStringAsFixed(0)} ${vm.baseUnitLabel})',
                                  style: TextStyle(
                                    fontSize: (13 * scale).clamp(12, 14.5),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Custom unit section
                        SizedBox(height: (16 * scale).clamp(12, 20)),
                        if (pendingNewUnit == null)
                          GestureDetector(
                            onTap: () => setSheet(() => pendingNewUnit = ''),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: (14 * scale).clamp(12, 16),
                                vertical: (10 * scale).clamp(8, 12),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline_rounded,
                                      color: _subtitleColor,
                                      size: (20 * scale).clamp(18, 24)),
                                  SizedBox(width: (8 * scale).clamp(6, 10)),
                                  Text(
                                    'Iba pa (custom)...',
                                    style: TextStyle(
                                      fontSize: (13.5 * scale).clamp(12.5, 15),
                                      fontWeight: FontWeight.w600,
                                      color: _subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            'Bag-ong unit',
                            style: TextStyle(
                              fontSize: (12.5 * scale).clamp(11.5, 14),
                              fontWeight: FontWeight.w700,
                              color: _subtitleColor,
                            ),
                          ),
                          SizedBox(height: (8 * scale).clamp(6, 10)),
                          TextField(
                            controller: sizeCtrl,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _fieldBg,
                              labelText: 'Pila ka ${vm.baseUnitLabel} ang 1 ${pendingNewUnit!.isEmpty ? "unit" : pendingNewUnit!}?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (v) => setSheet(() {}),
                          ),
                          SizedBox(height: (8 * scale).clamp(6, 10)),
                          TextField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _fieldBg,
                              labelText: 'Ngalan sa unit (e.g. galon, bote)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (v) => setSheet(() => pendingNewUnit = v),
                          ),
                          SizedBox(height: (10 * scale).clamp(8, 12)),
                          ElevatedButton(
                            onPressed: () {
                              final name = pendingNewUnit!.trim();
                              final qty = double.tryParse(sizeCtrl.text.trim()) ?? 0;
                              if (name.isEmpty || qty <= 0) return;
                              vm.conversionNameController.text = name;
                              vm.conversionQuantityController.text = qty.toStringAsFixed(0);
                              vm.addUnitConversion();
                              vm.setPurchaseUnit(name);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('I-save'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showBaseUnitBottomSheet({
    required BuildContext context,
    required List<String> units,
    required String? selected,
    required double scale,
    String title = 'Select smallest unit',
    String? addButtonLabel = 'Add Unit',
    bool allowManageActions = false,
    String? baseUnitLabel,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetCtx) {
        final search = ValueNotifier('');
        final maxHeight = MediaQuery.of(sheetCtx).size.height * 0.78;
        final s = scale.clamp(0.90, 1.20);

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                  color: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: (16 * s).clamp(14, 20),
                right: (16 * s).clamp(14, 20),
                top: (10 * s).clamp(8, 12),
                bottom: (16 * s).clamp(14, 20) +
                    MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Container(
                    height: 5,
                    width: (48 * s).clamp(44, 54),
                    decoration: BoxDecoration(
                      color: _cardBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),
                  Row(
                    children: [
                      Container(
                        height: (36 * s).clamp(34, 42),
                        width: (36 * s).clamp(34, 42),
                        decoration: BoxDecoration(
                          color: _accentBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(
                            (12 * s).clamp(10, 16),
                          ),
                        ),
                        child: Icon(
                          Icons.straighten_rounded,
                          color: _accentBlue,
                          size: (20 * s).clamp(18, 24),
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(8, 12)),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: (16 * s).clamp(14, 18),
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),
                      ),
                      if (addButtonLabel != null)
                        InkWell(
                          onTap: () => Navigator.pop(sheetCtx, '__add_new__'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (12 * s).clamp(10, 14),
                              vertical: (9 * s).clamp(8, 10),
                            ),
                            decoration: BoxDecoration(
                              color: _accentBlue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _accentBlue.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  size: (18 * s).clamp(16, 22),
                                  color: _accentBlue,
                                ),
                                SizedBox(width: (6 * s).clamp(5, 8)),
                                Text(
                                  addButtonLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _accentBlue,
                                    fontSize: (13 * s).clamp(12, 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),
                  ValueListenableBuilder<String>(
                    valueListenable: search,
                    builder: (_, value, _) => TextField(
                      onChanged: (v) => search.value = v,
                      decoration: InputDecoration(
                        hintText: 'Search unit...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: value.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => search.value = '',
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: _fieldBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _accentBlue),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: search,
                      builder: (_, value, _) {
                        final q = value.trim().toLowerCase();
                        final filtered = q.isEmpty
                            ? units
                            : units
                                .where((unit) => unit.toLowerCase().contains(q))
                                .toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'Walay match nga base unit.',
                              style: TextStyle(
                                color: _subtitleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: (8 * s).clamp(6, 10)),
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final isSelected = item == selected;

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(sheetCtx, item),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (14 * s).clamp(12, 16),
                                  vertical: (12 * s).clamp(10, 14),
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _accentBlue.withOpacity(0.10)
                                      : _fieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? _accentBlue.withOpacity(0.35)
                                        : _cardBorder.withOpacity(0.8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: isSelected
                                              ? _accentBlue
                                              : _titleColor,
                                          fontSize: (14 * s).clamp(13, 16),
                                        ),
                                      ),
                                    ),
                                    if (allowManageActions &&
                                        (baseUnitLabel == null ||
                                            item.trim().toLowerCase() !=
                                                baseUnitLabel.trim().toLowerCase()))
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_horiz_rounded,
                                          color: isSelected
                                              ? _accentBlue
                                              : _subtitleColor,
                                        ),
                                        onSelected: (action) {
                                          Navigator.pop(
                                            sheetCtx,
                                            '$action::$item',
                                          );
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      )
                                    else if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: _accentBlue,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: (8 * s).clamp(6, 10)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddBaseUnitDialog(
    BuildContext context,
    StockInViewModel vm, {
    required double scale,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final value = ValueNotifier<String>('');
    final s = scale.clamp(0.90, 1.20);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((18 * s).clamp(16, 22)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              (16 * s).clamp(14, 20),
              (14 * s).clamp(12, 18),
              (16 * s).clamp(14, 20),
              (12 * s).clamp(10, 16),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pagdugang ug Bag-ong Base Unit',
                          style: TextStyle(
                            fontSize: (16 * s).clamp(14, 18),
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: (10 * s).clamp(8, 12)),
                  Text(
                    'Example: bottle, litro, box, kilo',
                    style: TextStyle(
                      color: _subtitleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: (13.5 * s).clamp(12.5, 15),
                    ),
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),
                  ValueListenableBuilder<String>(
                    valueListenable: value,
                    builder: (_, text, _) {
                      return TextFormField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 40,
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.straighten_rounded),
                          labelText: 'Unit name',
                          hintText: 'e.g. bottle',
                          filled: true,
                          fillColor: _fieldBg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              (12 * s).clamp(10, 16),
                            ),
                            borderSide: BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              (12 * s).clamp(10, 16),
                            ),
                            borderSide: const BorderSide(color: _accentBlue),
                          ),
                        ),
                        onChanged: (v) => value.value = v,
                        validator: (v) {
                          final name = (v ?? '').trim();
                          if (name.isEmpty) return 'Please enter a base unit.';

                          final exists = vm.baseUnitOptions.any(
                            (item) => item.trim().toLowerCase() == name.toLowerCase(),
                          );
                          if (exists) return 'Base unit already exists.';
                          return null;
                        },
                      );
                    },
                  ),
                  SizedBox(height: (6 * s).clamp(4, 10)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(8, 12)),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: value,
                          builder: (_, text, _) {
                            return ElevatedButton(
                              onPressed: text.trim().isEmpty
                                  ? null
                                  : () {
                                      if (formKey.currentState?.validate() != true) {
                                        return;
                                      }
                                      Navigator.pop(dialogCtx, controller.text);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentBlue,
                                elevation: 0,
                              ),
                              child: const Text('Add'),
                            );
                          },
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

    final trimmed = (result ?? '').trim();
    if (trimmed.isNotEmpty) {
      await vm.addNewBaseUnit(trimmed);
    }
  }

  Future<void> _showEditBaseUnitDialog(
    BuildContext context,
    StockInViewModel vm,
    String currentUnit, {
    required double scale,
  }) async {
    final controller = TextEditingController(text: currentUnit);
    final formKey = GlobalKey<FormState>();
    final value = ValueNotifier<String>(currentUnit);
    final s = scale.clamp(0.90, 1.20);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((18 * s).clamp(16, 22)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              (16 * s).clamp(14, 20),
              (14 * s).clamp(12, 18),
              (16 * s).clamp(14, 20),
              (12 * s).clamp(10, 16),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Base Unit',
                          style: TextStyle(
                            fontSize: (16 * s).clamp(14, 18),
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: (10 * s).clamp(8, 12)),
                  ValueListenableBuilder<String>(
                    valueListenable: value,
                    builder: (_, text, _) {
                      return TextFormField(
                        controller: controller,
                        maxLength: 40,
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.straighten_rounded),
                          labelText: 'Unit name',
                          filled: true,
                          fillColor: _fieldBg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              (12 * s).clamp(10, 16),
                            ),
                            borderSide: BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              (12 * s).clamp(10, 16),
                            ),
                            borderSide: const BorderSide(color: _accentBlue),
                          ),
                        ),
                        onChanged: (v) => value.value = v,
                        validator: (v) {
                          final name = (v ?? '').trim();
                          if (name.isEmpty) return 'Please enter a base unit.';

                          final exists = vm.baseUnitOptions.any(
                            (item) =>
                                item.trim().toLowerCase() == name.toLowerCase() &&
                                item.trim().toLowerCase() !=
                                    currentUnit.trim().toLowerCase(),
                          );
                          if (exists) return 'Base unit already exists.';
                          return null;
                        },
                      );
                    },
                  ),
                  SizedBox(height: (6 * s).clamp(4, 10)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(8, 12)),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: value,
                          builder: (_, text, _) {
                            return ElevatedButton(
                              onPressed: text.trim().isEmpty
                                  ? null
                                  : () {
                                      if (formKey.currentState?.validate() != true) {
                                        return;
                                      }
                                      Navigator.pop(dialogCtx, controller.text);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentBlue,
                                elevation: 0,
                              ),
                              child: const Text('Save'),
                            );
                          },
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

    final trimmed = (result ?? '').trim();
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != currentUnit.toLowerCase()) {
      await vm.updateBaseUnitChoice(currentUnit, trimmed);
    }
  }

  // ============================================================
  // INPUTS (responsive params)
  // ============================================================
  Widget _inputDate(
    StockInViewModel vm, {
    required double height,
    required double radius,
    required double valueFs,
  }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        readOnly: true,
        initialValue: vm.formattedDate,
        onTap: () async {
          final today = DateTime.now();
          final initialDate = vm.selectedDate.isAfter(today) ? today : vm.selectedDate;

          final picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2020),
            lastDate: today,
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: _accentBlue,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            ),
          );

          if (picked != null) vm.pickDate(picked);
        },
        style: TextStyle(
          color: _titleColor,
          fontWeight: FontWeight.bold,
          fontSize: valueFs,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: const Icon(Icons.calendar_today, color: _accentBlue),
          labelText: 'Petsa',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _accentBlue),
          ),
        ),
      ),
    );
  }

  Widget _autocompleteProduct(
    StockInViewModel vm, {
    required double scale,
    required double height,
    required double radius,
    required double optionFs,
    required double valueFs,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        return vm.productNames.where(
          (name) => name.toLowerCase().startsWith(value.text.toLowerCase()),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(radius),
            color: _cardBg,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
                maxWidth: MediaQuery.of(context).size.width - (32 * scale).clamp(28, 44),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: _cardBorder.withOpacity(0.8)),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      await Future.delayed(const Duration(milliseconds: 50));
                      onSelected(option);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (14 * scale).clamp(12, 18),
                        vertical: (14 * scale).clamp(12, 18),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: _titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: optionFs,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, fieldController, focusNode, onSubmit) {
        vm.autocompleteFieldController = fieldController;

        return SizedBox(
          height: height,
          child: TextField(
            controller: fieldController,
            focusNode: focusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontSize: valueFs, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              labelText: 'Pangalan sa produkto',
              prefixIcon: const Icon(Icons.edit, color: _accentBlue),
              filled: true,
              fillColor: _fieldBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(
                  color: (vm.showValidationErrors &&
                          vm.effectiveProductName.trim().isEmpty)
                      ? Colors.red
                      : _cardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(
                  color: (vm.showValidationErrors &&
                          vm.effectiveProductName.trim().isEmpty)
                      ? Colors.red
                      : _accentBlue,
                ),
              ),
            ),
            onChanged: (value) {
              vm.productController.text = value;
              if (vm.selectedProduct != null &&
                  vm.selectedProduct!.name.toLowerCase() != value.toLowerCase()) {
                vm.clearSelectedProductLink();
              }
            },
          ),
        );
      },
      onSelected: (value) async {
        final product = vm.allProducts.firstWhere((p) => p.name == value);
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 50));
        await vm.populateFromSelectedProduct(product);
      },
    );
  }

  Widget _inputTextField({
    required String label,
    required TextEditingController controller,
    required bool showError,
    required IconData icon,
    ValueChanged<String>? onChanged,
    required double scale,
    required double height,
    required double radius,
    required double valueFs,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: valueFs,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: Icon(icon, color: _accentBlue, size: (22 * scale).clamp(20, 26)),
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: showError && controller.text.trim().isEmpty
                  ? Colors.red
                  : _cardBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: showError && controller.text.trim().isEmpty
                  ? Colors.red
                  : _accentBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _advancedOptionRow({
    required String title,
    required String description,
    required bool isOn,
    required double scale,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular((14 * scale).clamp(12, 18)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: (14 * scale).clamp(12, 16),
          vertical: (14 * scale).clamp(12, 16),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular((14 * scale).clamp(12, 18)),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: (14.5 * scale).clamp(13.5, 16),
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                    ),
                  ),
                  SizedBox(height: (4 * scale).clamp(3, 6)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: (12.8 * scale).clamp(12, 14.5),
                      fontWeight: FontWeight.w600,
                      color: _subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: (12 * scale).clamp(10, 14)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: (44 * scale).clamp(40, 48),
              height: (26 * scale).clamp(24, 30),
              padding: EdgeInsets.all((3 * scale).clamp(2.5, 3.5)),
              decoration: BoxDecoration(
                color: isOn ? const Color(0xFF1D9E75) : const Color(0xFFCCD6E9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: (20 * scale).clamp(18, 22),
                  height: (20 * scale).clamp(18, 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _suggestedPurchaseUnits(StockInViewModel vm) {
    final base = vm.baseUnitLabel.toLowerCase();
    if (base == 'gram' || base == 'grams' || base == 'g') {
      return const ['kilo', 'sack', 'pack'];
    }
    if (base == 'ml' || base == 'milliliter' || base == 'millilitre') {
      return const ['liter', 'bottle', 'gallon'];
    }
    if (base == 'pcs') {
      return const ['box', 'tray', 'pack'];
    }
    return const ['pack', 'box', 'tray'];
  }

  String _quantityUnitLabel(StockInViewModel vm) {
    final unit = vm.baseUnitLabel.trim();
    if (unit.isEmpty) return 'unit';

    final normalized = unit.toLowerCase();
    if (normalized == 'pcs' ||
        normalized == 'pc' ||
        normalized == 'piece' ||
        normalized == 'pieces') {
      return 'pieces';
    }
    if (normalized == 'half' || normalized == 'tungaon') return 'halves';
    return unit;
  }

  bool _isWeightBaseUnit(StockInViewModel vm) {
    final normalized = vm.baseUnitLabel.trim().toLowerCase();
    return normalized == 'gram' || normalized == 'grams' || normalized == 'g';
  }

  bool _isLiquidBaseUnit(StockInViewModel vm) {
    final normalized = vm.baseUnitLabel.trim().toLowerCase();
    return normalized == 'ml' ||
        normalized == 'milliliter' ||
        normalized == 'millilitre';
  }

  bool _isPackBaseUnit(StockInViewModel vm) {
    final normalized = vm.baseUnitLabel.trim().toLowerCase();
    return normalized == 'half' || normalized == 'tungaon';
  }

  bool _isPieceBaseUnit(StockInViewModel vm) {
    final normalized = vm.baseUnitLabel.trim().toLowerCase();
    return normalized == 'pcs' ||
        normalized == 'pc' ||
        normalized == 'piece' ||
        normalized == 'pieces';
  }

  List<({String label, int quantity})> _pieceQuickSaleSuggestions(
    StockInViewModel vm,
  ) {
    if (!_isPieceBaseUnit(vm)) return const [];
    return const [
      (label: '1 kilo', quantity: 0),
      (label: '3 pcs', quantity: 3),
      (label: '6 pcs', quantity: 6),
      (label: '1 dozen', quantity: 12),
    ];
  }

  List<({String label, int quantity})> _liquidQuickSaleSuggestions(
    StockInViewModel vm,
  ) {
    if (!_isLiquidBaseUnit(vm)) return const [];
    return const [
      (label: '1 flat / lapad', quantity: 375),
      (label: '1/2 liter', quantity: 500),
      (label: '1 liter', quantity: 1000),
    ];
  }

  List<({String label, int quantity})> _packQuickSaleSuggestions(
    StockInViewModel vm,
  ) {
    if (!_isPackBaseUnit(vm)) return const [];
    return const [
      (label: 'Tungaon', quantity: 1),
      (label: '1 Sachet', quantity: 2),
      (label: '6 pcs', quantity: 12),
      (label: '1 Dozen', quantity: 24),
    ];
  }

  Widget _unitConversionSection(
    StockInViewModel vm, {
    required double scale,
    required double radius,
    required double valueFs,
    required double gap12,
  }) {
    final suggestedUnits = _suggestedPurchaseUnits(vm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap a common size to auto-fill it, or type your own custom unit.',
          style: TextStyle(
            fontSize: (valueFs - 1).clamp(12, 15),
            fontWeight: FontWeight.w600,
            color: _subtitleColor,
          ),
        ),
        SizedBox(height: gap12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final unit in suggestedUnits)
              ActionChip(
                label: Text(unit),
                onPressed: () => setState(() {
                  _applySuggestedVariant(vm, unit);
                }),
              ),
          ],
        ),
        SizedBox(height: gap12),
        Row(
          children: [
            Expanded(
              child: _inputTextField(
                label: 'Unit name',
                controller: vm.conversionNameController,
                showError: false,
                icon: Icons.label_outline_rounded,
                onChanged: (text) => setState(() {
                  final suggestedQty = _suggestedBaseQuantity(vm, text);
                  if (suggestedQty != null) {
                    vm.conversionQuantityController.text = suggestedQty;
                  } else {
                    vm.conversionQuantityController.clear();
                  }
                }),
                scale: scale,
                height: (58 * scale).clamp(54, 66),
                radius: radius,
                valueFs: valueFs,
              ),
            ),
            SizedBox(width: gap12),
            Expanded(
              child: _inputNumberField(
                label: '${_quantityUnitLabel(vm)} per unit',
                controller: vm.conversionQuantityController,
                showError: false,
                icon: Icons.water_drop_outlined,
                scale: scale,
                height: (58 * scale).clamp(54, 66),
                radius: radius,
                valueFs: valueFs,
              ),
            ),
            SizedBox(width: gap12),
            Expanded(
              child: _inputNumberField(
                label: 'Sell price (optional)',
                controller: vm.conversionPriceController,
                showError: false,
                isPeso: true,
                icon: Icons.sell_outlined,
                scale: scale,
                height: (58 * scale).clamp(54, 66),
                radius: radius,
                valueFs: valueFs,
              ),
            ),
          ],
        ),
        SizedBox(height: gap12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: vm.addUnitConversion,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add wholesale unit'),
          ),
        ),
        if (vm.unitConversions.isNotEmpty) ...[
          SizedBox(height: gap12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vm.unitConversions.map((conversion) {
              return _conversionChip(conversion, vm);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _conversionChip(
    ProductUnitConversion conversion,
    StockInViewModel vm,
  ) {
    final priceText = (conversion.sellPrice != null && conversion.sellPrice! > 0)
        ? ' · ₱${conversion.sellPrice!.toStringAsFixed(conversion.sellPrice! % 1 == 0 ? 0 : 2)}'
        : '';
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _showEditPurchaseUnitDialog(
        context,
        vm,
        conversion,
        scale: MediaQuery.of(context).size.width / 390,
      ),
      child: Chip(
        label: Text(
          '${conversion.unitName} = ${conversion.baseQuantity} ${vm.baseUnitLabel}$priceText',
        ),
        onDeleted: () => vm.removeUnitConversion(conversion),
        deleteIcon: const Icon(Icons.close_rounded, size: 18),
        backgroundColor: Colors.white,
        side: BorderSide(color: _cardBorder.withOpacity(0.9)),
      ),
    );
  }

  Widget _unitReferenceDropdown({
    required List<String> options,
    required String value,
    required ValueChanged<String?> onChanged,
    required double scale,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Of unit',
        filled: true,
        fillColor: _fieldBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((12 * scale).clamp(10, 16)),
          borderSide: BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((12 * scale).clamp(10, 16)),
          borderSide: const BorderSide(color: _accentBlue),
        ),
      ),
      items: options
          .map(
            (unit) => DropdownMenuItem<String>(
              value: unit,
              child: Text(unit),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _showEditPurchaseUnitDialog(
    BuildContext context,
    StockInViewModel vm,
    ProductUnitConversion conversion, {
    required double scale,
  }) async {
    final unitController = TextEditingController(text: conversion.unitName);
    final quantityController = TextEditingController(
      text: conversion.baseQuantity.toString(),
    );
    final sellPriceController = TextEditingController(
      text: (conversion.sellPrice != null && conversion.sellPrice! > 0)
          ? conversion.sellPrice!.toStringAsFixed(
              conversion.sellPrice! % 1 == 0 ? 0 : 2,
            )
          : '',
    );
    final formKey = GlobalKey<FormState>();
    final qtyValue = ValueNotifier<String>(conversion.baseQuantity.toString());
    final referenceUnit = ValueNotifier<String>(vm.baseUnitLabel);
    final s = scale.clamp(0.90, 1.20);

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((18 * s).clamp(16, 22)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              (16 * s).clamp(14, 20),
              (14 * s).clamp(12, 18),
              (16 * s).clamp(14, 20),
              (12 * s).clamp(10, 16),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Unit',
                          style: TextStyle(
                            fontSize: (16 * s).clamp(14, 18),
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    'Update the unit name or what known unit it equals.',
                    style: TextStyle(
                      color: _subtitleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: (13.5 * s).clamp(12.5, 15),
                    ),
                  ),
                  if (vm.baseUnitLabel.toLowerCase() == 'pcs') ...[
                    SizedBox(height: (10 * s).clamp(8, 12)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all((10 * s).clamp(8, 12)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAEEDA),
                        borderRadius: BorderRadius.circular(
                          (12 * s).clamp(10, 16),
                        ),
                      ),
                      child: Text(
                        'For rice or weight-based products, change Smallest unit to gram first before using kilo or sack.',
                        style: TextStyle(
                          color: _subtitleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: (12.5 * s).clamp(12, 14),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: (12 * s).clamp(10, 14)),
                  TextFormField(
                    controller: unitController,
                    maxLength: 40,
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      labelText: 'Unit name',
                      filled: true,
                      fillColor: _fieldBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          (12 * s).clamp(10, 16),
                        ),
                        borderSide: BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          (12 * s).clamp(10, 16),
                        ),
                        borderSide: const BorderSide(color: _accentBlue),
                      ),
                    ),
                    validator: (text) {
                      final name = (text ?? '').trim();
                      if (name.isEmpty) return 'Please enter a unit name.';
                      if (vm.baseUnitLabel.toLowerCase() == 'pcs' &&
                          _isWeightUnitName(name)) {
                        return 'Set Smallest unit to gram first for weight units.';
                      }
                      final exists = vm.unitConversions.any(
                        (item) =>
                            item.unitName.trim().toLowerCase() ==
                                name.toLowerCase() &&
                            item.unitName.trim().toLowerCase() !=
                                conversion.unitName.trim().toLowerCase(),
                      );
                      if (exists) return 'Unit already exists.';
                      return null;
                    },
                  ),
                  SizedBox(height: (10 * s).clamp(8, 12)),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (text) => qtyValue.value = text,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.straighten_rounded),
                            labelText: 'How many?',
                            filled: true,
                            fillColor: _fieldBg,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                (12 * s).clamp(10, 16),
                              ),
                              borderSide: BorderSide(color: _cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                (12 * s).clamp(10, 16),
                              ),
                              borderSide:
                                  const BorderSide(color: _accentBlue),
                            ),
                          ),
                          validator: (text) {
                            final qty = int.tryParse((text ?? '').trim()) ?? 0;
                            if (qty <= 0) return 'Enter a valid quantity.';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(8, 12)),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: referenceUnit,
                          builder: (context, currentUnit, child) {
                            return _unitReferenceDropdown(
                              options: vm.purchaseUnitOptions,
                              value: currentUnit,
                              onChanged: (value) {
                                if (value != null) {
                                  referenceUnit.value = value;
                                }
                              },
                              scale: s,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (6 * s).clamp(4, 10)),
                  ValueListenableBuilder<String>(
                    valueListenable: qtyValue,
                    builder: (context, qtyText, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: referenceUnit,
                        builder: (context, currentUnit, child) {
                          final qty = int.tryParse(qtyText.trim()) ?? 0;
                          final converted = qty <= 0
                              ? 0
                              : qty * vm.quantityFactorFor(currentUnit);
                          return Text(
                            converted > 0
                                ? 'This will be saved as $converted ${vm.baseUnitLabel}.'
                                : 'The app will save stock in ${vm.baseUnitLabel}.',
                            style: TextStyle(
                              color: _subtitleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: (12.8 * s).clamp(12, 14.5),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: (10 * s).clamp(8, 12)),
                  TextFormField(
                    controller: sellPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.sell_outlined),
                      prefixText: '₱ ',
                      labelText: 'Wholesale sell price (optional)',
                      filled: true,
                      fillColor: _fieldBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          (12 * s).clamp(10, 16),
                        ),
                        borderSide: BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          (12 * s).clamp(10, 16),
                        ),
                        borderSide: const BorderSide(color: _accentBlue),
                      ),
                    ),
                  ),
                  SizedBox(height: (12 * s).clamp(10, 14)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(8, 12)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() != true) return;
                            Navigator.pop(dialogCtx, {
                              'name': unitController.text.trim(),
                              'qty': quantityController.text.trim(),
                              'reference': referenceUnit.value,
                              'sell_price': sellPriceController.text.trim(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentBlue,
                            elevation: 0,
                          ),
                          child: const Text('Save'),
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

    unitController.dispose();
    quantityController.dispose();
    sellPriceController.dispose();

    final name = (result?['name'] ?? '').trim();
    final qtyText = (result?['qty'] ?? '').trim();
    final reference = (result?['reference'] ?? vm.baseUnitLabel).trim();
    final sellPriceText = (result?['sell_price'] ?? '').trim().replaceAll(',', '');
    final qty = int.tryParse(qtyText) ?? 0;
    if (name.isEmpty || qty <= 0) return;
    final convertedQty = qty * vm.quantityFactorFor(reference);
    if (convertedQty <= 0) return;
    final sellPrice = double.tryParse(sellPriceText);

    vm.updateUnitConversion(
      conversion,
      unitName: name,
      baseQuantity: convertedQty,
      sellPrice: sellPrice,
    );
  }

  bool _isWeightUnitName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'kilo' ||
        normalized == 'kilogram' ||
        normalized == 'kilograms' ||
        normalized == 'kg' ||
        normalized == 'gram' ||
        normalized == 'grams' ||
        normalized == 'g';
  }

  Widget _sellingOptionsSection(
    StockInViewModel vm, {
    required double scale,
    required double radius,
    required double valueFs,
    required double gap12,
  }) {
    final isLiquid = _isLiquidBaseUnit(vm);
    final isPack = _isPackBaseUnit(vm);
    final isPiece = _isPieceBaseUnit(vm);
    final isWeight = _isWeightBaseUnit(vm);
    final liquidSuggestions = _liquidQuickSaleSuggestions(vm);
    final packSuggestions = _packQuickSaleSuggestions(vm);
    final pieceSuggestions = _pieceQuickSaleSuggestions(vm);
    // Weight: common per-piece sales (quantity=0 means user fills grams manually)
    const weightSuggestions = <({String label, int quantity})>[
      (label: '1 piece', quantity: 0),
      (label: '¼ kilo', quantity: 250),
      (label: '½ kilo', quantity: 500),
      (label: '1 kilo', quantity: 1000),
    ];
    final suggestions = isPack
        ? packSuggestions
        : isLiquid
            ? liquidSuggestions
            : isPiece
                ? pieceSuggestions
                : isWeight
                    ? weightSuggestions
                    : const <({String label, int quantity})>[];
    final currentLabel =
        vm.sellingOptionLabelController.text.trim().toLowerCase();
    final isKiloLabel =
        currentLabel == '1 kilo' || currentLabel == 'kilo' || currentLabel == 'kg';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPack
              ? 'Tap a preset to auto-fill (Tungaon, 1 Sachet, 6 pcs, 1 Dozen), or type your own.'
              : isLiquid
                  ? 'Optional only. Add common liquid sales like 1 flat/lapad, 1/2 liter, or 1 liter so the cashier can tap faster later.'
                  : isWeight
                      ? 'For per-piece selling (e.g. 1 sibuyas = 50g = ₱2), tap "1 piece" and enter the grams and price. Also add ¼ or ½ kilo quick buttons.'
                      : isPiece
                          ? 'Add quick sale buttons like "3 pcs" or "1 dozen". For products also sold by kilo (like sibuyas), tap "1 kilo" and enter how many pieces equal 1 kilo.'
                          : 'Optional only. Add common quick buttons like 1 dozen, twin pack, 3 for 20, or 1 case so the cashier can tap faster later.',
          style: TextStyle(
            fontSize: (valueFs - 1).clamp(12, 15),
            fontWeight: FontWeight.w600,
            color: _subtitleColor,
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          SizedBox(height: gap12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion.label),
                onPressed: () {
                  vm.sellingOptionLabelController.text = suggestion.label;
                  if (suggestion.quantity > 0) {
                    vm.sellingOptionQuantityController.text =
                        suggestion.quantity.toString();
                  } else {
                    vm.sellingOptionQuantityController.clear();
                  }
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
        SizedBox(height: gap12),
        _inputTextField(
          label: isLiquid ? 'Sale label' : 'Quick button label',
          controller: vm.sellingOptionLabelController,
          showError: false,
          icon: Icons.local_offer_outlined,
          onChanged: (_) => setState(() {}),
          scale: scale,
          height: (58 * scale).clamp(54, 66),
          radius: radius,
          valueFs: valueFs,
        ),
        SizedBox(height: gap12),
        Row(
          children: [
            Expanded(
              child: _inputNumberField(
                label: isKiloLabel
                    ? 'Pieces per kilo (estimate)'
                    : isWeight
                        ? 'Grams to deduct per sale'
                        : 'How many ${_quantityUnitLabel(vm)} to deduct?',
                controller: vm.sellingOptionQuantityController,
                showError: false,
                icon: Icons.inventory_2_outlined,
                scale: scale,
                height: (58 * scale).clamp(54, 66),
                radius: radius,
                valueFs: valueFs,
              ),
            ),
            SizedBox(width: gap12),
            Expanded(
              child: _inputNumberField(
                label: isLiquid ? 'Usual price' : 'Bundle price',
                controller: vm.sellingOptionPriceController,
                showError: false,
                isPeso: true,
                scale: scale,
                height: (58 * scale).clamp(54, 66),
                radius: radius,
                valueFs: valueFs,
              ),
            ),
          ],
        ),
        SizedBox(height: gap12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: vm.addSellingOption,
            icon: const Icon(Icons.add_rounded),
            label: Text(isLiquid ? 'Add sale sample' : 'Add quick button'),
          ),
        ),
        if (vm.sellingOptions.isNotEmpty) ...[
          SizedBox(height: gap12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vm.sellingOptions.map((option) {
              return _sellingOptionChip(option, vm);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _sellingOptionChip(
    ProductSellingOption option,
    StockInViewModel vm,
  ) {
    final qty = option.baseQuantity ?? 0;
    final priceText = option.price % 1 == 0
        ? option.price.toStringAsFixed(0)
        : option.price.toStringAsFixed(2);

    return Chip(
      label: Text(() {
        final labelLower = option.label.trim().toLowerCase();
        final unitLower = vm.baseUnitLabel.trim().toLowerCase();
        final labelShowsQty = labelLower.endsWith(unitLower) ||
            labelLower.endsWith('pcs') ||
            labelLower.endsWith('pieces');
        return labelShowsQty
            ? '${option.label}  \u2013  \u20B1$priceText'
            : '${option.label}  \u2013  $qty ${vm.baseUnitLabel}  \u2013  \u20B1$priceText';
      }()),
      onDeleted: () => vm.removeSellingOption(option),
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      backgroundColor: Colors.white,
      side: BorderSide(color: _cardBorder.withOpacity(0.9)),
    );
  }

  Widget _inputNumberField({
    required String label,
    required TextEditingController controller,
    required bool showError,
    IconData? icon,
    bool isPeso = false,
    bool allowDecimal = false,
    ValueChanged<String>? onChanged,

    required double scale,
    required double height,
    required double radius,
    required double valueFs,
  }) {
    final acceptsDecimal = isPeso || allowDecimal;
    final s = scale.clamp(0.90, 1.20);

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: acceptsDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          if (acceptsDecimal) ...[
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            DecimalThousandsSeparatorInputFormatter(),
          ] else ...[
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorInputFormatter(),
          ],
        ],
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: valueFs,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: isPeso
              ? Padding(
                  padding: EdgeInsets.all((16 * s).clamp(14, 18)),
                  child: Text(
                    '\u20B1',
                    style: TextStyle(
                      color: _accentBlue,
                      fontSize: (18 * s).clamp(16, 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : icon != null
                  ? Icon(icon, color: _accentBlue, size: (22 * s).clamp(20, 26))
                  : null,
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: showError && controller.text.isEmpty
                  ? Colors.red
                  : _cardBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: showError && controller.text.isEmpty
                  ? Colors.red
                  : _accentBlue,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PICKER (responsive only)
  // ============================================================
  Widget _imagePicker(
    StockInViewModel vm,
    BuildContext context, {
    required double scale,
    required double radius,
    required double imageHeight,
    required double gap10,
    required double valueFs,
  }) {
    Future<void> pickImage() async {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((20 * scale).clamp(18, 24))),
          child: Padding(
            padding: EdgeInsets.all((20 * scale).clamp(16, 24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.photo_library,
                      size: (28 * scale).clamp(24, 32), color: _accentBlue),
                  label: Text(
                    "Gallery",
                    style: TextStyle(
                      fontSize: (16 * scale).clamp(14, 18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    vm.pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: (8 * scale).clamp(6, 10)),
                TextButton.icon(
                  icon: Icon(Icons.camera_alt,
                      size: (28 * scale).clamp(24, 32), color: _accentBlue),
                  label: Text(
                    "Camera",
                    style: TextStyle(
                      fontSize: (16 * scale).clamp(14, 18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(radius),
              color: _fieldBg,
            ),
            child: vm.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Image.file(vm.productImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: (54 * scale).clamp(46, 62),
                        width: (54 * scale).clamp(46, 62),
                        decoration: BoxDecoration(
                          color: _accentBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular((18 * scale).clamp(16, 22)),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: _accentBlue,
                          size: (28 * scale).clamp(24, 34),
                        ),
                      ),
                      SizedBox(height: gap10),
                      Text(
                        "Tap para mag add og product image",
                        style: TextStyle(
                          color: _subtitleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: valueFs,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: gap10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.camera_alt_rounded, size: (20 * scale).clamp(18, 24)),
                label: Text(
                  "Add / Retake",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: (13.5 * scale).clamp(12.5, 15)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentBlue,
                  side: BorderSide(color: _accentBlue.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular((12 * scale).clamp(10, 16)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: (12 * scale).clamp(10, 14)),
                ),
              ),
            ),
            SizedBox(width: (10 * scale).clamp(8, 12)),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.productImage == null ? null : vm.removeImage,
                icon: Icon(Icons.delete_outline_rounded, size: (20 * scale).clamp(18, 24)),
                label: Text(
                  "Remove",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: (13.5 * scale).clamp(12.5, 15)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular((12 * scale).clamp(10, 16)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: (12 * scale).clamp(10, 14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// FORMATTERS (UNCHANGED)
// ============================================================
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) return oldValue;
    if (raw.isEmpty) return const TextEditingValue();

    // Count non-comma chars before cursor to restore cursor position
    final cursorPos = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPos; i++) {
      if (newValue.text[i] != ',') digitsBeforeCursor++;
    }

    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final result = '${_formatIntegerWithComma(intPart)}$decPart';

    // Find new cursor offset by counting digits in formatted result
    int newOffset = result.length;
    int digitsSeen = 0;
    for (int i = 0; i < result.length; i++) {
      if (result[i] != ',') digitsSeen++;
      if (digitsSeen == digitsBeforeCursor) {
        newOffset = i + 1;
        break;
      }
    }
    if (digitsBeforeCursor == 0) newOffset = 0;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class DecimalThousandsSeparatorInputFormatter extends TextInputFormatter {
  final RegExp _amountPattern = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return const TextEditingValue();
    if (!_amountPattern.hasMatch(raw)) return oldValue;

    // Count non-comma chars before cursor to restore cursor position
    final cursorPos = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPos; i++) {
      if (newValue.text[i] != ',') digitsBeforeCursor++;
    }

    final hasDot = raw.contains('.');
    final parts = raw.split('.');
    final intPartRaw = parts.first;
    final fracPart = hasDot ? (parts.length > 1 ? parts[1] : '') : '';

    final formattedInt = _formatIntegerWithComma(intPartRaw);
    final formatted = hasDot ? '$formattedInt.$fracPart' : formattedInt;

    // Find new cursor offset by counting digits in formatted result
    int newOffset = formatted.length;
    int digitsSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != ',') digitsSeen++;
      if (digitsSeen == digitsBeforeCursor) {
        newOffset = i + 1;
        break;
      }
    }
    if (digitsBeforeCursor == 0) newOffset = 0;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

String _formatIntegerWithComma(String digits) {
  if (digits.isEmpty) return '';
  final chars = digits.split('').reversed.toList();
  final chunks = <String>[];
  for (var i = 0; i < chars.length; i += 3) {
    chunks.add(chars.skip(i).take(3).join());
  }
  return chunks
      .map((e) => e.split('').reversed.join())
      .toList()
      .reversed
      .join(',');
}

