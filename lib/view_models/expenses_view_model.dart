import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final expensesViewModelProvider = ChangeNotifierProvider<ExpensesViewModel>((
  ref,
) {
  return ExpensesViewModel();
});

class ExpensesViewModel extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedCategory;
  XFile? receiptImage;

  final List<String> categories = [
    "Pagkaon",
    "Tubig / Kuryente",
    "Transportasyon",
    "Mga Bayronon",
    "Uban pa",
  ];

  void setCategory(String value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    selectedDate = value;
    notifyListeners();
  }

  Future<void> pickReceiptFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      receiptImage = image;
      notifyListeners();
    }
  }

  Future<void> pickReceiptFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      receiptImage = image;
      notifyListeners();
    }
  }

  void removeReceipt() {
    receiptImage = null;
    notifyListeners();
  }

  bool validate() {
    if (amountController.text.isEmpty) return false;
    if (selectedCategory == null) return false;
    if (descriptionController.text.isEmpty) return false;
    return true;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    await Future.delayed(const Duration(milliseconds: 400));

    return true;
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
