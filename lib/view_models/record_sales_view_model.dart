import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import '../services/db_service.dart';

final salesViewModelProvider = ChangeNotifierProvider<SalesViewModel>((ref) {
  return SalesViewModel();
});

class SalesViewModel extends ChangeNotifier {
  ProductRepository? _repository;
  List<ProductModel> products = [];
  bool isLoading = false;
  int total = 0;
  int selectedCategoryIndex = 0;

  final Map<int, int> productQuantities = {};

  static const List<String> categories = [
    'All',
    'Imnonon',
    'Alak',
    'Pagkaon',
    'Panglimpyo',
    'Gamit sa Panimalay',
    'Gamit sa Eskwelahan',
    'Uban Pa',
  ];

  SalesViewModel() {
    debugPrint('⭐ SalesViewModel initialized');
    // Ensure async initialization runs after construction
    Future.microtask(() => _initRepository());
  }

  Future<void> _initRepository() async {
    debugPrint('⭐ _initRepository() called');
    try {
      final dbFuture = DBService.instance.database;
      debugPrint('⭐ DBService.database future created: $dbFuture');

      final db = await dbFuture;
      debugPrint('⭐ DBService.database resolved: $db');

      _repository = ProductRepository(db);
      debugPrint('⭐ ProductRepository initialized: $_repository');

      await loadProducts();
      debugPrint('⭐ loadProducts() completed');
    } catch (e, st) {
      debugPrint('⭐ Error in _initRepository(): $e');
      debugPrint('⭐ Stack trace: $st');
    }
  }

  Future<void> loadProducts() async {
    if (_repository == null) return;

    debugPrint('⭐ Loading products...');
    isLoading = true;
    notifyListeners();

    try {
      products = await _repository!.getProducts();
      debugPrint('⭐ Products loaded: ${products.length}');
    } catch (e, st) {
      debugPrint('⭐ Error loading products: $e');
      debugPrint('⭐ Stack trace: $st');
    }

    for (var p in products) {
      if (p.id != null) {
        productQuantities[p.id!] = 0;
        debugPrint('⭐ Product initialized: ${p.name} (ID: ${p.id})');
      }
    }

    isLoading = false;
    notifyListeners();
    debugPrint('⭐ Finished loading products');
  }

  Future<void> reloadProducts() async {
    debugPrint('⭐ Reloading products...');
    await loadProducts();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
    debugPrint('⭐ Selected category: ${categories[index]}');
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategoryIndex == 0) return products;
    final filtered = products
        .where(
          (p) =>
              p.category.toLowerCase() ==
              categories[selectedCategoryIndex].toLowerCase(),
        )
        .toList();
    debugPrint('⭐ Filtered products count: ${filtered.length}');
    return filtered;
  }

  void incrementQuantity(ProductModel product) {
    if (product.id == null) return;
    final currentQty = productQuantities[product.id!] ?? 0;
    if (currentQty < product.quantity) {
      productQuantities[product.id!] = currentQty + 1;
      calculateTotal();
      notifyListeners();
      debugPrint(
        '⭐ Incremented ${product.name} to ${productQuantities[product.id!]}',
      );
    }
  }

  void decrementQuantity(ProductModel product) {
    if (product.id == null) return;
    final current = productQuantities[product.id!] ?? 0;
    if (current > 0) {
      productQuantities[product.id!] = current - 1;
      calculateTotal();
      notifyListeners();
      debugPrint(
        '⭐ Decremented ${product.name} to ${productQuantities[product.id!]}',
      );
    }
  }

  void updateQuantity(ProductModel product, int qty) {
    if (product.id == null) return;
    if (qty < 0) qty = 0;
    if (qty > product.quantity) qty = product.quantity;

    productQuantities[product.id!] = qty;
    calculateTotal();
    notifyListeners();
    debugPrint('⭐ Updated ${product.name} quantity to $qty');
  }

  int getQuantity(ProductModel product) {
    if (product.id == null) return 0;
    final qty = productQuantities[product.id!] ?? 0;
    debugPrint('⭐ Quantity for ${product.name}: $qty');
    return qty;
  }

  void calculateTotal() {
    total = 0;
    for (var p in products) {
      if (p.id == null) continue;
      final qty = productQuantities[p.id!] ?? 0;
      total += (p.sellingPrice * qty).toInt();
    }
    debugPrint('⭐ Total calculated: $total');
  }

  Future<void> checkout() async {
    debugPrint('⭐ Checkout started');
    final purchasedItems = <Map<String, dynamic>>[];

    for (var p in products) {
      final qty = productQuantities[p.id!] ?? 0;
      if (qty > 0) {
        purchasedItems.add({
          'productId': p.id,
          'name': p.name,
          'quantity': qty,
          'price': p.sellingPrice,
          'total': qty * p.sellingPrice,
        });
        p.quantity -= qty;
        debugPrint('⭐ Purchased ${p.name}: $qty');
      }
    }

    if (_repository != null) {
      await _repository!.savePurchase(purchasedItems);
      debugPrint('⭐ Purchase saved to repository');
    }

    for (var id in productQuantities.keys) {
      productQuantities[id] = 0;
    }

    calculateTotal();
    notifyListeners();
    debugPrint('⭐ Checkout completed');
  }
}
