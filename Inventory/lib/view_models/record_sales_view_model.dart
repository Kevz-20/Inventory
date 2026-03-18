import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/capital_management_model.dart';
import '../models/product_model.dart';
import '../models/product_selling_option.dart';
import '../models/product_unit_conversion.dart';
import '../providers/capital_management_view_model_provider.dart';
import '../repositories/account_repository.dart';
import '../repositories/capital_management_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/product_category_repository.dart';
import '../repositories/product_repository.dart';
import '../services/db_service.dart';

class AppliedSellingOptionSummary {
  final ProductSellingOption option;
  final int count;

  const AppliedSellingOptionSummary({
    required this.option,
    required this.count,
  });
}

class SalesViewModel extends ChangeNotifier {
  final void Function()? onCashUpdated;

  CapitalManagementRepository? _capitalRepository;
  ProductRepository? _productRepository;
  CustomerRepository? _customerRepository;
  ProductCategoryRepository? _categoryRepository;

  List<ProductModel> products = [];
  List<Map<String, dynamic>> customers = [];
  bool isLoading = false;
  double total = 0.0;
  int selectedCategoryIndex = 0;

  final Map<int, int> productQuantities = {};
  final Map<int, double> productAmounts = {};
  final Map<int, TextEditingController> controllers = {};
  final Map<int, TextEditingController> amountControllers = {};
  final Map<int, VoidCallback> _controllerListeners = {};
  final Map<int, List<ProductUnitConversion>> productUnitConversions = {};
  final Map<int, List<ProductSellingOption>> productSellingOptions = {};
  final Map<int, Map<String, int>> appliedSellingOptionCounts = {};

  List<Map<String, dynamic>> _dbCategories = [];

  List<String> get categoryNames {
    final names = _dbCategories
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((n) => n.isNotEmpty)
        .toList();

    return ['All', ...names];
  }

  int? categoryIdByIndex(int index) {
    if (index <= 0) return null;
    final rowIndex = index - 1;
    if (rowIndex < 0 || rowIndex >= _dbCategories.length) return null;

    final id = _dbCategories[rowIndex]['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  }

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

  SalesViewModel({this.onCashUpdated}) {
    Future.microtask(_initRepository);
  }

  Future<void> _initRepository() async {
    try {
      final db = await DBService.instance.database;
      final accountRepo = AccountRepository();

      _productRepository = ProductRepository(db, accountRepo);
      _customerRepository = CustomerRepository(db);
      _capitalRepository = CapitalManagementRepository(db);
      _categoryRepository = ProductCategoryRepository(db);

      await loadCategories();
      await loadProducts();
      await loadCustomers();
    } catch (_) {}
  }

  Future<void> loadCategories() async {
    final repo = _categoryRepository;
    if (repo == null) return;

    try {
      _dbCategories = await repo.getAllCategories();
    } catch (_) {
      _dbCategories = [];
    }

    if (selectedCategoryIndex >= categoryNames.length) {
      selectedCategoryIndex = 0;
    }

    notifyListeners();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
  }

  double getEffectiveUnitPrice(ProductModel product) {
    if (product.pricePerUnit > 0) return product.pricePerUnit;
    return product.sellingPrice;
  }

  bool supportsPesoEntry(ProductModel product) =>
      product.baseUnit.toLowerCase() != 'pcs' &&
      getEffectiveUnitPrice(product) > 0;

  List<ProductUnitConversion> unitConversionsFor(ProductModel product) =>
      product.id == null
          ? const <ProductUnitConversion>[]
          : (productUnitConversions[product.id!] ??
              const <ProductUnitConversion>[]);

  List<ProductSellingOption> sellingOptionsFor(ProductModel product) =>
      product.id == null
          ? const <ProductSellingOption>[]
          : (productSellingOptions[product.id!] ??
              const <ProductSellingOption>[]);

  List<AppliedSellingOptionSummary> appliedSellingOptionsFor(
    ProductModel product,
  ) {
    final id = product.id;
    if (id == null) return const <AppliedSellingOptionSummary>[];

    final counts = appliedSellingOptionCounts[id];
    if (counts == null || counts.isEmpty) {
      return const <AppliedSellingOptionSummary>[];
    }

    final options = sellingOptionsFor(product);
    final summaries = <AppliedSellingOptionSummary>[];

    for (final option in options) {
      final count = counts[option.label] ?? 0;
      if (count <= 0) continue;
      summaries.add(
        AppliedSellingOptionSummary(option: option, count: count),
      );
    }

    return summaries;
  }

  Map<String, int> appliedSellingOptionCountMap(ProductModel product) {
    final id = product.id;
    if (id == null) return const <String, int>{};
    return Map<String, int>.from(appliedSellingOptionCounts[id] ?? const <String, int>{});
  }

  void _clearAppliedSellingOptions(ProductModel product) {
    final id = product.id;
    if (id == null) return;
    appliedSellingOptionCounts.remove(id);
  }

  Future<void> loadProducts() async {
    if (_productRepository == null) return;

    selectedCategoryIndex = 0;
    isLoading = true;
    notifyListeners();

    try {
      products = await _productRepository!.getProducts();
      productUnitConversions
        ..clear()
        ..addAll(await _productRepository!.getAllUnitConversions());
      productSellingOptions
        ..clear()
        ..addAll(await _productRepository!.getAllSellingOptions());
    } catch (_) {
      products = [];
      productUnitConversions.clear();
      productSellingOptions.clear();
    }

    for (final p in products) {
      final id = p.id;
      if (id == null) continue;

      productQuantities[id] ??= 0;
      productAmounts[id] ??= 0;

      controllers[id] ??= TextEditingController(
        text: productQuantities[id].toString(),
      );
      amountControllers[id] ??= TextEditingController(
        text: productAmounts[id] == 0 ? '' : productAmounts[id]!.toStringAsFixed(2),
      );

      final controller = controllers[id]!;
      if (_controllerListeners.containsKey(id)) {
        controller.removeListener(_controllerListeners[id]!);
      }

      _controllerListeners[id] = () {
        final text = controller.text.trim();
        if (text.isEmpty) {
          productQuantities[id] = 0;
          productAmounts[id] = 0;
          calculateTotal();
          return;
        }

        final parsed = int.tryParse(text) ?? 0;
        final clamped = parsed.clamp(0, p.quantity);
        productQuantities[id] = clamped;
        productAmounts[id] = clamped * getEffectiveUnitPrice(p);

        if (parsed != clamped) {
          controller
            ..text = clamped.toString()
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
        }

        final amountController = amountControllers[id];
        if (amountController != null) {
          amountController.text =
              clamped == 0 ? '' : productAmounts[id]!.toStringAsFixed(2);
        }

        calculateTotal();
      };

      controller.addListener(_controllerListeners[id]!);
    }

    isLoading = false;
    notifyListeners();
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategoryIndex == 0) return products;

    final selectedName = categoryNames[selectedCategoryIndex].toLowerCase();
    final selectedId = categoryIdByIndex(selectedCategoryIndex);

    return products.where((p) {
      final matchesId =
          selectedId != null && p.categoryId != null && p.categoryId == selectedId;
      final matchesName = p.category.toLowerCase() == selectedName;
      return matchesId || matchesName;
    }).toList();
  }

  void setTypedQuantity(ProductModel product, String value) {
    if (product.id == null) return;
    final id = product.id!;
    final controller = controllers[id];

    if (value.trim().isEmpty) {
      _clearAppliedSellingOptions(product);
      productQuantities[id] = 0;
      productAmounts[id] = 0;
      calculateTotal();
      return;
    }

    final parsed = int.tryParse(value) ?? 0;
    final clamped = parsed.clamp(0, product.quantity);

    _clearAppliedSellingOptions(product);
    productQuantities[id] = clamped;
    productAmounts[id] = clamped * getEffectiveUnitPrice(product);

    if (controller != null && controller.text != clamped.toString()) {
      if (_controllerListeners.containsKey(id)) {
        controller.removeListener(_controllerListeners[id]!);
      }

      controller.text = clamped.toString();
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );

      if (_controllerListeners.containsKey(id)) {
        controller.addListener(_controllerListeners[id]!);
      }
    }

    final amountController = amountControllers[id];
    if (amountController != null) {
      amountController.text = clamped == 0 ? '' : productAmounts[id]!.toStringAsFixed(2);
    }

    calculateTotal();
  }

  void setTypedAmount(ProductModel product, String value) {
    if (product.id == null) return;

    final id = product.id!;
    final amount = double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    final unitPrice = getEffectiveUnitPrice(product);

    if (amount <= 0 || unitPrice <= 0) {
      _clearAppliedSellingOptions(product);
      productQuantities[id] = 0;
      productAmounts[id] = 0;
      final qtyController = controllers[id];
      if (qtyController != null) qtyController.text = '0';
      calculateTotal();
      return;
    }

    final maxAmount = product.quantity * unitPrice;
    final clampedAmount = amount.clamp(0, maxAmount);
    final baseQty = (clampedAmount / unitPrice).floor().clamp(0, product.quantity);
    final subtotal = baseQty * unitPrice;

    _clearAppliedSellingOptions(product);
    productQuantities[id] = baseQty;
    productAmounts[id] = subtotal;

    final qtyController = controllers[id];
    if (qtyController != null) {
      qtyController.text = baseQty.toString();
    }

    calculateTotal();
  }

  void applyUnitConversion(ProductModel product, ProductUnitConversion conversion) {
    _clearAppliedSellingOptions(product);
    final nextQty = getQuantity(product) + conversion.baseQuantity;
    updateQuantity(product, nextQty);
  }

  void applySellingOption(ProductModel product, ProductSellingOption option) {
    if (product.id == null) return;
    final id = product.id!;
    final baseQty = option.baseQuantity ?? 0;
    final price = option.price;
    if (baseQty <= 0 || price <= 0) return;

    final currentQty = productQuantities[id] ?? 0;
    final currentAmount = productAmounts[id] ?? 0;
    final nextQty = currentQty + baseQty;
    if (nextQty > product.quantity) {
      return;
    }

    productQuantities[id] = nextQty;
    productAmounts[id] = currentAmount + price;
    final counts = {...(appliedSellingOptionCounts[id] ?? <String, int>{})};
    counts[option.label] = (counts[option.label] ?? 0) + 1;
    appliedSellingOptionCounts[id] = counts;

    final controller = controllers[id];
    if (controller != null && controller.text != nextQty.toString()) {
      if (_controllerListeners.containsKey(id)) {
        controller.removeListener(_controllerListeners[id]!);
      }
      controller.text = nextQty.toString();
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      if (_controllerListeners.containsKey(id)) {
        controller.addListener(_controllerListeners[id]!);
      }
    }

    final amountController = amountControllers[id];
    if (amountController != null) {
      amountController.text = productAmounts[id]!.toStringAsFixed(2);
    }

    calculateTotal();
  }

  void incrementQuantity(ProductModel product) {
    if (product.id == null) return;
    final id = product.id!;
    final currentQty = productQuantities[id] ?? 0;

    if (product.quantity > 0 && currentQty < product.quantity) {
      _clearAppliedSellingOptions(product);
      updateQuantity(product, currentQty + 1);
    }
  }

  void decrementQuantity(ProductModel product) {
    if (product.id == null) return;
    final id = product.id!;
    final currentQty = productQuantities[id] ?? 0;

    if (currentQty > 0) {
      _clearAppliedSellingOptions(product);
      updateQuantity(product, currentQty - 1);
    }
  }

  void updateQuantity(ProductModel product, int qty) {
    if (product.id == null) return;
    final id = product.id!;

    qty = qty.clamp(0, product.quantity);
    _clearAppliedSellingOptions(product);
    productQuantities[id] = qty;
    productAmounts[id] = qty * getEffectiveUnitPrice(product);

    final controller = controllers[id];
    if (controller != null && controller.text != qty.toString()) {
      if (_controllerListeners.containsKey(id)) {
        controller.removeListener(_controllerListeners[id]!);
      }

      controller.text = qty.toString();
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );

      if (_controllerListeners.containsKey(id)) {
        controller.addListener(_controllerListeners[id]!);
      }
    }

    final amountController = amountControllers[id];
    if (amountController != null) {
      amountController.text =
          qty == 0 ? '' : productAmounts[id]!.toStringAsFixed(2);
    }

    calculateTotal();
  }

  void setProductSelection(
    ProductModel product, {
    required int qty,
    required double subtotal,
    Map<String, int>? appliedOptionCounts,
  }) {
    final id = product.id;
    if (id == null) return;

    final clampedQty = qty.clamp(0, product.quantity);
    final safeSubtotal = clampedQty <= 0
        ? 0.0
        : subtotal.clamp(0, double.infinity).toDouble();

    if (appliedOptionCounts == null || appliedOptionCounts.isEmpty || clampedQty == 0) {
      appliedSellingOptionCounts.remove(id);
    } else {
      appliedSellingOptionCounts[id] = Map<String, int>.from(appliedOptionCounts);
    }

    productQuantities[id] = clampedQty;
    productAmounts[id] = safeSubtotal;

    final controller = controllers[id];
    if (controller != null) {
      if (_controllerListeners.containsKey(id)) {
        controller.removeListener(_controllerListeners[id]!);
      }
      controller.text = clampedQty.toString();
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      if (_controllerListeners.containsKey(id)) {
        controller.addListener(_controllerListeners[id]!);
      }
    }

    final amountController = amountControllers[id];
    if (amountController != null) {
      amountController.text = safeSubtotal == 0 ? '' : safeSubtotal.toStringAsFixed(2);
    }

    calculateTotal();
  }

  int getQuantity(ProductModel product) =>
      product.id == null ? 0 : productQuantities[product.id!] ?? 0;

  double getSubtotal(ProductModel product) =>
      product.id == null ? 0 : productAmounts[product.id!] ?? 0;

  void calculateTotal() {
    double newTotal = 0.0;

    for (final p in products) {
      final id = p.id;
      if (id == null) continue;
      newTotal += productAmounts[id] ?? 0;
    }

    total = newTotal;
    notifyListeners();
  }

  bool get hasSelectedProducts =>
      productQuantities.values.any((qty) => qty > 0);

  void resetQuantities() {
    for (final p in products) {
      final id = p.id;
      if (id == null) continue;

      productQuantities[id] = 0;
      productAmounts[id] = 0;
      appliedSellingOptionCounts.remove(id);

      final controller = controllers[id];
      if (controller != null && controller.text != '0') {
        if (_controllerListeners.containsKey(id)) {
          controller.removeListener(_controllerListeners[id]!);
        }
        controller.text = '0';
        if (_controllerListeners.containsKey(id)) {
          controller.addListener(_controllerListeners[id]!);
        }
      }

      final amountController = amountControllers[id];
      if (amountController != null) {
        amountController.clear();
      }
    }

    total = 0.0;
    notifyListeners();
  }

  Future<void> loadCustomers() async {
    if (_customerRepository == null) return;

    try {
      customers = await _customerRepository!.getCustomers();
    } catch (_) {
      customers = [];
    }

    notifyListeners();
  }

  Future<void> checkout({
    bool isCash = true,
    int? customerId,
    DateTime? dueDate,
  }) async {
    if (_productRepository == null || _customerRepository == null) return;

    final purchasedItems = <Map<String, dynamic>>[];

    for (final p in products) {
      final id = p.id;
      if (id == null) continue;

      final qty = productQuantities[id] ?? 0;
      if (qty <= 0) continue;

      purchasedItems.add({
        'productId': id,
        'quantity': qty,
        'price': getEffectiveUnitPrice(p),
        'subtotal': productAmounts[id] ?? (qty * getEffectiveUnitPrice(p)),
        'appliedSellingOptions': appliedSellingOptionsFor(p)
            .map(
              (entry) => {
                'label': entry.option.label,
                'count': entry.count,
                'baseQuantity': entry.option.baseQuantity,
                'price': entry.option.price,
              },
            )
            .toList(),
      });
    }

    if (purchasedItems.isEmpty) return;

    try {
      if (isCash) {
        await _productRepository!.checkoutCash(purchasedItems);

        if (_capitalRepository != null) {
          final totalCash = purchasedItems.fold<double>(
            0.0,
            (sum, item) => sum + ((item['subtotal'] as num).toDouble()),
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
              createdAt: latest.createdAt,
            );

            await _capitalRepository!.updateCapital(updatedModel);

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

final salesViewModelProvider = ChangeNotifierProvider<SalesViewModel>((ref) {
  return SalesViewModel(
    onCashUpdated: () {
      ref.read(capitalManagementViewModelProvider).loadCapitals();
    },
  );
});
