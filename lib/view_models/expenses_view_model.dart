import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

final expensesViewModelProvider = ChangeNotifierProvider<ExpensesViewModel>((
  ref,
) {
  final repoFuture = ref.watch(expenseRepositoryProvider.future);
  return ExpensesViewModel(expenseRepositoryFuture: repoFuture);
});

class ExpensesViewModel extends ChangeNotifier {
  final Future<ExpenseRepository> expenseRepositoryFuture;

  ExpensesViewModel({required this.expenseRepositoryFuture});

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

  String get formattedDate {
    return DateFormat('MMMM d, y').format(selectedDate);
  }

  void setCategory(String? value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    selectedDate = value;
    notifyListeners();
  }

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

    try {
      final repo = await expenseRepositoryFuture;

      final expense = ExpenseModel(
        accountId: await repo.accountRepository.getAccountId(),
        amount: double.parse(amountController.text),
        category: selectedCategory!,
        description: descriptionController.text,
        receipt: receiptImage?.path,
        createdAt: selectedDate.toIso8601String(),
      );

      debugPrint("debug - Saving Expense (before insert): ${expense.toMap()}");

      final newId = await repo.addExpense(
        expense,
      ); // SQLite returns generated id

      final savedExpense = ExpenseModel(
        id: newId,
        accountId: expense.accountId,
        amount: expense.amount,
        category: expense.category,
        description: expense.description,
        receipt: expense.receipt,
        createdAt: expense.createdAt,
      );

      debugPrint(
        "debug - Expense saved successfully: ${savedExpense.toMap()}",
      ); // after saving

      successMessage = "Expense saved.";
      isLoading = false;
      notifyListeners();
      resetForm();
      return true;
    } catch (e) {
      debugPrint("debug - Failed to save expense: $e");
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

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
