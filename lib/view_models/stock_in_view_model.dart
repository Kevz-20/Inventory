import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/stock_in_repository.dart';
import '../repositories/product_category_repository.dart';
import '../services/db_service.dart';
import '../models/product_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // ✅ Categories from DB
  List<Map<String, dynamic>> categoryRows = []; // [{id:1,name:"Imnonon"}]
  String? selectedCategory; // name (UI)
  int? selectedCategoryId; // id (DB)

  // ✅ THIS FIXES YOUR ERROR
  List<String> get categoryNames =>
      categoryRows.map((e) => (e['name'] ?? '').toString()).toList();

  File? productImage;
  List<String> productNames = [];
  List<ProductModel> allProducts = [];
  ProductModel? selectedProduct;

  TextEditingController? autocompleteFieldController;
  final TextEditingController productController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  bool get hasUnsavedData =>
      productController.text.isNotEmpty ||
      purchasePriceController.text.isNotEmpty ||
      sellingPriceController.text.isNotEmpty ||
      quantityController.text.isNotEmpty ||
      selectedCategory != null ||
      productImage != null;

  final List<String> months = [
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
    productController.clear();
    purchasePriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();
    autocompleteFieldController = null;
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

  // -------------------- CATEGORY (DB) --------------------

  Future<void> loadCategories() async {
    try {
      categoryRows = await _categoryRepo.getAllCategories(); // [{id,name}]
    } catch (_) {
      categoryRows = [];
    }

    // keep selection consistent
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

    // if exists, just select it
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

  // -------------------- Date / UI --------------------

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

  // -------------------- SAVE PRODUCT --------------------

  Future<void> saveProduct(BuildContext context) async {
    if (!isInitialized) return;

    final productName = effectiveProductName;

    final purchaseText = purchasePriceController.text.trim();
    final sellingText = sellingPriceController.text.trim();
    final qtyText = quantityController.text.trim();

    if (productName.isEmpty ||
        selectedCategory == null ||
        purchaseText.isEmpty ||
        sellingText.isEmpty ||
        qtyText.isEmpty) {
      showSnackBar(context, 'Please fill all required fields', success: false);
      return;
    }

    // ✅ Ensure category id exists
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
    final purchasePrice =
        double.tryParse(purchaseText.replaceAll(',', '')) ?? 0;
    final newQuantity = int.tryParse(qtyText.replaceAll(',', '')) ?? 0;

    if (purchasePrice <= 0) {
      showSnackBar(
        context,
        'Purchase price must be greater than 0',
        success: false,
      );
      return;
    }
    if (sellingPrice <= 0) {
      showSnackBar(
        context,
        'Selling price must be greater than 0',
        success: false,
      );
      return;
    }
    if (newQuantity <= 0) {
      showSnackBar(context, 'Quantity must be greater than 0', success: false);
      return;
    }
    if (sellingPrice <= purchasePrice) {
      showSnackBar(
        context,
        'Selling price must be greater than purchase price',
        success: false,
      );
      return;
    }

    setLoading(true);

    ProductModel? existingProduct;
    for (var p in allProducts) {
      if (p.name.toLowerCase() == productName.toLowerCase()) {
        existingProduct = p;
        break;
      }
    }

    selectedProduct ??= existingProduct;

    final stock = ProductModel(
      id: selectedProduct?.id,
      name: productName,
      category: selectedCategory!, // keep for display
      categoryId: selectedCategoryId, // ✅ save to DB
      sellingPrice: sellingPrice,
      purchasePrice: purchasePrice,
      quantity: (selectedProduct?.quantity ?? 0) + newQuantity,
      image: productImage?.path ?? selectedProduct?.image,
      createdAt: selectedProduct?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      String message;
      if (selectedProduct != null) {
        await _repository.updateProduct(stock);
        message = 'Product updated successfully';
      } else {
        final newId = await _repository.addProduct(stock);
        stock.id = newId;
        allProducts.add(stock);
        message = 'Product saved successfully';
      }

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

  // -------------------- LOAD PRODUCTS --------------------

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

  void clearFields() {
    productController.clear();
    purchasePriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();
    autocompleteFieldController?.clear();

    selectedCategory = null;
    selectedCategoryId = null;
    productImage = null;
    selectedProduct = null;
    showValidationErrors = false;

    safeNotifyListeners();
  }
}