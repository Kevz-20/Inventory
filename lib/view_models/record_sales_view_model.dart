import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/capital_management_model.dart';
import '../models/product_model.dart';
import '../providers/capital_management_view_model_provider.dart';
import '../repositories/product_repository.dart';
import '../repositories/customer_repository.dart';
import '../services/db_service.dart';
import '../repositories/capital_management_repository.dart';
import '../repositories/account_repository.dart';

/// SalesViewModel for shared/global cash & capital
class SalesViewModel extends ChangeNotifier {
  final void Function()? onCashUpdated; // callback to notify CapitalManagement

  CapitalManagementRepository? _capitalRepository;
  ProductRepository? _productRepository;
  CustomerRepository? _customerRepository;

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

  // ------------------- Selected Customer -------------------
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? get selectedCustomer => _selectedCustomer;

  set selectedCustomer(Map<String, dynamic>? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void resetSelectedCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  // ------------------- Constructor -------------------
  SalesViewModel({this.onCashUpdated}) {
    Future.microtask(() => _initRepository());
  }

  Future<void> _initRepository() async {
  try {
    final db = await DBService.instance.database;
    final accountRepo = AccountRepository(); // still needed for ProductRepository

    _productRepository = ProductRepository(db, accountRepo); // keep both arguments
    _customerRepository = CustomerRepository(db); // CustomerRepository now only needs DB
    _capitalRepository = CapitalManagementRepository(db);

    await loadProducts();
    await loadCustomers();
  } catch (_) {}
}

  // ------------------- Products -------------------
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
          productQuantities[p.id!] =
              text.isEmpty ? 0 : int.tryParse(text)?.clamp(0, p.quantity) ?? 0;
          calculateTotal();
        };

        controller.addListener(_controllerListeners[p.id!]!);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategoryIndex == 0) return products;
    return products
        .where((p) => p.category.toLowerCase() ==
            categories[selectedCategoryIndex].toLowerCase())
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
      controller.selection =
          TextSelection.fromPosition(TextPosition(offset: controller.text.length));

      if (_controllerListeners.containsKey(product.id!)) {
        controller.addListener(_controllerListeners[product.id!]!);
      }
    }

    calculateTotal();
  }

  int getQuantity(ProductModel product) =>
      product.id == null ? 0 : productQuantities[product.id!] ?? 0;

  double getSubtotal(ProductModel product) =>
      getQuantity(product) * product.sellingPrice;

  void calculateTotal() {
    total = 0.0;
    for (var p in products) {
      if (p.id == null) continue;
      total += p.sellingPrice * (productQuantities[p.id!] ?? 0);
    }
    notifyListeners();
  }

  bool get hasSelectedProducts =>
      productQuantities.values.any((qty) => qty > 0);

  void resetQuantities() {
    for (var p in products) {
      if (p.id == null) continue;
      productQuantities[p.id!] = 0;
      controllers[p.id!]?.text = '0';
    }
    total = 0.0;
    notifyListeners();
  }

  // ------------------- Customers -------------------
  Future<void> loadCustomers() async {
  if (_customerRepository == null) return;

  try {
    customers = await _customerRepository!.getCustomers(); // just get all customers
  } catch (_) {
    customers = [];
  }

  notifyListeners();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
  }

  // ------------------- Checkout -------------------
  Future<void> checkout({
    bool isCash = true,
    int? customerId,
    DateTime? dueDate,
  }) async {
    if (_productRepository == null || _customerRepository == null) return;

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
        // Cash sale
        await _productRepository!.checkoutCash(purchasedItems);

        if (_capitalRepository != null) {
          double totalCash = purchasedItems.fold<double>(
            0.0,
            (sum, item) => sum + (item['subtotal'] as double),
          );

          final latest = await _capitalRepository!.getLatestCapital();
          if (latest != null && latest.id != null) {
            final updatedCash = latest.cashOnHand + totalCash;

            final updatedModel = CapitalManagementModel(
              id: latest.id,
              capital: latest.capital,
              cashOnHand: updatedCash,
              bankCash: latest.bankCash,
              remarks: 'Cash sale added',
              createdAt: DateTime.now(),
            );

            await _capitalRepository!.updateCapital(updatedModel);

            if (onCashUpdated != null) onCashUpdated!();
          }
        }
      } else {
        // Credit / Utang
        if (customerId == null || dueDate == null) {
          throw Exception('Customer and due date required for utang.');
        }

        await _productRepository!.checkoutCredit(
            purchasedItems,
            customerId,
            dueDate: dueDate,
          );

          // 🔥 Reload customers from DB
          await loadCustomers();

          final updatedCustomer = customers
    .where((c) => c['id'] == customerId)
    .cast<Map<String, dynamic>>()
    .toList();

if (updatedCustomer.isNotEmpty) {
  _selectedCustomer = updatedCustomer.first;
}

          notifyListeners();
      }
    } catch (_) {
      rethrow;
    }

    await loadProducts();
    resetQuantities();
    resetSelectedCustomer();
  }
}

/// Provider for SalesViewModel
final salesViewModelProvider =
    ChangeNotifierProvider<SalesViewModel>((ref) {
  return SalesViewModel(
    onCashUpdated: () {
      ref.read(capitalManagementViewModelProvider).loadCapitals();
    },
  );
});
