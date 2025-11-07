import 'package:flutter_riverpod/flutter_riverpod.dart';

final expensesViewModelProvider =
    StateNotifierProvider<ExpensesViewModel, ExpensesState>(
      (ref) => ExpensesViewModel(),
    );

class ExpensesState {
  final DateTime selectedDate;
  final String? category;
  final String amount;
  final String description;

  ExpensesState({
    required this.selectedDate,
    this.category,
    this.amount = '',
    this.description = '',
  });

  ExpensesState copyWith({
    DateTime? selectedDate,
    String? category,
    String? amount,
    String? description,
  }) {
    return ExpensesState(
      selectedDate: selectedDate ?? this.selectedDate,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }
}

class ExpensesViewModel extends StateNotifier<ExpensesState> {
  ExpensesViewModel() : super(ExpensesState(selectedDate: DateTime.now()));

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setAmount(String amount) {
    state = state.copyWith(amount: amount);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }
}
