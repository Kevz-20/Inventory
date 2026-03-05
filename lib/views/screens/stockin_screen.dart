// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../view_models/stock_in_view_model.dart';
import '../widgets/header.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
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

        // ✅ same scaling pattern as your other pages
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
          backgroundColor: AppColors.surface,
          appBar: const AppHeader(title: 'Stock In', showBackButton: true),

          body: ScrollbarTheme(
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

                          // ✅ Category Picker (Bottom Sheet)
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
                          _inputNumberField(
                            label: 'Presyo sa pagpalit',
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
                            label: 'Presyo sa pagbaligya',
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
                            label: 'Gidaghanon',
                            controller: vm.quantityController,
                            showError: vm.showValidationErrors,
                            icon: Icons.shopping_cart_rounded,
                            isPeso: false,
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            valueFs: valueFs,
                          ),
                        ],
                      ),
                    ),

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
                    backgroundColor: AppColors.primary,
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
  // ✅ CATEGORY PICKER FIELD (BOTTOM SHEET) - responsive only
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
          fillColor: Colors.grey.shade50,
          prefixIcon: Icon(
            Icons.category,
            color: AppColors.primary,
            size: (22 * scale).clamp(20, 26),
          ),
          labelText: 'Kategorya',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: isError ? Colors.red : AppColors.primary,
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
                      ? Colors.grey.shade600
                      : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black54,
              size: (22 * scale).clamp(20, 26),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ CATEGORY BOTTOM SHEET (responsive only)
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
              color: Colors.white,
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
                      color: Colors.grey.shade300,
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
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: AppColors.primary,
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
                            color: Colors.black87,
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
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add,
                                  size: (18 * s).clamp(16, 22),
                                  color: AppColors.primary),
                              SizedBox(width: (6 * s).clamp(5, 8)),
                              Text(
                                'Add Kategorya',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
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
                        fillColor: Colors.grey.shade50,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: (12 * s).clamp(10, 14),
                          vertical: (14 * s).clamp(12, 16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary),
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
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.search_off_rounded,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: (10 * s).clamp(8, 12)),
                                  Text(
                                    'Walay match nga category.',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w800,
                                      fontSize: (13.5 * s).clamp(12.5, 15),
                                    ),
                                  ),
                                  SizedBox(height: (4 * s).clamp(3, 6)),
                                  Text(
                                    'Try lain nga keyword or add new category.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
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
                                      ? AppColors.primary.withOpacity(0.10)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.35)
                                        : Colors.grey.shade200,
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
                                              ? AppColors.primary
                                              : Colors.black87,
                                          fontSize: (14 * s).clamp(13, 16),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
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
  // ✅ ADD CATEGORY DIALOG (responsive only)
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
          backgroundColor: Colors.white,
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
                          "Add New Category",
                          style: TextStyle(
                            fontSize: (16 * s).clamp(14, 18),
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
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
                      color: Colors.grey.shade700,
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
                          labelText: "Category name",
                          hintText: "e.g. Frozen Foods",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                            borderSide: const BorderSide(color: AppColors.primary),
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
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
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
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.30),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade200),
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
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                ),
                child: Icon(icon, color: AppColors.primary, size: (20 * s).clamp(18, 24)),
              ),
              SizedBox(width: (10 * s).clamp(8, 12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: titleFs,
                    color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade200),
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
                  primary: AppColors.primary,
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
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: valueFs,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
          labelText: 'Petsa',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: AppColors.primary),
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
            color: Colors.white,
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
                    Divider(height: 1, color: Colors.grey.shade200),
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
                          color: Colors.black,
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
              prefixIcon: const Icon(Icons.edit, color: AppColors.primary),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(
                  color: (vm.showValidationErrors &&
                          vm.effectiveProductName.trim().isEmpty)
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(
                  color: (vm.showValidationErrors &&
                          vm.effectiveProductName.trim().isEmpty)
                      ? Colors.red
                      : AppColors.primary,
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
        vm.selectedProduct = product;

        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 50));

        vm.productController.text = product.name;
        vm.autocompleteFieldController?.text = product.name;

        vm.setCategoryByName(product.category);

        vm.purchasePriceController.text = product.purchasePrice.toString();
        vm.sellingPriceController.text = product.sellingPrice.toString();
        vm.quantityController.text = product.quantity.toString();
        vm.productImage = product.image != null ? File(product.image!) : null;
      },
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
          fillColor: Colors.grey.shade50,
          prefixIcon: isPeso
              ? Padding(
                  padding: EdgeInsets.all((16 * s).clamp(14, 18)),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: (18 * s).clamp(16, 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : icon != null
                  ? Icon(icon, color: AppColors.primary, size: (22 * s).clamp(20, 26))
                  : null,
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: showError && controller.text.isEmpty
                  ? Colors.red
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: showError && controller.text.isEmpty
                  ? Colors.red
                  : AppColors.primary,
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((20 * scale).clamp(18, 24))),
          child: Padding(
            padding: EdgeInsets.all((20 * scale).clamp(16, 24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.photo_library,
                      size: (28 * scale).clamp(24, 32), color: AppColors.primary),
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
                      size: (28 * scale).clamp(24, 32), color: AppColors.primary),
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
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(radius),
              color: Colors.grey.shade50,
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
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular((18 * scale).clamp(16, 22)),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.primary,
                          size: (28 * scale).clamp(24, 34),
                        ),
                      ),
                      SizedBox(height: gap10),
                      Text(
                        "Tap para mag add og product image",
                        style: TextStyle(
                          color: Colors.grey.shade700,
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
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
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