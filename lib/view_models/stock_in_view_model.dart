import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final stockInViewModelProvider =
    ChangeNotifierProvider.autoDispose<StockInViewModel>((ref) {
  return StockInViewModel();
});

class StockInViewModel extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  File? productImage;
  
  final TextEditingController productController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  final List<String> categories = ['Fruits', 'Vegetables', 'Snacks', 'Drinks'];
  final List<String> months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
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

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      productImage = File(pickedFile.path);
      notifyListeners();
    }
  }
}
