import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/capital_management_repository.dart';
import '../providers/database_provider.dart';

final expensesViewModelProvider =
    ChangeNotifierProvider<ExpensesViewModel>((ref) {
  final repoFuture = ref.watch(expenseRepositoryProvider.future);
  final dbFuture = ref.watch(databaseProvider.future);
  return ExpensesViewModel(
    expenseRepositoryFuture: repoFuture,
    databaseFuture: dbFuture,
  );
});

class ExpensesViewModel extends ChangeNotifier {
  final Future<ExpenseRepository> expenseRepositoryFuture;
  final Future databaseFuture;

  ExpensesViewModel({
    required this.expenseRepositoryFuture,
    required this.databaseFuture,
  });

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

  String get formattedDate =>
      DateFormat('MMMM d, y').format(selectedDate);

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

  // 🔥 MAIN SAVE LOGIC
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
      final expenseRepo = await expenseRepositoryFuture;
      final db = await databaseFuture;
      final capitalRepo = CapitalManagementRepository(db);

      final accountId =
          await expenseRepo.accountRepository.getAccountId();

      final amount = double.parse(amountController.text);

      // 1️⃣ Deduct cash first
      await capitalRepo.deductCash(
        accountId: accountId,
        amount: amount,
      );

      // 2️⃣ Save expense
      final expense = ExpenseModel(
        accountId: accountId,
        amount: amount,
        category: selectedCategory!,
        description: descriptionController.text,
        receipt: receiptImage?.path,
        createdAt: selectedDate.toIso8601String(),
      );

      await expenseRepo.addExpense(expense);

      successMessage = "Expense saved successfully.";
      resetForm();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
