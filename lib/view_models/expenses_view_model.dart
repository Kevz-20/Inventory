import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/capital_management_repository.dart';
import '../repositories/account_repository.dart'; // ✅ import AccountRepository
import '../providers/database_provider.dart';
import '../models/current_user.dart'; // ✅ CurrentUser import

final expensesViewModelProvider = ChangeNotifierProvider<ExpensesViewModel>((ref) {
  final repoFuture = ref.watch(expenseRepositoryProvider.future);
  final dbFuture = ref.watch(databaseProvider.future);
  final accountRepo = AccountRepository(); // ✅ 
  return ExpensesViewModel(
    expenseRepositoryFuture: repoFuture,
    databaseFuture: dbFuture,
    accountRepository: accountRepo, // ✅ pass it
  );
});

class ExpensesViewModel extends ChangeNotifier {
  final Future<ExpenseRepository> expenseRepositoryFuture;
  final Future databaseFuture;
  final AccountRepository accountRepository; // ✅ added

  ExpensesViewModel({
    required this.expenseRepositoryFuture,
    required this.databaseFuture,
    required this.accountRepository, // ✅ added
  }) {
    loadExpenses();
  }

  // ------------------------
  // STATE
  // ------------------------
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

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

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
  // LOAD EXPENSES (shared DB)
  // ------------------------
  Future<void> loadExpenses() async {
    try {
      final repo = await expenseRepositoryFuture;
      _expenses = await repo.fetchAllExpenses(); // <-- show all users
      notifyListeners();
    } catch (_) {
      _expenses = [];
      notifyListeners();
    }
  }

  

  

  // ------------------------
  // MESSAGE HANDLER
  // ------------------------
  void _showMessage(String msg, {bool isError = false, int durationSeconds = 2}) {
    if (isError) {
      errorMessage = msg;
    } else {
      successMessage = msg;
    }
    notifyListeners();

    Future.delayed(Duration(seconds: durationSeconds), () {
      try {
        if (isError) {
          errorMessage = null;
        } else {
          successMessage = null;
        }
        notifyListeners();
      } catch (_) {
        // Ignore if view model is disposed
      }
    });
  }

  // ------------------------
  // MAIN SAVE FUNCTION
  // ------------------------
  Future<bool> save({
  required String createdByFirstName,
  String? createdByMiddleName,
  required String createdByLastName,
}) async {
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

    final amount = double.parse(amountController.text);

    await capitalRepo.deductCash(amount: amount);

    final expense = ExpenseModel(
      amount: amount,
      category: selectedCategory!,
      description: descriptionController.text,
      receipt: receiptImage?.path,
      createdAt: selectedDate.toIso8601String(),
      createdByFirstName: CurrentUser.firstName ?? createdByFirstName,
      createdByMiddleName: CurrentUser.middleName ?? createdByMiddleName,
      createdByLastName: CurrentUser.lastName ?? createdByLastName,
    );

    await expenseRepo.addExpense(expense);

    // ✅ Safe refresh of expenses
    try {
      _expenses = await expenseRepo.fetchAllExpenses();
    } catch (_) {
      // Ignore refresh errors; expense is still saved
    }

    _showMessage("Expense saved successfully");
    resetForm();

    isLoading = false;
    return true;
  } catch (e) {
    isLoading = false;
    notifyListeners();

    if (e.toString().contains('Insufficient cash')) {
      _showMessage('Insufficient cash on hand', isError: true);
    } else {
      _showMessage('Something went wrong. Please try again.', isError: true);
    }

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
}
