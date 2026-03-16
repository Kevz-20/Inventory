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

// ✅ NEW repo for expense categories (you will create this)
import '../repositories/expense_category_repository.dart';

final expensesViewModelProvider =
    ChangeNotifierProvider.autoDispose<ExpensesViewModel>((ref) {
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
    _init();
  }

  // ------------------------
  // STATE
  // ------------------------
  DateTime selectedDate = DateTime.now();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  // ✅ DB categories like StockIn
  List<Map<String, dynamic>> categoryRows = []; // [{id:1,name:"Kumpra"}]
  String? selectedCategory; // name
  int? selectedCategoryId; // id

  bool isCategoriesLoading = false;

  XFile? receiptImage;

  bool isLoading = false;
  bool showValidationErrors = false;

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

  String get formattedDate => DateFormat('MMMM d, y').format(selectedDate);

  List<String> get categoryNames =>
      categoryRows.map((e) => (e['name'] ?? '').toString()).toList();

  // ------------------------
  // INIT (StockIn pattern)
  // ------------------------
  Future<void> _init() async {
    await loadExpenseCategories();
    await loadExpenses();
  }

  // ------------------------
  // SETTERS
  // ------------------------
  void setCategoryByName(String? name) {
    selectedCategory = name;

    if (name == null) {
      selectedCategoryId = null;
    } else {
      final row = categoryRows.where((c) => c['name'] == name).toList();
      selectedCategoryId = row.isNotEmpty ? row.first['id'] as int? : null;
    }

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
  // ✅ LOAD CATEGORIES (DB)
  // ------------------------
  Future<void> loadExpenseCategories() async {
    isCategoriesLoading = true;
    notifyListeners();

    try {
      final db = await databaseFuture;
      final catRepo = ExpenseCategoryRepository(db);

      categoryRows = await catRepo.getAllCategories();

      // keep selection consistent
      if (selectedCategoryId != null) {
        final row =
            categoryRows.where((c) => c['id'] == selectedCategoryId).toList();
        if (row.isNotEmpty) {
          selectedCategory = row.first['name'] as String?;
        } else {
          selectedCategory = null;
          selectedCategoryId = null;
        }
      }
    } catch (_) {
      categoryRows = [];
      selectedCategory = null;
      selectedCategoryId = null;
    }

    isCategoriesLoading = false;
    notifyListeners();
  }

  // ✅ Add new category like StockIn
  Future<void> addNewCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      final db = await databaseFuture;
      final catRepo = ExpenseCategoryRepository(db);

      // If exists, just select
      final exists = categoryRows.any(
        (c) => (c['name'] ?? '').toString().toLowerCase() == trimmed.toLowerCase(),
      );
      if (exists) {
        setCategoryByName(
          categoryRows
              .firstWhere((c) =>
                  (c['name'] ?? '').toString().toLowerCase() ==
                  trimmed.toLowerCase())['name']
              .toString(),
        );
        return;
      }

      final id = await catRepo.getOrCreateCategoryId(trimmed);

      await loadExpenseCategories();

      selectedCategory = trimmed;
      selectedCategoryId = id;
      notifyListeners();
    } catch (_) {}
  }

  // ------------------------
  // SNACKBAR
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
  // MAIN SAVE
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

      // ✅ remove commas before parsing
      final amount =
          double.parse(amountController.text.replaceAll(',', '').trim());

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
  // RESET
  // ------------------------
  void resetForm() {
    amountController.clear();
    descriptionController.clear();
    selectedCategory = null;
    selectedCategoryId = null;
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