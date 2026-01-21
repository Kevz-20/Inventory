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
  final Map<int, TextEditingController> controllers = {};

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
      // Initialize quantity map
      productQuantities[p.id!] ??= 0;

      // Initialize controller if not exists
      if (!controllers.containsKey(p.id!)) {
        controllers[p.id!] = TextEditingController(text: productQuantities[p.id!]!.toString());
      }

      // Remove all previous listeners
      final controller = controllers[p.id!]!;
      controller.removeListener(() {});

      // Add listener
      controller.addListener(() {
        final text = controller.text;

        // When empty, reset to 0
        if (text.isEmpty) {
          productQuantities[p.id!] = 0;
          return;
        }

        // Parse user input
        int qty = int.tryParse(text) ?? 0;

        // Clamp to current stock
        if (qty > p.quantity) qty = p.quantity;
        if (qty < 0) qty = 0;

        productQuantities[p.id!] = qty;
        calculateTotal();
        notifyListeners();
      });
    }
  }

  isLoading = false;
  notifyListeners();
}

  Future<void> reloadProducts() async => await loadProducts();

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

  // Allow increment only if stock > 0
  if (product.quantity > 0 && currentQty < product.quantity) {
    updateQuantity(product, currentQty + 1);
  }
}

  void decrementQuantity(ProductModel product) {
  if (product.id == null) return;
  final currentQty = productQuantities[product.id!] ?? 0;

  if (currentQty > 0) {
    updateQuantity(product, currentQty - 1);
  }
}

  void updateQuantity(ProductModel product, int qty) {
  if (product.id == null) return;

  // Clamp to stock
  if (qty > product.quantity) qty = product.quantity;
  if (qty < 0) qty = 0;

  productQuantities[product.id!] = qty;

  // Sync controller text only if different
  final controller = controllers[product.id!];
  if (controller != null && controller.text != qty.toString()) {
    controller.text = qty.toString();
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

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

  bool get hasSelectedProducts {
    return productQuantities.values.any((qty) => qty > 0);
  }

  void resetQuantities() {
    for (var p in products) {
      if (p.id == null) continue;
      productQuantities[p.id!] = 0;

      if (controllers[p.id!] != null) {
        controllers[p.id!]!.text = '0';
      } else {
        controllers[p.id!] = TextEditingController(text: '0');
      }
    }
    total = 0;
    notifyListeners();
  }

  /// ===========================
  /// Checkout / Save Sale
  /// ===========================
 Future<void> checkout({bool isCash = true, int? customerId, DateTime? dueDate}) async {
  if (_repository == null) return;

  // Collect purchased items
  final purchasedItems = <Map<String, dynamic>>[];

  for (var p in products) {
    final qty = productQuantities[p.id!] ?? 0;
    if (qty > 0) {
      purchasedItems.add({
        'productId': p.id,
        'quantity': qty,
        'price': p.sellingPrice,
        'subtotal': qty * p.sellingPrice,
      });
    }
  }

  if (purchasedItems.isEmpty) return;

  if (isCash) {
    // Use repository method to save cash sale and update stock
    await _repository!.checkoutCash(purchasedItems);
  } else {
    if (customerId == null) return;
    await _repository!.checkoutCredit(
      purchasedItems,
      customerId,
      dueDate: dueDate,
    );
  }

  // ✅ Reload products from DB to update stock in UI
  await loadProducts();

  // ✅ Reset quantity selectors
  resetQuantities();

  // ✅ Notify UI
  notifyListeners();
}

}
