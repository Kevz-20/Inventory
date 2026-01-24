import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/capital_management_repository.dart';
import '../providers/database_provider.dart';

final expensesViewModelProvider = ChangeNotifierProvider<ExpensesViewModel>((
  ref,
) {
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
    "Kumpra",
    "Tubig / Kuryente",
    "Transportasyon",
    "Mga Bayronon",
    "Uban pa",
  ];

  String get formattedDate => DateFormat('MMMM d, y').format(selectedDate);

  // ------------------------
  // SETTERS
  // ------------------------
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

  // ------------------------
  // MESSAGE HANDLER
  // ------------------------
  void _showMessage(
    String msg, {
    bool isError = false,
    int durationSeconds = 2,
  }) {
    if (isError) {
      errorMessage = msg;
    } else {
      successMessage = msg;
    }
    notifyListeners();

    Future.delayed(Duration(seconds: durationSeconds), () {
      if (isError) {
        errorMessage = null;
      } else {
        successMessage = null;
      }
      notifyListeners();
    });
  }

  // ------------------------
  // MAIN SAVE FUNCTION
  // ------------------------
  Future<bool> save() async {
    triggerValidation();

    if (!validate()) {
      _showMessage("Please fill out all fields", isError: true);
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

      final accountId = await expenseRepo.accountRepository.getAccountId();
      final amount = double.parse(amountController.text);

      // Deduct cash first
      await capitalRepo.deductCash(accountId: accountId, amount: amount);

      // Save expense
      final expense = ExpenseModel(
        accountId: accountId,
        amount: amount,
        category: selectedCategory!,
        description: descriptionController.text,
        receipt: receiptImage?.path,
        createdAt: selectedDate.toIso8601String(),
      );

      await expenseRepo.addExpense(expense);

      _showMessage("Expense saved successfully");
      resetForm();

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e.toString().contains('Insufficient cash')) {
        _showMessage('Insufficient cash on hand', isError: true);
      } else {
        _showMessage('Something went wrong. Please try again.', isError: true);
      }

      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ------------------------
  // RESET FORM
  // ------------------------
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
