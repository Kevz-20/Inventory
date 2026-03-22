// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../models/product_selling_option.dart';
import '../models/product_unit_conversion.dart';
import '../repositories/product_category_repository.dart';
import '../repositories/stock_in_repository.dart';
import '../services/db_service.dart';

final stockInViewModelProvider =
    ChangeNotifierProvider.autoDispose<StockInViewModel>((ref) {
  return StockInViewModel();
});

class StockInViewModel extends ChangeNotifier {
  late final StockInRepository _repository;
  late final ProductCategoryRepository _categoryRepo;
  bool isInitialized = false;
  bool showValidationErrors = false;
  bool _isDisposed = false;

  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> categoryRows = [];
  String? selectedCategory;
  int? selectedCategoryId;

  List<String> get categoryNames =>
      categoryRows.map((e) => (e['name'] ?? '').toString()).toList();

  File? productImage;
  List<String> productNames = [];
  List<ProductModel> allProducts = [];
  ProductModel? selectedProduct;
  List<ProductUnitConversion> unitConversions = [];
  List<ProductSellingOption> sellingOptions = [];
  List<String> baseUnitOptions = [];
  bool useAdvancedUnitSetup = false;
  bool editSavedSetup = false;

  TextEditingController? autocompleteFieldController;
  final TextEditingController productController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController baseUnitController =
      TextEditingController(text: 'pcs');
  final TextEditingController purchaseUnitController =
      TextEditingController(text: 'pcs');
  final TextEditingController conversionNameController =
      TextEditingController();
  final TextEditingController conversionQuantityController =
      TextEditingController();
  final TextEditingController sellingOptionLabelController =
      TextEditingController();
  final TextEditingController sellingOptionQuantityController =
      TextEditingController();
  final TextEditingController sellingOptionPriceController =
      TextEditingController();

  bool get hasUnsavedData =>
      productController.text.isNotEmpty ||
      purchasePriceController.text.isNotEmpty ||
      sellingPriceController.text.isNotEmpty ||
      quantityController.text.isNotEmpty ||
      baseUnitController.text.trim().toLowerCase() != 'pcs' ||
      purchaseUnitController.text.trim().toLowerCase() != 'pcs' ||
      unitConversions.isNotEmpty ||
      sellingOptions.isNotEmpty ||
      selectedCategory != null ||
      productImage != null;

  final List<String> months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool isLoading = false;

  StockInViewModel() {
    _init();
  }

  @override
  void dispose() {
    _isDisposed = true;
    productController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
    quantityController.dispose();
    baseUnitController.dispose();
    purchaseUnitController.dispose();
    conversionNameController.dispose();
    conversionQuantityController.dispose();
    sellingOptionLabelController.dispose();
    sellingOptionQuantityController.dispose();
    sellingOptionPriceController.dispose();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _init() async {
    final db = await DBService.instance.database;
    _repository = StockInRepository(db);
    _categoryRepo = ProductCategoryRepository(db);
    await loadCategories();
    await loadProductNames();
    await loadBaseUnits();

    isInitialized = true;
    safeNotifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      categoryRows = await _categoryRepo.getAllCategories();
    } catch (_) {
      categoryRows = [];
    }

    if (selectedCategoryId != null) {
      final row =
          categoryRows.where((c) => c['id'] == selectedCategoryId).toList();
      if (row.isNotEmpty) {
        selectedCategory = row.first['name'] as String?;
      } else {
        selectedCategory = null;
        selectedCategoryId = null;
      }
    }

    safeNotifyListeners();
  }

  void setCategoryByName(String? categoryName) {
    selectedCategory = categoryName;

    if (categoryName == null) {
      selectedCategoryId = null;
    } else {
      final row = categoryRows.where((c) => c['name'] == categoryName).toList();
      selectedCategoryId = row.isNotEmpty ? row.first['id'] as int? : null;
    }

    safeNotifyListeners();
  }

  Future<void> addNewCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final existing =
        categoryRows.where((c) => (c['name'] ?? '').toString() == trimmed);
    if (existing.isNotEmpty) {
      selectedCategory = trimmed;
      selectedCategoryId = existing.first['id'] as int?;
      safeNotifyListeners();
      return;
    }

    final id = await _categoryRepo.getOrCreateCategoryId(trimmed);

    await loadCategories();

    selectedCategory = trimmed;
    selectedCategoryId = id;
    safeNotifyListeners();
  }

  void pickDate(DateTime date) {
    selectedDate = date;
    safeNotifyListeners();
  }

  String get formattedDate =>
      '${months[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';

  String get effectiveProductName {
    final autoText = autocompleteFieldController?.text.trim() ?? '';
    final manualText = productController.text.trim();
    return autoText.isNotEmpty ? autoText : manualText;
  }

  String get baseUnitLabel {
    final raw = baseUnitController.text.trim();
    return raw.isEmpty ? 'pcs' : raw;
  }

  String get purchaseUnitLabel {
    final raw = purchaseUnitController.text.trim();
    return raw.isEmpty ? baseUnitLabel : raw;
  }

  String get stockTypePreset {
    final base = baseUnitLabel.toLowerCase();
    if (!useAdvancedUnitSetup || base == 'pcs') return 'piece';
    if (base == 'gram' || base == 'grams' || base == 'g') return 'weight';
    if (base == 'ml' || base == 'milliliter' || base == 'millilitre') {
      return 'liquid';
    }
    return 'custom';
  }

  List<String> get purchaseUnitOptions {
    final items = <String>[baseUnitLabel];
    for (final conversion in unitConversions) {
      if (conversion.unitName.trim().isEmpty) continue;
      if (!items.any(
        (item) => item.toLowerCase() == conversion.unitName.toLowerCase(),
      )) {
        items.add(conversion.unitName);
      }
    }
    return items;
  }

  int quantityFactorFor(String unit) {
    final normalized = unit.trim().toLowerCase();
    if (normalized.isEmpty || normalized == baseUnitLabel.toLowerCase()) {
      return 1;
    }

    final match = unitConversions.where(
      (item) => item.unitName.trim().toLowerCase() == normalized,
    );

    if (match.isEmpty) return 1;
    return match.first.baseQuantity <= 0 ? 1 : match.first.baseQuantity;
  }

  int get convertedPurchaseQuantity {
    final qtyText = quantityController.text.trim().replaceAll(',', '');
    final enteredQty = double.tryParse(qtyText) ?? 0;
    if (enteredQty <= 0) return 0;

    final factor = quantityFactorFor(purchaseUnitLabel);
    return (enteredQty * factor).round();
  }

  bool get isExistingProductSelected => selectedProduct != null;

  bool get shouldShowSetupEditors => !isExistingProductSelected || editSavedSetup;

  Future<void> loadBaseUnits() async {
    try {
      baseUnitOptions = await _repository.getBaseUnits();
    } catch (_) {
      baseUnitOptions = ['pcs'];
    }

    if (baseUnitOptions.isEmpty) {
      baseUnitOptions = ['pcs'];
    }

    final current = baseUnitController.text.trim();
    if (current.isNotEmpty && !baseUnitOptions.contains(current)) {
      baseUnitOptions = [...baseUnitOptions, current]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    safeNotifyListeners();
  }

  void setBaseUnit(String value) {
    baseUnitController.text = value.trim();
    if (purchaseUnitController.text.trim().isEmpty ||
        purchaseUnitController.text.trim().toLowerCase() ==
            baseUnitLabel.toLowerCase()) {
      purchaseUnitController.text = value.trim();
    }
    safeNotifyListeners();
  }

  void setPurchaseUnit(String value) {
    purchaseUnitController.text = value.trim();
    safeNotifyListeners();
  }

  void applyStockTypePreset(String preset) {
    switch (preset) {
      case 'piece':
        setUseAdvancedUnitSetup(false);
        break;
      case 'weight':
        useAdvancedUnitSetup = true;
        baseUnitController.text = 'gram';
        purchaseUnitController.text = 'kilo';
        _upsertUnitConversion('kilo', 1000);
        safeNotifyListeners();
        break;
      case 'liquid':
        useAdvancedUnitSetup = true;
        baseUnitController.text = 'mL';
        purchaseUnitController.text = 'liter';
        _upsertUnitConversion('liter', 1000);
        safeNotifyListeners();
        break;
    }
  }

  Future<void> addNewBaseUnit(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    await _repository.addBaseUnit(trimmed);
    await loadBaseUnits();
    setBaseUnit(trimmed);
  }

  Future<void> updateBaseUnitChoice(String previousValue, String nextValue) async {
    final previousTrimmed = previousValue.trim();
    final nextTrimmed = nextValue.trim();
    if (previousTrimmed.isEmpty || nextTrimmed.isEmpty) return;

    await _repository.updateBaseUnit(previousTrimmed, nextTrimmed);
    await loadBaseUnits();

    if (baseUnitController.text.trim().toLowerCase() ==
        previousTrimmed.toLowerCase()) {
      setBaseUnit(nextTrimmed);
    }
  }

  Future<void> deleteBaseUnitChoice(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    await _repository.deleteBaseUnit(trimmed);
    await loadBaseUnits();

    if (baseUnitController.text.trim().toLowerCase() == trimmed.toLowerCase()) {
      setBaseUnit('pcs');
    }
  }

  void setUseAdvancedUnitSetup(bool value) {
    useAdvancedUnitSetup = value;
    if (!value) {
      baseUnitController.text = 'pcs';
      purchaseUnitController.text = 'pcs';
      unitConversions = [];
      conversionNameController.clear();
      conversionQuantityController.clear();
    } else if (purchaseUnitController.text.trim().isEmpty) {
      purchaseUnitController.text = baseUnitLabel;
    }
    safeNotifyListeners();
  }

  void setEditSavedSetup(bool value) {
    editSavedSetup = value;
    safeNotifyListeners();
  }

  void clearSelectedProductLink() {
    selectedProduct = null;
    editSavedSetup = false;
    safeNotifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      productImage = File(pickedFile.path);
      safeNotifyListeners();
    }
  }

  void removeImage() {
    productImage = null;
    safeNotifyListeners();
  }

  void addUnitConversion() {
    final name = conversionNameController.text.trim();
    final qtyText = conversionQuantityController.text.trim().replaceAll(',', '');
    final qty = int.tryParse(qtyText) ?? 0;

    if (name.isEmpty || qty <= 0) return;

    _upsertUnitConversion(name, qty);

    conversionNameController.clear();
    conversionQuantityController.clear();
    safeNotifyListeners();
  }

  void removeUnitConversion(ProductUnitConversion conversion) {
    unitConversions = unitConversions
        .where((item) => item.unitName != conversion.unitName)
        .toList();
    if (purchaseUnitController.text.trim().toLowerCase() ==
        conversion.unitName.trim().toLowerCase()) {
      purchaseUnitController.text = baseUnitLabel;
    }
    safeNotifyListeners();
  }

  void updateUnitConversion(
    ProductUnitConversion original, {
    required String unitName,
    required int baseQuantity,
  }) {
    final trimmedName = unitName.trim();
    if (trimmedName.isEmpty || baseQuantity <= 0) return;

    unitConversions = [
      ...unitConversions.where(
        (item) =>
            item.unitName.toLowerCase() != original.unitName.toLowerCase() &&
            item.unitName.toLowerCase() != trimmedName.toLowerCase(),
      ),
      ProductUnitConversion(unitName: trimmedName, baseQuantity: baseQuantity),
    ]..sort((a, b) => b.baseQuantity.compareTo(a.baseQuantity));

    if (purchaseUnitController.text.trim().toLowerCase() ==
        original.unitName.trim().toLowerCase()) {
      purchaseUnitController.text = trimmedName;
    }
    safeNotifyListeners();
  }

  void _upsertUnitConversion(String unitName, int baseQuantity) {
    unitConversions = [
      ...unitConversions.where(
        (item) => item.unitName.toLowerCase() != unitName.toLowerCase(),
      ),
      ProductUnitConversion(unitName: unitName.trim(), baseQuantity: baseQuantity),
    ]..sort((a, b) => b.baseQuantity.compareTo(a.baseQuantity));
  }

  void addSellingOption() {
    final label = sellingOptionLabelController.text.trim();
    final qtyText = sellingOptionQuantityController.text.trim().replaceAll(
      ',',
      '',
    );
    final priceText = sellingOptionPriceController.text.trim().replaceAll(
      ',',
      '',
    );

    final qty = int.tryParse(qtyText) ?? 0;
    final price = double.tryParse(priceText) ?? 0;

    if (label.isEmpty || qty <= 0 || price <= 0) return;

    sellingOptions = [
      ...sellingOptions.where(
        (item) => item.label.toLowerCase() != label.toLowerCase(),
      ),
      ProductSellingOption(
        label: label,
        mode: 'preset',
        unitName: baseUnitLabel,
        baseQuantity: qty,
        price: price,
      ),
    ]..sort((a, b) {
        final qtyCompare = (b.baseQuantity ?? 0).compareTo(a.baseQuantity ?? 0);
        if (qtyCompare != 0) return qtyCompare;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

    sellingOptionLabelController.clear();
    sellingOptionQuantityController.clear();
    sellingOptionPriceController.clear();
    safeNotifyListeners();
  }

  void removeSellingOption(ProductSellingOption option) {
    sellingOptions = sellingOptions
        .where((item) => item.label != option.label)
        .toList();
    safeNotifyListeners();
  }

  void showSnackBar(
    BuildContext context,
    String message, {
    required bool success,
  }) {
    final color = success ? Colors.green : Colors.red;
    final icon = success ? Icons.check_circle_outline : Icons.error_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> saveProduct(BuildContext context) async {
    if (!isInitialized) return;

    final productName = effectiveProductName;
    final purchaseText = purchasePriceController.text.trim();
    final sellingText = sellingPriceController.text.trim();
    final qtyText = quantityController.text.trim();
    final baseUnit = useAdvancedUnitSetup ? baseUnitLabel : 'pcs';
    final purchaseUnit = useAdvancedUnitSetup ? purchaseUnitLabel : 'pcs';
    if (productName.isEmpty ||
        selectedCategory == null ||
        purchaseText.isEmpty ||
        qtyText.isEmpty ||
        baseUnit.isEmpty ||
        purchaseUnit.isEmpty) {
      showSnackBar(context, 'Please fill all required fields', success: false);
      return;
    }

    if (selectedCategoryId == null) {
      final row =
          categoryRows.where((c) => c['name'] == selectedCategory).toList();
      if (row.isNotEmpty) {
        selectedCategoryId = row.first['id'] as int?;
      } else {
        selectedCategoryId =
            await _categoryRepo.getOrCreateCategoryId(selectedCategory!);
        await loadCategories();
      }
    }

    final sellingPriceEntered = double.tryParse(sellingText.replaceAll(',', '')) ?? 0;
    // Convert selling price from per-purchase-unit → per-base-unit for storage
    final purchaseFactor = useAdvancedUnitSetup ? quantityFactorFor(purchaseUnitLabel) : 1;
    final sellingPrice = (sellingPriceEntered > 0 && purchaseFactor > 1)
        ? sellingPriceEntered / purchaseFactor
        : sellingPriceEntered;
    final purchaseInput = double.tryParse(purchaseText.replaceAll(',', '')) ?? 0;
    final enteredQuantity = double.tryParse(qtyText.replaceAll(',', '')) ?? 0;
    final newQuantity = useAdvancedUnitSetup
        ? convertedPurchaseQuantity
        : int.tryParse(qtyText.replaceAll(',', '')) ?? 0;

    if (purchaseInput <= 0) {
      showSnackBar(
        context,
        'Total stock cost must be greater than 0',
        success: false,
      );
      return;
    }
    if (newQuantity <= 0) {
      showSnackBar(
        context,
        'Bought quantity in $purchaseUnit must be greater than 0',
        success: false,
      );
      return;
    }
    if (useAdvancedUnitSetup && enteredQuantity <= 0) {
      showSnackBar(
        context,
        'Bought quantity in $purchaseUnit must be greater than 0',
        success: false,
      );
      return;
    }

    setLoading(true);

    ProductModel? existingProduct;
    for (final p in allProducts) {
      if (p.name.toLowerCase() == productName.toLowerCase()) {
        existingProduct = p;
        break;
      }
    }

    selectedProduct ??= existingProduct;

    final purchaseTotal = purchaseInput;
    final incomingCostPerUnit =
        newQuantity > 0 ? purchaseTotal / newQuantity : purchaseInput;
    final previousQty = selectedProduct?.quantity ?? 0;
    final previousCostPerUnit = selectedProduct?.costPerUnit ?? 0.0;
    final mergedQuantity = previousQty + newQuantity;
    final mergedCostPerUnit = mergedQuantity <= 0
        ? incomingCostPerUnit
        : ((previousQty * previousCostPerUnit) + purchaseTotal) / mergedQuantity;

    final stock = ProductModel(
      id: selectedProduct?.id,
      name: productName,
      category: selectedCategory!,
      categoryId: selectedCategoryId,
      sellingPrice: sellingPrice,
      purchasePrice: mergedCostPerUnit,
      quantity: mergedQuantity,
      baseUnit: baseUnit,
      costPerUnit: mergedCostPerUnit,
      pricePerUnit: sellingPrice,
      image: productImage?.path ?? selectedProduct?.image,
      createdAt: selectedProduct?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      String message;
      if (selectedProduct != null) {
        await _repository.updateProduct(stock);
        await _repository.replaceUnitConversions(stock.id!, unitConversions);
        await _repository.replaceSellingOptions(stock.id!, sellingOptions);
        message = 'Product updated successfully';
      } else {
        final newId = await _repository.addProduct(stock);
        stock.id = newId;
        await _repository.replaceUnitConversions(newId, unitConversions);
        await _repository.replaceSellingOptions(newId, sellingOptions);
        allProducts.add(stock);
        message = 'Product saved successfully';
      }

      await loadProductNames();
      clearFields();
      selectedProduct = null;
      safeNotifyListeners();

      setLoading(false);

      if (context.mounted) showSnackBar(context, message, success: true);
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        showSnackBar(context, 'Failed to save product: $e', success: false);
      }
    }
  }

  Future<void> loadProductNames() async {
    allProducts = await _repository.loadAllProducts();
    productNames = allProducts.map((p) => p.name).toList();
    safeNotifyListeners();
  }

  Future<void> deleteStock(int id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProductNames();
    } catch (_) {}
  }

  void triggerValidation() {
    showValidationErrors = true;
    safeNotifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    safeNotifyListeners();
  }

  Future<void> populateFromSelectedProduct(ProductModel product) async {
    selectedProduct = product;
    editSavedSetup = false;
    productController.text = product.name;
    autocompleteFieldController?.text = product.name;
    setCategoryByName(product.category);
    purchasePriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();
    baseUnitController.text = product.baseUnit;
    purchaseUnitController.text = product.baseUnit;
    if (!baseUnitOptions.contains(product.baseUnit)) {
      baseUnitOptions = [...baseUnitOptions, product.baseUnit]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    productImage = product.image != null ? File(product.image!) : null;
    unitConversions = product.id == null
        ? []
        : await _repository.getUnitConversions(product.id!);
    sellingOptions = product.id == null
        ? []
        : await _repository.getSellingOptions(product.id!);
    useAdvancedUnitSetup =
        product.baseUnit.toLowerCase() != 'pcs' || unitConversions.isNotEmpty;

    // After loading conversions, set the purchase unit and convert selling price
    // back to per-purchase-unit so the field shows the human-friendly value
    if (unitConversions.isNotEmpty && product.pricePerUnit > 0) {
      // Use the smallest conversion as the primary purchase unit (e.g. kilo for rice)
      final primary = unitConversions.reduce((a, b) =>
          a.baseQuantity < b.baseQuantity ? a : b);
      purchaseUnitController.text = primary.unitName;
      final displayPrice = product.pricePerUnit * primary.baseQuantity;
      sellingPriceController.text = displayPrice.toStringAsFixed(
        displayPrice % 1 == 0 ? 0 : 2,
      );
    } else if (product.pricePerUnit > 0) {
      sellingPriceController.text = product.pricePerUnit.toStringAsFixed(
        product.pricePerUnit % 1 == 0 ? 0 : 2,
      );
    }

    safeNotifyListeners();
  }

  void clearFields() {
    productController.clear();
    purchasePriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();
    baseUnitController.text = 'pcs';
    purchaseUnitController.text = 'pcs';
    conversionNameController.clear();
    conversionQuantityController.clear();
    sellingOptionLabelController.clear();
    sellingOptionQuantityController.clear();
    sellingOptionPriceController.clear();
    autocompleteFieldController?.clear();

    selectedCategory = null;
    selectedCategoryId = null;
    productImage = null;
    selectedProduct = null;
    unitConversions = [];
    sellingOptions = [];
    useAdvancedUnitSetup = false;
    editSavedSetup = false;
    showValidationErrors = false;

    safeNotifyListeners();
  }
}
