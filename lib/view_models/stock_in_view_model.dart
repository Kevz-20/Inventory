import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/stock_in_repository.dart';
import '../services/db_service.dart';
import '../models/product_model.dart';

final stockInViewModelProvider =
    ChangeNotifierProvider.autoDispose<StockInViewModel>((ref) {
      return StockInViewModel();
    });

class StockInViewModel extends ChangeNotifier {
  late final StockInRepository _repository;
  bool isInitialized = false;
  bool showValidationErrors = false;
  bool _isDisposed = false;

  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  File? productImage;
  List<String> productNames = [];
  List<ProductModel> allProducts = [];
  ProductModel? selectedProduct;

  /// 🔹 used by autocomplete
  TextEditingController? autocompleteFieldController;

  final TextEditingController productController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final quantityController = TextEditingController();

  bool get hasUnsavedData =>
      productController.text.isNotEmpty ||
      purchasePriceController.text.isNotEmpty ||
      sellingPriceController.text.isNotEmpty ||
      quantityController.text.isNotEmpty ||
      selectedCategory != null ||
      productImage != null;

  final List<String> categories = [
    'Imnonon',
    'Alak',
    'Pagkaon',
    'Panglimpyo',
    'Gamit sa Panimalay',
    'Gamit sa Eskwelahan',
    'Uban Pa',
  ];

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

    // Clear regular controllers
    productController.clear();
    purchasePriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();

    // Detach the autocomplete controller to prevent 'used after dispose' errors
    autocompleteFieldController = null;

    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _init() async {
    final db = await DBService.instance.database;
    _repository = StockInRepository(db);
    await loadProductNames();
    isInitialized = true;
    safeNotifyListeners();
  }

  void pickDate(DateTime date) {
    selectedDate = date;
    safeNotifyListeners();
  }

  void setCategory(String? category) {
    selectedCategory = category;
    safeNotifyListeners();
  }

  String get formattedDate =>
      '${months[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';

  String get effectiveProductName {
    final autoText = autocompleteFieldController?.text.trim() ?? '';
    final manualText = productController.text.trim();
    return autoText.isNotEmpty ? autoText : manualText;
  }

  String? get selectedUnitType => null;
  void Function(String? p1)? get setUnitType => null;

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

  // ------------------------
  // SNACKBAR (same pattern as LoginViewModel)
  // ------------------------
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

  // ------------------------
  // MAIN SAVE FUNCTION
  // ------------------------
  Future<void> saveProduct(BuildContext context) async {
    debugPrint('saveProduct() called');

    if (!isInitialized) return;

    final productName = effectiveProductName;

    if (productName.isEmpty || selectedCategory == null) {
      showSnackBar(context, 'Please fill all required fields', success: false);
      return;
    }

    final sellingPrice =
        double.tryParse(sellingPriceController.text.replaceAll(',', '')) ?? 0;
    final purchasePrice =
        double.tryParse(purchasePriceController.text.replaceAll(',', '')) ?? 0;

    if (sellingPrice < purchasePrice) {
      showSnackBar(
        context,
        'Selling price cannot be lower than purchase price.',
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

    final sellingPriceText = sellingPriceController.text.replaceAll(',', '');
    final purchasePriceText = purchasePriceController.text.replaceAll(',', '');
    final int newQuantity =
        int.tryParse(quantityController.text.replaceAll(',', '')) ?? 0;

    final stock = ProductModel(
      id: selectedProduct?.id,
      name: productName,
      category: selectedCategory!,
      sellingPrice: double.tryParse(sellingPriceText) ?? 0,
      purchasePrice: double.tryParse(purchasePriceText) ?? 0,
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
        await _repository.addProduct(stock);
        message = 'Product saved successfully';
      }

      await loadProductNames();
      clearFields();
      selectedProduct = null;

      setLoading(false);

      if (context.mounted) {
        showSnackBar(context, message, success: true);
      }
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        showSnackBar(context, 'Failed to save product: $e', success: false);
      }
    }
  }

  Future<List<ProductModel>> getAllStocks() async {
    if (!isInitialized) return [];
    return await _repository.getProducts();
  }

  Future<void> deleteStock(int id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProductNames();
    } catch (_) {}
  }

  Future<void> loadProductNames() async {
    allProducts = await _repository.loadAllProducts();
    productNames = allProducts.map((p) => p.name).toList();
    safeNotifyListeners();
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
    productImage = null;
    selectedProduct = null;
    showValidationErrors = false;
    safeNotifyListeners();
  }
}
