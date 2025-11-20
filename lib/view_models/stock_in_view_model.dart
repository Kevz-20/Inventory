import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final stockInViewModelProvider =
    ChangeNotifierProvider.autoDispose<StockInViewModel>((ref) {
      return StockInViewModel();
    });

class StockInViewModel extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  final TextEditingController productController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  final List<String> categories = ['Fruits', 'Vegetables', 'Snacks', 'Drinks'];
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
}
