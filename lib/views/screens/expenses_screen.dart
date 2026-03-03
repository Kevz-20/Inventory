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
import '../widgets/header.dart';
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Gasto',
        showBackButton: true,
        action: Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () => GoRouter.of(context).push('/list_expenses'),
          ),
        ),
      ),
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cleanCard(
                  child: Column(
                    children: [
                      _readOnlyField(
                        controller: _dateTextController,
                        icon: Icons.calendar_month_rounded,
                        label: 'Petsa',
                        onTap: () => _pickDate(context, vm),
                      ),
                      const SizedBox(height: 12),

                      // ✅ NEW: Bottom sheet picker like StockIn (with Add Category)
                      _categoryPickerField(vm),

                      const SizedBox(height: 12),
                      _inputTextField(
                        prefix: const SizedBox(
                          width: 48,
                          child: Center(
                            child: Text(
                              '₱',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        label: 'Gasto',
                        controller: vm.amountController,
                        showError: vm.showValidationErrors,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsFormatter()],
                        hintText: "0.00",
                      ),
                      const SizedBox(height: 12),
                      _inputTextField(
                        prefix: const Icon(
                          Icons.description_rounded,
                          color: AppColors.primary,
                        ),
                        label: 'Deskripsyon',
                        controller: vm.descriptionController,
                        showError: vm.showValidationErrors,
                        hintText: "Unsa ni nga gasto?",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: "Resibo (Opsyonal)",
                  icon: Icons.camera_alt_rounded,
                  child: _receiptSection(context, vm),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(14),
          shadowColor: Colors.black.withOpacity(0.15),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  : const Text(
                      'Rekord',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ CATEGORY PICKER FIELD (BOTTOM SHEET) - same as StockIn
  // ============================================================
  Widget _categoryPickerField(ExpensesViewModel vm) {
    final isError = vm.showValidationErrors && (vm.selectedCategory == null);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: vm.isCategoriesLoading
          ? null
          : () async {
              final selected = await _showCategoryBottomSheet(
                context: context,
                categories: vm.categoryNames,
                selected: vm.selectedCategory,
              );

              if (selected == null) return;

              if (selected == '__add_new__') {
                await _showAddCategoryDialog(context, vm);
                return;
              }

              vm.setCategoryByName(selected);
            },
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: const Icon(Icons.category, color: AppColors.primary),
          labelText: 'Kategorya',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : AppColors.primary,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                vm.isCategoriesLoading
                    ? 'Loading...'
                    : (vm.selectedCategory ?? 'Pili ug category'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: (vm.selectedCategory == null)
                      ? Colors.grey.shade600
                      : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCategoryBottomSheet({
  required BuildContext context,
  required List<String> categories,
  required String? selected,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (sheetCtx) {
      final search = ValueNotifier('');
      final maxHeight = MediaQuery.of(sheetCtx).size.height * 0.78;

      return SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
              left: 16,
              right: 16,
              top: 10,
              bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  height: 5,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pili ug Kategorya',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // Add button (same style as StockIn)
                    InkWell(
                      onTap: () =>
                          Navigator.pop(sheetCtx, '__add_new__'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary
                                .withOpacity(0.25),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add,
                                size: 18,
                                color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Add Kategorya',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search field
                ValueListenableBuilder<String>(
                  valueListenable: search,
                  builder: (_, value, _) => TextField(
                    onChanged: (v) => search.value = v,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search category...',
                      prefixIcon:
                          const Icon(Icons.search_rounded),
                      suffixIcon: value.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () =>
                                  search.value = '',
                              icon: const Icon(
                                  Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category list
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: search,
                    builder: (_, value, _) {
                      final q =
                          value.trim().toLowerCase();
                      final filtered = q.isEmpty
                          ? categories
                          : categories
                              .where((e) => e
                                  .toLowerCase()
                                  .contains(q))
                              .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .grey.shade100,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                18),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .search_off_rounded,
                                    color:
                                        Colors.black54,
                                  ),
                                ),
                                const SizedBox(
                                    height: 10),
                                Text(
                                  'Walay match nga category.',
                                  style: TextStyle(
                                    color: Colors
                                        .grey.shade700,
                                    fontWeight:
                                        FontWeight.w800,
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
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item =
                              filtered[i];
                          final isSelected =
                              item == selected;

                          return InkWell(
                            borderRadius:
                                BorderRadius
                                    .circular(14),
                            onTap: () =>
                                Navigator.pop(
                                    sheetCtx, item),
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: isSelected
                                    ? AppColors
                                        .primary
                                        .withOpacity(
                                            0.10)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors
                                          .primary
                                          .withOpacity(
                                              0.35)
                                      : Colors.grey
                                          .shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                        color: isSelected
                                            ? AppColors
                                                .primary
                                            : Colors
                                                .black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons
                                          .check_circle_rounded,
                                      color: AppColors
                                          .primary,
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
    ExpensesViewModel vm,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final value = ValueNotifier<String>('');

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Add New Category",
                          style: TextStyle(
                            fontSize: 16,
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
                  const SizedBox(height: 10),
                  Text(
                    "Example: Kumpra, Bayronon, Transportasyon",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          hintText: "e.g. Uban pa",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: value,
                          builder: (_, text, _) {
                            final canAdd = text.trim().isNotEmpty;
                            return ElevatedButton(
                              onPressed: canAdd
                                  ? () {
                                      if (formKey.currentState?.validate() !=
                                          true) {
                                        return;
                                      }
                                      Navigator.pop(dialogCtx, controller.text);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Add",
                                style: TextStyle(fontWeight: FontWeight.w900),
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
  // UI PARTS
  // ============================================================
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _cleanCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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

  Widget _readOnlyField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          suffixIcon: const Icon(Icons.chevron_right_rounded),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _receiptSection(BuildContext context, ExpensesViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pickReceiptImage(context, vm),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade50,
            ),
            child: vm.receiptImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(vm.receiptImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Tap para mag add og resibo",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickReceiptImage(context, vm),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text("Add / Retake"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: vm.receiptImage == null ? null : vm.removeReceipt,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text("Remove"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
  }) {
    final isError = showError && controller.text.isEmpty;

    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: prefix,
          labelText: label,
          hintText: hintText,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : AppColors.primary,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.photo_library,
                    size: 28, color: AppColors.primary),
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
                    size: 28, color: AppColors.primary),
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