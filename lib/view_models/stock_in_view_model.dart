// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
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
  bool useAdvancedUnitSetup = false;

  TextEditingController? autocompleteFieldController;
  final TextEditingController productController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController baseUnitController =
      TextEditingController(text: 'pcs');
  final TextEditingController conversionNameController =
      TextEditingController();
  final TextEditingController conversionQuantityController =
      TextEditingController();

  bool get hasUnsavedData =>
      productController.text.isNotEmpty ||
      purchasePriceController.text.isNotEmpty ||
      sellingPriceController.text.isNotEmpty ||
      quantityController.text.isNotEmpty ||
      baseUnitController.text.trim().toLowerCase() != 'pcs' ||
      unitConversions.isNotEmpty ||
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
    conversionNameController.dispose();
    conversionQuantityController.dispose();
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

  void setUseAdvancedUnitSetup(bool value) {
    useAdvancedUnitSetup = value;
    if (!value) {
      baseUnitController.text = 'pcs';
      unitConversions = [];
      conversionNameController.clear();
      conversionQuantityController.clear();
    }
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

    unitConversions = [
      ...unitConversions.where(
        (item) => item.unitName.toLowerCase() != name.toLowerCase(),
      ),
      ProductUnitConversion(unitName: name, baseQuantity: qty),
    ]..sort((a, b) => b.baseQuantity.compareTo(a.baseQuantity));

    conversionNameController.clear();
    conversionQuantityController.clear();
    safeNotifyListeners();
  }

  void removeUnitConversion(ProductUnitConversion conversion) {
    unitConversions = unitConversions
        .where((item) => item.unitName != conversion.unitName)
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

    if (productName.isEmpty ||
        selectedCategory == null ||
        purchaseText.isEmpty ||
        sellingText.isEmpty ||
        qtyText.isEmpty ||
        baseUnit.isEmpty) {
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

    final sellingPrice = double.tryParse(sellingText.replaceAll(',', '')) ?? 0;
    final purchaseInput = double.tryParse(purchaseText.replaceAll(',', '')) ?? 0;
    final newQuantity = int.tryParse(qtyText.replaceAll(',', '')) ?? 0;

    if (purchaseInput <= 0) {
      showSnackBar(
        context,
        useAdvancedUnitSetup
            ? 'Total stock cost must be greater than 0'
            : 'Purchase price must be greater than 0',
        success: false,
      );
      return;
    }
    if (sellingPrice <= 0) {
      showSnackBar(
        context,
        'Selling price per $baseUnit must be greater than 0',
        success: false,
      );
      return;
    }
    if (newQuantity <= 0) {
      showSnackBar(
        context,
        'Stock quantity in $baseUnit must be greater than 0',
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

    final purchaseTotal =
        useAdvancedUnitSetup ? purchaseInput : purchaseInput * newQuantity;
    final incomingCostPerUnit =
        useAdvancedUnitSetup ? purchaseTotal / newQuantity : purchaseInput;
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
        message = 'Product updated successfully';
      } else {
        final newId = await _repository.addProduct(stock);
        stock.id = newId;
        await _repository.replaceUnitConversions(newId, unitConversions);
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
    productController.text = product.name;
    autocompleteFieldController?.text = product.name;
    setCategoryByName(product.category);
    purchasePriceController.clear();
    sellingPriceController.text = product.pricePerUnit.toStringAsFixed(
      product.pricePerUnit % 1 == 0 ? 0 : 2,
    );
      quantityController.clear();
    baseUnitController.text = product.baseUnit;
    productImage = product.image != null ? File(product.image!) : null;
    unitConversions = product.id == null
        ? []
        : await _repository.getUnitConversions(product.id!);
    useAdvancedUnitSetup =
        product.baseUnit.toLowerCase() != 'pcs' || unitConversions.isNotEmpty;
    safeNotifyListeners();
  }

  void clearFields() {
    productController.clear();
    purchasePriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();
    baseUnitController.text = 'pcs';
    conversionNameController.clear();
    conversionQuantityController.clear();
    autocompleteFieldController?.clear();

    selectedCategory = null;
    selectedCategoryId = null;
    productImage = null;
    selectedProduct = null;
    unitConversions = [];
    useAdvancedUnitSetup = false;
    showValidationErrors = false;

    safeNotifyListeners();
  }
}
