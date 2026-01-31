import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/capital_management_model.dart';
import '../models/product_model.dart';
import '../providers/capital_management_view_model_provider.dart';
import '../repositories/product_repository.dart';
import '../repositories/customer_repository.dart';
import '../services/db_service.dart';
import '../repositories/capital_management_repository.dart';

/// Updated SalesViewModel with proper callback to update CapitalManagementViewModel
class SalesViewModel extends ChangeNotifier {
  final void Function()?
  onCashUpdated; // 🔹 callback to notify CapitalManagement

  CapitalManagementRepository? _capitalRepository;
  ProductRepository? _productRepository;
  CustomerRepository? _customerRepository;
  Map<String, dynamic>? selectedCustomer;

  List<ProductModel> products = [];
  List<Map<String, dynamic>> customers = [];
  bool isLoading = false;
  double total = 0.0;
  int selectedCategoryIndex = 0;

  final Map<int, int> productQuantities = {};
  final Map<int, TextEditingController> controllers = {};
  final Map<int, VoidCallback> _controllerListeners = {};

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

  SalesViewModel({this.onCashUpdated}) {
    Future.microtask(() => _initRepository());
  }

  Future<void> _initRepository() async {
    try {
      final db = await DBService.instance.database;
      _productRepository = ProductRepository(db);
      _customerRepository = CustomerRepository(db);
      _capitalRepository = CapitalManagementRepository(db);
      await loadProducts();
      await loadCustomers();
    } catch (_) {}
  }

  Future<void> loadProducts() async {
    if (_productRepository == null) return;

    selectedCategoryIndex = 0;
    isLoading = true;
    notifyListeners();

    try {
      products = await _productRepository!.getProducts();
    } catch (_) {
      products = [];
    }

    for (var p in products) {
      if (p.id != null) {
        productQuantities[p.id!] ??= 0;

        if (!controllers.containsKey(p.id!)) {
          controllers[p.id!] = TextEditingController(
            text: productQuantities[p.id!]!.toString(),
          );
        }

        final controller = controllers[p.id!]!;

        if (_controllerListeners.containsKey(p.id!)) {
          controller.removeListener(_controllerListeners[p.id!]!);
        }

        _controllerListeners[p.id!] = () {
          final text = controller.text;
          if (text.isEmpty) {
            productQuantities[p.id!] = 0;
          } else {
            int qty = int.tryParse(text) ?? 0;
            qty = qty.clamp(0, p.quantity);
            productQuantities[p.id!] = qty;
          }
          calculateTotal();
        };

        controller.addListener(_controllerListeners[p.id!]!);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadCustomers({bool allAccounts = true}) async {
    if (_customerRepository == null) return;

    try {
      customers = await _customerRepository!.getCustomers(
        allAccounts: allAccounts,
      );
    } catch (_) {
      customers = [];
    }

    notifyListeners();
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
    qty = qty.clamp(0, product.quantity);
    productQuantities[product.id!] = qty;

    final controller = controllers[product.id!];
    if (controller != null && controller.text != qty.toString()) {
      if (_controllerListeners.containsKey(product.id!)) {
        controller.removeListener(_controllerListeners[product.id!]!);
      }

      controller.text = qty.toString();
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );

      if (_controllerListeners.containsKey(product.id!)) {
        controller.addListener(_controllerListeners[product.id!]!);
      }
    }

    calculateTotal();
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
    total = 0.0;
    for (var p in products) {
      if (p.id == null) continue;
      total += p.sellingPrice * (productQuantities[p.id!] ?? 0);
    }
    notifyListeners();
  }

  bool get hasSelectedProducts {
    return productQuantities.values.any((qty) => qty > 0);
  }

  void resetQuantities() {
    for (var p in products) {
      if (p.id == null) continue;
      productQuantities[p.id!] = 0;
      controllers[p.id!]?.text = '0';
    }
    total = 0.0;
    notifyListeners();
  }

  /// 🔹 Checkout method with callback to refresh CapitalManagementViewModel
  Future<void> checkout({
    bool isCash = true,
    int? customerId,
    DateTime? dueDate,
  }) async {
    if (_productRepository == null) return;

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

    try {
      if (isCash) {
        // Record cash sale
        await _productRepository!.checkoutCash(purchasedItems);

        // Update cash on hand in CapitalManagement
        if (_capitalRepository != null) {
          double totalCash = purchasedItems.fold<double>(
            0.0,
            (sum, item) => sum + (item['subtotal'] as double),
          );

          final capitals = await _capitalRepository!.getCapitalByAccount();
          if (capitals.isNotEmpty) {
            final latest = capitals.last;
            final updatedCash = latest.cashOnHand + totalCash;

            final updatedModel = CapitalManagementModel(
              id: latest.id,
              accountId: latest.accountId,
              capital: latest.capital,
              cashOnHand: updatedCash,
              bankCash: latest.bankCash,
              remarks: 'Cash sale added',
              createdAt: DateTime.now(),
            );

            await _capitalRepository!.updateCapital(updatedModel);

            // 🔹 Call the callback to refresh the CapitalManagementViewModel
            if (onCashUpdated != null) onCashUpdated!();
          }
        }
      } else {
        if (customerId == null || dueDate == null) {
          throw Exception('Customer and due date required for utang.');
        }
        await _productRepository!.checkoutCredit(
          purchasedItems,
          customerId,
          dueDate: dueDate,
        );
      }
    } catch (_) {
      rethrow;
    }

    await loadProducts();
    resetQuantities();
  }
}

/// 🔹 Updated provider passing callback
final salesViewModelProvider = ChangeNotifierProvider<SalesViewModel>((ref) {
  return SalesViewModel(
    onCashUpdated: () {
      // This will reload the CapitalManagementViewModel when cash is updated
      ref.read(capitalManagementViewModelProvider).loadCapitals();
    },
  );
});
