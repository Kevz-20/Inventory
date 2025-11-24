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

  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  File? productImage;
  List<String> productNames = [];
  List<ProductModel> allProducts = [];
  ProductModel? selectedProduct;

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
    'Food',
    'Vegetables',
    'Snacks',
    'Drinks',
    'Others',
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
  String? errorMessage;
  String? successMessage;

  StockInViewModel() {
    _init();
  }

  Future<void> _init() async {
    final db = await DBService.instance.database;
    _repository = StockInRepository(db);
    await loadProductNames();
    isInitialized = true;
    notifyListeners();
  }

  void pickDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  String get formattedDate =>
      '${months[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      productImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> saveProduct() async {
    if (!isInitialized) return;

    if (productController.text.isEmpty || selectedCategory == null) {
      errorMessage = 'Please fill all required fields';
      notifyListeners();
      return;
    }

    setLoading(true);

    final stock = ProductModel(
      id: selectedProduct?.id,
      name: productController.text,
      category: selectedCategory!,
      sellingPrice: double.tryParse(sellingPriceController.text) ?? 0,
      purchasePrice: double.tryParse(purchasePriceController.text) ?? 0,
      quantity: int.tryParse(quantityController.text) ?? 0,
      image: productImage?.path,
      createdAt: selectedProduct?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (selectedProduct != null) {
        await _repository.updateProduct(stock);
        successMessage = 'Product updated successfully';
      } else {
        await _repository.addProduct(stock);
        successMessage = 'Product saved successfully';
      }
      clearFields();
      selectedProduct = null;
    } catch (e) {
      errorMessage = 'Failed to save product: ${e.toString()}';
    } finally {
      setLoading(false);
      notifyListeners();
      autoClearMessages();
    }
  }

  Future<List<ProductModel>> getAllStocks() async {
    if (!isInitialized) return [];
    return await _repository.getProducts();
  }

  Future<void> updateStock(ProductModel stock) async {
    try {
      await _repository.updateProduct(stock);
      notifyListeners();
    } catch (_) {
      errorMessage = 'Failed to update product';
    }
  }

  Future<void> deleteStock(int id) async {
    try {
      await _repository.deleteProduct(id);
      notifyListeners();
    } catch (_) {
      errorMessage = 'Failed to delete product';
    }
  }

  Future<bool> handleBackPressed(BuildContext context) async {
    if (!hasUnsavedData) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Unsaved product information. Do you want to discard or cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> loadProductNames() async {
    allProducts = await _repository.loadAllProducts();
    productNames = allProducts.map((p) => p.name).toList();
    notifyListeners();
  }

  void triggerValidation() {
    showValidationErrors = true;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void autoClearMessages() {
    Future.delayed(const Duration(seconds: 3), () {
      errorMessage = null;
      successMessage = null;
      notifyListeners();
    });
  }

  void clearFields() {
    productController.clear();
    purchasePriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();
    selectedCategory = null;
    productImage = null;
    errorMessage = null;
    successMessage = null;
    showValidationErrors = false;
    notifyListeners();
  }
}
