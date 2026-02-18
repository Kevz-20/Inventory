import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/capital_management_repository.dart';
import '../repositories/account_repository.dart';
import '../providers/database_provider.dart';
import '../models/current_user.dart';

final expensesViewModelProvider = ChangeNotifierProvider<ExpensesViewModel>((
  ref,
) {
  final repoFuture = ref.watch(expenseRepositoryProvider.future);
  final dbFuture = ref.watch(databaseProvider.future);
  final accountRepo = AccountRepository();
  return ExpensesViewModel(
    expenseRepositoryFuture: repoFuture,
    databaseFuture: dbFuture,
    accountRepository: accountRepo,
  );
});

class ExpensesViewModel extends ChangeNotifier {
  final Future<ExpenseRepository> expenseRepositoryFuture;
  final Future databaseFuture;
  final AccountRepository accountRepository;

  ExpensesViewModel({
    required this.expenseRepositoryFuture,
    required this.databaseFuture,
    required this.accountRepository,
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
  // LOAD EXPENSES
  // ------------------------
  Future<void> loadExpenses() async {
    try {
      final repo = await expenseRepositoryFuture;
      _expenses = await repo.fetchAllExpenses();
      notifyListeners();
    } catch (_) {
      _expenses = [];
      notifyListeners();
    }
  }

  // ------------------------
  // SNACKBAR (same pattern as LoginViewModel)
  // ------------------------
  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool success,
  }) {
    final color = success ? Colors.green : Colors.red;
    final icon = success ? Icons.check_circle_outline : Icons.error_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ------------------------
  // MAIN SAVE FUNCTION
  // ------------------------
  Future<bool> save({
    required BuildContext context,
    required String createdByFirstName,
    String? createdByMiddleName,
    required String createdByLastName,
  }) async {
    triggerValidation();

    if (!validate()) {
      _showSnackBar(context, 'Please fill out all fields', success: false);
      return false;
    }

    isLoading = true;
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

      try {
        _expenses = await expenseRepo.fetchAllExpenses();
      } catch (_) {}

      isLoading = false;
      notifyListeners();

      resetForm();

      if (context.mounted) {
        _showSnackBar(context, 'Expense saved successfully!', success: true);
      }

      return true;
    } catch (e) {
      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        if (e.toString().contains('Insufficient cash')) {
          _showSnackBar(context, 'Insufficient cash on hand', success: false);
        } else {
          _showSnackBar(
            context,
            'Something went wrong. Please try again.',
            success: false,
          );
        }
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
