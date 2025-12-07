import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final expensesViewModelProvider = ChangeNotifierProvider<ExpensesViewModel>((
  ref,
) {
  return ExpensesViewModel();
});

class ExpensesViewModel extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedCategory;
  XFile? receiptImage;

  bool isLoading = false;
  bool showValidationErrors = false;

  String? successMessage;
  String? errorMessage;

  final List<String> categories = [
    "Pagkaon",
    "Tubig / Kuryente",
    "Transportasyon",
    "Mga Bayronon",
    "Uban pa",
  ];

  // -------------------------------------------------------------
  // Getters used by the screen
  // -------------------------------------------------------------
  String get formattedDate {
    return DateFormat('MMMM d, yyyy').format(selectedDate);
  }

  // -------------------------------------------------------------
  // Setters
  // -------------------------------------------------------------
  void setCategory(String? value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    selectedDate = value;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Receipt Picker (screen expects pickReceipt())
  // -------------------------------------------------------------
  Future<void> pickReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source);

    if (img != null) {
      receiptImage = img;
      notifyListeners();
    }
  }

  void removeReceipt() {
    receiptImage = null;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------
  void triggerValidation() {
    showValidationErrors = true;
    notifyListeners();
  }

  bool validate() {
    if (amountController.text.isEmpty) return false;
    if (selectedCategory == null) return false;
    if (descriptionController.text.isEmpty) return false;
    return true;
  }

  // -------------------------------------------------------------
  // Save
  // -------------------------------------------------------------
  Future<bool> save() async {
    triggerValidation();

    if (!validate()) {
      errorMessage = "Please fill out all fields.";
      notifyListeners();
      return false;
    }

    isLoading = true;
    successMessage = null;
    errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    isLoading = false;
    successMessage = "Expense saved.";
    errorMessage = null;
    notifyListeners();

    resetForm();
    return true;
  }

  // -------------------------------------------------------------
  // Reset Form
  // -------------------------------------------------------------
  void resetForm() {
    amountController.clear();
    descriptionController.clear();
    selectedCategory = null;
    receiptImage = null;
    selectedDate = DateTime.now();
    showValidationErrors = false;
    notifyListeners();
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
