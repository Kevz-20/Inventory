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

  List<ProductModel> get filteredProducts {
    if (selectedCategory == null) return allProducts;
    final categoryIndex = categories.indexOf(selectedCategory!);
    return allProducts.where((p) => p.categoryIndex == categoryIndex).toList();
  }

  Future<void> saveProduct(BuildContext context) async {
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
    final newQuantity =
        int.tryParse(quantityController.text.replaceAll(',', '')) ?? 0;

    if (newQuantity <= 0) {
      showSnackBar(context, 'Quantity must be greater than 0', success: false);
      return;
    }
    if (sellingPrice < purchasePrice) {
      showSnackBar(
        context,
        'Selling price cannot be lower than purchase price',
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
      category: selectedCategory!,
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
        allProducts.add(stock); // live update
        message = 'Product saved successfully';
      }

      clearFields();
      selectedProduct = null;
      safeNotifyListeners(); // <-- live update the UI

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
    productImage = null;
    selectedProduct = null;
    showValidationErrors = false;
    safeNotifyListeners();
  }
}
