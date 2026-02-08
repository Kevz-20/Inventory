import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/expense_model.dart';
import '../../repositories/expense_repository.dart';
import '../../providers/database_provider.dart';
import '../../view_models/expenses_view_model.dart';

/// -------------------------
/// LOCAL EDIT VIEWMODEL
/// -------------------------
class EditExpenseViewModel extends ChangeNotifier {
  final ExpenseModel expense;
  final Future<ExpenseRepository> expenseRepositoryFuture;
  final Future databaseFuture;

  EditExpenseViewModel({
    required this.expense,
    required this.expenseRepositoryFuture,
    required this.databaseFuture,
  }) {
    amountController.text = NumberFormat("#,##0.00").format(expense.amount);
    descriptionController.text = expense.description;
    selectedCategory = expense.category;
    selectedDate = DateTime.parse(expense.createdAt);
  }

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedCategory;
  DateTime selectedDate = DateTime.now();

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

  void setCategory(String? value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    selectedDate = value;
    notifyListeners();
  }

  void triggerValidation() {
    showValidationErrors = true;
    notifyListeners();
  }

  bool validate() {
    if (amountController.text.isEmpty ||
        double.tryParse(amountController.text.replaceAll(',', '')) == null) return false;
    if (selectedCategory == null) return false;
    if (descriptionController.text.isEmpty) return false;
    return true;
  }

  void _showMessage(String msg, {bool isError = false, int durationSeconds = 2}) {
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

  Future<bool> save() async {
    triggerValidation();
    if (!validate()) {
      _showMessage("Please fill out all fields correctly.", isError: true);
      return false;
    }

    isLoading = true;
    successMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      final expenseRepo = await expenseRepositoryFuture;

      // -------------------------
      // Keep original Recorded By fields
      // -------------------------
      final updatedExpense = ExpenseModel(
        id: expense.id,
        amount: double.parse(amountController.text.replaceAll(',', '')),
        category: selectedCategory!,
        description: descriptionController.text,
        receipt: expense.receipt,
        createdAt: selectedDate.toIso8601String(),
        createdByFirstName: expense.createdByFirstName.isNotEmpty
            ? expense.createdByFirstName
            : 'Unknown',
        createdByMiddleName: expense.createdByMiddleName,
        createdByLastName: expense.createdByLastName.isNotEmpty
            ? expense.createdByLastName
            : 'Unknown',
      );

      await expenseRepo.updateExpense(updatedExpense);

      _showMessage("Expense updated successfully");
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _showMessage("Something went wrong. Please try again.", isError: true);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

/// -------------------------
/// EXISTING EXPENSES SCREEN
/// -------------------------
class ExistingExpensesScreen extends ConsumerWidget {
  const ExistingExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(expensesViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Mga Gasto'),
      ),
      body: vm.expenses.isEmpty
          ? const Center(child: Text('No expenses recorded yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: vm.expenses.length,
              itemBuilder: (context, index) {
                final exp = vm.expenses[index];

                // -------------------------
                // Build "Recorded By" text safely
                // -------------------------
                final recordedBy = [
                  exp.createdByFirstName.isNotEmpty ? exp.createdByFirstName : 'Unknown',
                  if (exp.createdByMiddleName != null && exp.createdByMiddleName!.isNotEmpty)
                    exp.createdByMiddleName!,
                  exp.createdByLastName.isNotEmpty ? exp.createdByLastName : 'Unknown',
                ].join(' ');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(exp.description.isNotEmpty
                        ? exp.description
                        : 'Wala deskripsyon'),
                    subtitle: Text(
                        '₱${exp.amount.toStringAsFixed(2)} • ${exp.category}\nRecorded By: $recordedBy'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        _showEditExpenseModal(context, ref, exp);
                      },
                    ),
                    onTap: () {
                      _showExpenseDetails(context, exp);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showEditExpenseModal(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    final editExpenseProvider =
        ChangeNotifierProvider.autoDispose<EditExpenseViewModel>((ref) {
      return EditExpenseViewModel(
        expense: expense,
        expenseRepositoryFuture: ref.read(expenseRepositoryProvider.future),
        databaseFuture: ref.read(databaseProvider.future),
      );
    });

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Consumer(
            builder: (context, ref, _) {
              final vm = ref.watch(editExpenseProvider);
              return _EditExpenseModalContent(vm: vm);
            },
          ),
        );
      },
    );
  }

  /// -------------------------
  /// Gasto Details Modal
  /// -------------------------
  void _showExpenseDetails(BuildContext context, ExpenseModel expense) {
    final recordedBy = [
      expense.createdByFirstName.isNotEmpty ? expense.createdByFirstName : 'Unknown',
      if (expense.createdByMiddleName != null && expense.createdByMiddleName!.isNotEmpty)
        expense.createdByMiddleName!,
      expense.createdByLastName.isNotEmpty ? expense.createdByLastName : 'Unknown',
    ].join(' ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      _detailRow("Amount", '₱${expense.amount.toStringAsFixed(2)}'),
                      const SizedBox(height: 10),
                      _detailRow(
                        "Date",
                        DateFormat('MMMM d, y').format(DateTime.parse(expense.createdAt)),
                      ),
                      const SizedBox(height: 10),
                      _detailRow("Category", expense.category),
                      const SizedBox(height: 10),
                      _detailRow(
                        "Note",
                        expense.description.isNotEmpty ? expense.description : "Wala deskripsyon",
                      ),
                      const SizedBox(height: 10),
                      _detailRow("Recorded By", recordedBy),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// -------------------------
  /// Detail Row Widget
  /// -------------------------
  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

/// -------------------------
/// EDIT MODAL CONTENT (unchanged)
/// -------------------------
class _EditExpenseModalContent extends StatelessWidget {
  final EditExpenseViewModel vm;
  const _EditExpenseModalContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                if (vm.successMessage != null)
                  _banner(vm.successMessage!, AppColors.success),
                if (vm.errorMessage != null)
                  _banner(vm.errorMessage!, AppColors.error),
                const SizedBox(height: 10),
                _inputRow(
                  label: "Amount",
                  controller: vm.amountController,
                  showError: vm.showValidationErrors,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                _inputDropdown(
                  label: "Category",
                  value: vm.selectedCategory,
                  items: vm.categories,
                  showError: vm.showValidationErrors,
                  onChanged: vm.setCategory,
                ),
                const SizedBox(height: 15),
                _inputRow(
                  label: "Description",
                  controller: vm.descriptionController,
                  showError: vm.showValidationErrors,
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: vm.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) vm.setDate(picked);
                  },
                  child: _inputRow(
                    label: "Date",
                    controller: TextEditingController(text: vm.formattedDate),
                    readOnly: true,
                    showError: false,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          final success = await vm.save();
                          if (success) Navigator.pop(context, true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vm.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes",
                          style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _banner(String msg, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _inputRow({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    bool showError = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isError = showError && controller.text.isEmpty;
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isError ? AppColors.error : AppColors.border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isError ? AppColors.error : AppColors.primary,
                width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _inputDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool showError,
    required void Function(String?) onChanged,
  }) {
    final isError = showError && value == null;

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isError ? AppColors.error : AppColors.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isError ? AppColors.error : AppColors.primary, width: 1.2),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
