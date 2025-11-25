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
    _initRepository();
  }

  Future<void> _initRepository() async {
    final db = await DBService.instance.database;
    _repository = ProductRepository(db);
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (_repository == null) return; // Guard in case repository is not ready

    isLoading = true;
    notifyListeners();

    products = await _repository!.getProducts();

    isLoading = false;
    notifyListeners();
  }

  Future<void> reloadProducts() async => loadProducts();

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
}
