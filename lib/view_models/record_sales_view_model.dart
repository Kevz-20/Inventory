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
    Future.microtask(() => _initRepository());
  }

  Future<void> _initRepository() async {
    try {
      final db = await DBService.instance.database;
      _repository = ProductRepository(db);
      await loadProducts();
    } catch (_) {}
  }

  Future<void> loadProducts() async {
    if (_repository == null) return;

    isLoading = true;
    notifyListeners();

    try {
      products = await _repository!.getProducts();
    } catch (_) {}

    for (var p in products) {
      if (p.id != null) {
        productQuantities[p.id!] = 0;
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> reloadProducts() async {
    await loadProducts();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategoryIndex == 0) return products;
    return products
        .where(
          (p) =>
              p.category.toLowerCase() ==
              categories[selectedCategoryIndex].toLowerCase(),
        )
        .toList();
  }

  void incrementQuantity(ProductModel product) {
    if (product.id == null) return;
    final currentQty = productQuantities[product.id!] ?? 0;
    if (currentQty < product.quantity) {
      productQuantities[product.id!] = currentQty + 1;
      calculateTotal();
      notifyListeners();
    }
  }

  void decrementQuantity(ProductModel product) {
    if (product.id == null) return;
    final current = productQuantities[product.id!] ?? 0;
    if (current > 0) {
      productQuantities[product.id!] = current - 1;
      calculateTotal();
      notifyListeners();
    }
  }

  void updateQuantity(ProductModel product, int qty) {
    if (product.id == null) return;
    if (qty < 0) qty = 0;
    if (qty > product.quantity) qty = product.quantity;

    productQuantities[product.id!] = qty;
    calculateTotal();
    notifyListeners();
  }

  int getQuantity(ProductModel product) {
    if (product.id == null) return 0;
    return productQuantities[product.id!] ?? 0;
  }

  double getSubtotal(ProductModel product) {
    final qty = getQuantity(product);
    return qty * product.sellingPrice;
  }

  void calculateTotal() {
    total = 0;
    for (var p in products) {
      if (p.id == null) continue;
      final qty = productQuantities[p.id!] ?? 0;
      total += (p.sellingPrice * qty).toInt();
    }
  }

  Future<void> checkout() async {
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
      }
    }

    if (_repository != null) {
      await _repository!.savePurchase(purchasedItems);
    }

    for (var id in productQuantities.keys) {
      productQuantities[id] = 0;
    }

    calculateTotal();
    notifyListeners();
  }
}
