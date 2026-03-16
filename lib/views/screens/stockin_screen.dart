// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../models/product_unit_conversion.dart';
import '../../view_models/stock_in_view_model.dart';
import '../widgets/dashboard_background.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _fieldBg = Color(0xFFF9FBFF);
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _titleColor = Color(0xFF213A6B);
  static const Color _subtitleColor = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(stockInViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    if (!vm.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Ã¢Å“â€¦ same scaling pattern as your other pages
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

        final double titleFs = (16 * scale).clamp(14.5, 18);
        final double valueFs = (14 * scale).clamp(13, 16);
        final double optionFs = (15 * scale).clamp(13.5, 16.5);
        final double bottomBtnFs = (16 * scale).clamp(14.5, 18);

        final double gap12 = (12 * scale).clamp(10, 14);
        final double gap14 = (14 * scale).clamp(12, 18);
        final double gap10 = (10 * scale).clamp(8, 12);

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: _pageBg,
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
          ),

          body: Stack(
            children: [
              const DashboardBackground(),
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
                    // ===================== CARD: BASIC INFO =====================
                    _card(
                      padding: cardPad,
                      radius: radius16,
                      child: Column(
                        children: [
                          _inputDate(
                            vm,
                            height: fieldH,
                            radius: radius12,
                            valueFs: valueFs,
                          ),
                          SizedBox(height: gap12),

                          // Ã¢Å“â€¦ Category Picker (Bottom Sheet)
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
                        ],
                      ),
                    ),

                    SizedBox(height: gap14),

                    // ===================== CARD: PRICING & QUANTITY =====================
                    _card(
                      padding: cardPad,
                      radius: radius16,
                      child: Column(
                        children: [
                          _advancedModeToggle(
                            vm,
                            scale: scale,
                            radius: radius12,
                            valueFs: valueFs,
                          ),
                          SizedBox(height: gap12),
                          _inputNumberField(
                            label: vm.useAdvancedUnitSetup
                                ? 'Total stock cost'
                                : 'Purchase price',
                            controller: vm.purchasePriceController,
                            showError: vm.showValidationErrors,
                            isPeso: true,
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            valueFs: valueFs,
                          ),
                          SizedBox(height: gap12),
                          _inputNumberField(
                            label: vm.useAdvancedUnitSetup
                                ? 'Selling price per base unit'
                                : 'Selling price',
                            controller: vm.sellingPriceController,
                            showError: vm.showValidationErrors,
                            isPeso: true,
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            valueFs: valueFs,
                          ),
                          SizedBox(height: gap12),
                          _inputNumberField(
                            label: vm.useAdvancedUnitSetup
                                ? 'Stock quantity in base unit'
                                : 'Quantity',
                            controller: vm.quantityController,
                            showError: vm.showValidationErrors,
                            icon: Icons.shopping_cart_rounded,
                            isPeso: false,
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            valueFs: valueFs,
                          ),
                          if (vm.useAdvancedUnitSetup) ...[
                            SizedBox(height: gap12),
                            _baseUnitPickerField(
                              vm,
                              scale: scale,
                              radius: radius12,
                              valueFs: valueFs,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (vm.useAdvancedUnitSetup) ...[
                      SizedBox(height: gap14),
                      _sectionCard(
                        scale: scale,
                        padding: cardPad,
                        radius: radius16,
                        titleFs: titleFs,
                        title: 'Unit Conversion Setup',
                        icon: Icons.tune_rounded,
                        child: _unitConversionSection(
                          vm,
                          scale: scale,
                          radius: radius12,
                          valueFs: valueFs,
                          gap12: gap12,
                        ),
                      ),
                      SizedBox(height: gap14),
                    ] else
                      SizedBox(height: gap14),

                    // ===================== CARD: IMAGE =====================
                    _sectionCard(
                      scale: scale,
                      padding: cardPad,
                      radius: radius16,
                      titleFs: titleFs,
                      title: "Product Image (Opsyonal)",
                      icon: Icons.camera_alt_rounded,
                      child: _imagePicker(
                        vm,
                        context,
                        scale: scale,
                        radius: radius14,
                        imageHeight: imgH,
                        gap10: gap10,
                        valueFs: valueFs,
                      ),
                    ),

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
  // Ã¢Å“â€¦ CATEGORY PICKER FIELD (BOTTOM SHEET) - responsive only
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
  // Ã¢Å“â€¦ CATEGORY BOTTOM SHEET (responsive only)
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
  // Ã¢Å“â€¦ ADD CATEGORY DIALOG (responsive only)
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
                          "Pagdugang ug Bag-ong Kategorya",
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
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: (10 * s).clamp(8, 12)),
                  Text(
                    "Example: Snacks, Inomnon, Pagkaon",
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
                        textInputAction: TextInputAction.done,
                        maxLength: 30,
                        decoration: InputDecoration(
                          counterText: "",
                          prefixIcon: const Icon(Icons.category_rounded),
                          labelText: "Ngalan sa Kategorya",
                          hintText: "e.g. Frozen Foods",
                          filled: true,
                          fillColor: _fieldBg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                            borderSide: BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                            borderSide: const BorderSide(color: _accentBlue),
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
                  SizedBox(height: (6 * s).clamp(4, 10)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _titleColor,
                            side: BorderSide(color: _cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                            ),
                            padding: EdgeInsets.symmetric(vertical: (12 * s).clamp(10, 14)),
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
                                  borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                                ),
                                padding: EdgeInsets.symmetric(vertical: (12 * s).clamp(10, 14)),
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

  // ============================================================
  // UI CARDS (responsive params)
  // ============================================================
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,

    required double scale,
    required double padding,
    required double radius,
    required double titleFs,
  }) {
    final s = scale.clamp(0.90, 1.20);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: (36 * s).clamp(34, 44),
                width: (36 * s).clamp(34, 44),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                ),
                child: Icon(icon, color: _accentBlue, size: (20 * s).clamp(18, 24)),
              ),
              SizedBox(width: (10 * s).clamp(8, 12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: titleFs,
                    color: _titleColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (12 * s).clamp(10, 14)),
          child,
        ],
      ),
    );
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
        );

        if (selected == null) return;
        if (selected == '__add_new__') {
          await _showAddBaseUnitDialog(context, vm, scale: scale);
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
          labelText: 'Base unit',
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
                    ? 'Select base unit'
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

  Future<String?> _showBaseUnitBottomSheet({
    required BuildContext context,
    required List<String> units,
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
                          'Pili ug Base Unit',
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
                              Icon(
                                Icons.add,
                                size: (18 * s).clamp(16, 22),
                                color: _accentBlue,
                              ),
                              SizedBox(width: (6 * s).clamp(5, 8)),
                              Text(
                                'Add Unit',
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
                          labelText: 'Base unit name',
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
                vm.selectedProduct = null;
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
    required double scale,
    required double height,
    required double radius,
    required double valueFs,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
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

  Widget _advancedModeToggle(
    StockInViewModel vm, {
    required double scale,
    required double radius,
    required double valueFs,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (12 * scale).clamp(10, 16),
        vertical: (10 * scale).clamp(8, 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced unit setup',
                  style: TextStyle(
                    fontSize: valueFs,
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Turn on only for mL, grams, lapad, or custom unit conversion.',
                  style: TextStyle(
                    fontSize: (valueFs - 1).clamp(12, 15),
                    fontWeight: FontWeight.w600,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: vm.useAdvancedUnitSetup,
            onChanged: vm.setUseAdvancedUnitSetup,
            activeColor: _accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _unitConversionSection(
    StockInViewModel vm, {
    required double scale,
    required double radius,
    required double valueFs,
    required double gap12,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _inputTextField(
                label: 'Unit name',
                controller: vm.conversionNameController,
                showError: false,
                icon: Icons.label_outline_rounded,
                scale: scale,
                height: (58 * scale).clamp(54, 66),
                radius: radius,
                valueFs: valueFs,
              ),
            ),
            SizedBox(width: gap12),
            Expanded(
              child: _inputNumberField(
                label: 'Base qty',
                controller: vm.conversionQuantityController,
                showError: false,
                icon: Icons.water_drop_outlined,
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
            label: Text('Add unit for ${vm.baseUnitLabel}'),
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
    return Chip(
      label: Text(
        '${conversion.unitName} = ${conversion.baseQuantity} ${vm.baseUnitLabel}',
      ),
      onDeleted: () => vm.removeUnitConversion(conversion),
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

    required double scale,
    required double height,
    required double radius,
    required double valueFs,
  }) {
    final allowDecimal = isPeso;
    final s = scale.clamp(0.90, 1.20);

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        keyboardType: allowDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          if (allowDecimal) ...[
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
    String text = newValue.text.replaceAll(',', '');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;
    if (text.isEmpty) return const TextEditingValue();

    final parts = text.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    String formattedInt = '';
    if (intPart.isNotEmpty) {
      final chars = intPart.split('').reversed.toList();
      final chunks = <String>[];
      for (var i = 0; i < chars.length; i += 3) {
        chunks.add(chars.skip(i).take(3).join());
      }
      formattedInt = chunks
          .map((e) => e.split('').reversed.join())
          .toList()
          .reversed
          .join(',');
    }

    final result = '$formattedInt$decPart';
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
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

    final hasDot = raw.contains('.');
    final parts = raw.split('.');
    final intPartRaw = parts.first;
    final fracPart = hasDot ? (parts.length > 1 ? parts[1] : '') : '';

    final formattedInt = _formatIntegerWithComma(intPartRaw);
    final formatted = hasDot ? '$formattedInt.$fracPart' : formattedInt;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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

