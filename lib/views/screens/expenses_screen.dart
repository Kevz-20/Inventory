// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../view_models/expenses_view_model.dart';
import '../widgets/dashboard_background.dart';
import '../../models/current_user.dart';

class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String text = newValue.text.replaceAll(',', '');

    if (!RegExp(r'^[0-9.]*$').hasMatch(text)) return oldValue;
    if ('.'.allMatches(text).length > 1) return oldValue;

    final parts = text.split('.');
    final integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);

    String formattedInteger = '';
    if (integerPart.isNotEmpty) {
      formattedInteger = _formatter.format(int.parse(integerPart));
    }

    String result = formattedInteger;

    if (text.endsWith('.')) {
      result = "$formattedInteger.";
    } else if (decimalPart.isNotEmpty) {
      result = "$formattedInteger.$decimalPart";
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBgAlt = Color(0xFFF9FBFF);
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _titleColor = Color(0xFF213A6B);
  static const Color _subtitleColor = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  late final ScrollController _scrollController;
  late final TextEditingController _dateTextController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _dateTextController = TextEditingController();

    // ✅ StockIn-like: load categories on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expensesViewModelProvider).loadExpenseCategories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(expensesViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    _dateTextController.text = vm.formattedDate;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Phone -> tablet scaling, clamped (same style as your other pages)
        final double scale = (w / 390).clamp(0.90, 1.20);

        final double padH = (16 * scale).clamp(14, 22);
        final double padTop = (14 * scale).clamp(10, 18);
        final double padBottom = (16 * scale).clamp(12, 20);

        final double cardPad = (14 * scale).clamp(12, 18);
        final double radius16 = (16 * scale).clamp(14, 20);
        final double radius14 = (14 * scale).clamp(12, 18);
        final double radius12 = (12 * scale).clamp(10, 16);

        final double fieldH = (60 * scale).clamp(54, 66);
        final double receiptH = (220 * scale).clamp(170, 260);

        final double titleFs = (16 * scale).clamp(14.5, 18);
        final double labelFs = (14 * scale).clamp(13, 16);
        final double valueFs = (14 * scale).clamp(13, 16);
        final double buttonFs = (16 * scale).clamp(14.5, 18);

        final double gap12 = (12 * scale).clamp(10, 14);
        final double gap14 = (14 * scale).clamp(12, 18);

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
              'Gasto',
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
                    _cleanCard(
                      scale: scale,
                      padding: cardPad,
                      radius: radius16,
                      child: Column(
                        children: [
                          _readOnlyField(
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            controller: _dateTextController,
                            icon: Icons.calendar_month_rounded,
                            label: 'Petsa',
                            onTap: () => _pickDate(context, vm),
                            labelFs: labelFs,
                            valueFs: valueFs,
                          ),
                          SizedBox(height: gap12),

                          // ✅ NEW: Bottom sheet picker like StockIn (with Add Category)
                          _categoryPickerField(vm, scale: scale, radius: radius12, labelFs: labelFs),

                          SizedBox(height: gap12),
                          _inputTextField(
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            prefix: SizedBox(
                              width: (48 * scale).clamp(42, 56),
                              child: Center(
                                child: Text(
                                  '\u20B1',
                                  style: TextStyle(
                                    fontSize: (20 * scale).clamp(18, 24),
                                    color: _accentBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            label: 'Gasto',
                            controller: vm.amountController,
                            showError: vm.showValidationErrors,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [ThousandsFormatter()],
                            hintText: "0.00",
                            labelFs: labelFs,
                            valueFs: valueFs,
                          ),
                          SizedBox(height: gap12),
                          _inputTextField(
                            scale: scale,
                            height: fieldH,
                            radius: radius12,
                            prefix: Icon(
                              Icons.description_rounded,
                              color: _accentBlue,
                              size: (22 * scale).clamp(20, 26),
                            ),
                            label: 'Deskripsyon',
                            controller: vm.descriptionController,
                            showError: vm.showValidationErrors,
                            hintText: "Unsa ni nga gasto?",
                            labelFs: labelFs,
                            valueFs: valueFs,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap14),
                    _sectionCard(
                      scale: scale,
                      padding: cardPad,
                      radius: radius16,
                      titleFs: titleFs,
                      title: "Resibo (Opsyonal)",
                      icon: Icons.camera_alt_rounded,
                      child: _receiptSection(context, vm, scale: scale, radius: radius14, receiptHeight: receiptH),
                    ),
                        SizedBox(height: (90 * scale).clamp(70, 110)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                height: (52 * scale).clamp(48, 58),
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
                      : () async {
                          vm.triggerValidation();

                          await vm.save(
                            context: context,
                            createdByFirstName: CurrentUser.firstName ?? '',
                            createdByMiddleName: CurrentUser.middleName ?? '',
                            createdByLastName: CurrentUser.lastName ?? '',
                          );
                        },
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Rekord',
                          style: TextStyle(
                            fontSize: buttonFs,
                            fontWeight: FontWeight.w800,
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
  // ✅ CATEGORY PICKER FIELD (BOTTOM SHEET) - same as StockIn
  // ============================================================
  Widget _categoryPickerField(
    ExpensesViewModel vm, {
    required double scale,
    required double radius,
    required double labelFs,
  }) {
    final isError = vm.showValidationErrors && (vm.selectedCategory == null);

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: vm.isCategoriesLoading
          ? null
          : () async {
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
          fillColor: _cardBgAlt,
          prefixIcon: Icon(Icons.category, color: _accentBlue, size: (22 * scale).clamp(20, 26)),
          labelText: 'Kategorya',
          labelStyle: TextStyle(fontSize: labelFs),
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
                vm.isCategoriesLoading
                    ? 'Loading...'
                    : (vm.selectedCategory ?? 'Pili ug Kategorya'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: (14 * scale).clamp(13, 16),
                  color: (vm.selectedCategory == null)
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

        final double s = scale.clamp(0.90, 1.20);

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
                bottom: (16 * s).clamp(14, 20) + MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                          borderRadius: BorderRadius.circular(12),
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
                              Icon(Icons.add, size: (18 * s).clamp(16, 22), color: _accentBlue),
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
                        fillColor: _cardBgAlt,
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
                            : categories.where((e) => e.toLowerCase().contains(q)).toList();

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
                                      color: _cardBgAlt,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(Icons.search_off_rounded, color: _subtitleColor),
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
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => SizedBox(height: (8 * s).clamp(6, 10)),
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
                                      : _cardBgAlt,
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
                                          color: isSelected ? _accentBlue : _titleColor,
                                          fontSize: (14 * s).clamp(13, 16),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: _accentBlue),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    ExpensesViewModel vm, {
    required double scale,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final value = ValueNotifier<String>('');

    final double s = scale.clamp(0.90, 1.20);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((18 * s).clamp(16, 22))),
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
                    "Example: Kumpra, Bayronon, Transportasyon",
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
                          hintText: "e.g. Uban pa",
                          filled: true,
                          fillColor: _cardBgAlt,
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
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: (13.5 * s).clamp(12.5, 15)),
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
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: (13.5 * s).clamp(12.5, 15)),
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
  // UI PARTS (RESPONSIVE)
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

  Widget _cleanCard({
    required Widget child,
    required double scale,
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

  Widget _readOnlyField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double scale,
    required double height,
    required double radius,
    required double labelFs,
    required double valueFs,
  }) {
    final s = scale.clamp(0.90, 1.20);

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: valueFs,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _cardBgAlt,
          prefixIcon: Icon(icon, color: _accentBlue, size: (22 * s).clamp(20, 26)),
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFs, fontWeight: FontWeight.w700),
          suffixIcon: Icon(Icons.chevron_right_rounded, size: (22 * s).clamp(20, 26)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: _cardBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _accentBlue, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _receiptSection(
    BuildContext context,
    ExpensesViewModel vm, {
    required double scale,
    required double radius,
    required double receiptHeight,
  }) {
    final s = scale.clamp(0.90, 1.20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pickReceiptImage(context, vm),
          child: Container(
            height: receiptHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(radius),
              color: _cardBgAlt,
            ),
            child: vm.receiptImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Image.file(
                      File(vm.receiptImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: (54 * s).clamp(46, 62),
                        width: (54 * s).clamp(46, 62),
                        decoration: BoxDecoration(
                          color: _accentBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular((18 * s).clamp(16, 22)),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: _accentBlue,
                          size: (28 * s).clamp(24, 34),
                        ),
                      ),
                      SizedBox(height: (10 * s).clamp(8, 12)),
                      Text(
                        "Tap para mag add og resibo",
                        style: TextStyle(
                          color: _subtitleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: (13.5 * s).clamp(12.5, 15),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: (10 * s).clamp(8, 12)),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickReceiptImage(context, vm),
                icon: Icon(Icons.camera_alt_rounded, size: (20 * s).clamp(18, 24)),
                label: Text(
                  "Add / Retake",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: (13.5 * s).clamp(12.5, 15)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentBlue,
                  side: BorderSide(color: _accentBlue.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: (12 * s).clamp(10, 14)),
                ),
              ),
            ),
            SizedBox(width: (10 * s).clamp(8, 12)),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.receiptImage == null ? null : vm.removeReceipt,
                icon: Icon(Icons.delete_outline_rounded, size: (20 * s).clamp(18, 24)),
                label: Text(
                  "Remove",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: (13.5 * s).clamp(12.5, 15)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular((12 * s).clamp(10, 16)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: (12 * s).clamp(10, 14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inputTextField({
    required Widget? prefix,
    required String label,
    required TextEditingController controller,
    required bool showError,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,

    // responsive
    required double scale,
    required double height,
    required double radius,
    required double labelFs,
    required double valueFs,
  }) {
    final isError = showError && controller.text.isEmpty;
    final s = scale.clamp(0.90, 1.20);

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          color: _titleColor,
          fontWeight: FontWeight.w800,
          fontSize: valueFs,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _cardBgAlt,
          prefixIcon: prefix,
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFs, fontWeight: FontWeight.w700),
          hintText: hintText,
          hintStyle: TextStyle(fontSize: (13.5 * s).clamp(12.5, 15), color: _subtitleColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: isError ? Colors.red : _cardBorder,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: isError ? Colors.red : _accentBlue,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, ExpensesViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate.isAfter(DateTime.now())
          ? DateTime.now()
          : vm.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) vm.setDate(picked);
  }

  Future<void> _pickReceiptImage(
    BuildContext context,
    ExpensesViewModel vm,
  ) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.photo_library,
                    size: 28, color: _accentBlue),
                label: const Text(
                  "Gallery",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  vm.pickReceipt(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.camera_alt,
                    size: 28, color: _accentBlue),
                label: const Text(
                  "Camera",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  vm.pickReceipt(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
