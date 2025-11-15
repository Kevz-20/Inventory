import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_model.dart';

// Provider for the ViewModel
final transactionHistoryProvider =
    ChangeNotifierProvider<TransactionHistoryViewModel>(
      (ref) => TransactionHistoryViewModel(),
    );

class TransactionHistoryViewModel extends ChangeNotifier {
  List<HistoryModel> transactions = _dummyTransactions;

  String _selectedCategory = 'All';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  String get selectedCategory => _selectedCategory;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  List<HistoryModel> get filteredTransactions {
    return transactions.where((tx) {
      final matchesDate =
          !tx.date.isBefore(_startDate) && !tx.date.isAfter(_endDate);
      final matchesCategory =
          _selectedCategory == 'All' || tx.category == _selectedCategory;
      return matchesDate && matchesCategory;
    }).toList();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }
}

final List<HistoryModel> _dummyTransactions = [
  HistoryModel(
    title: 'Grocery',
    amount: 500,
    category: 'Food',
    method: 'Cash',
    date: DateTime(2025, 11, 1),
  ),
  HistoryModel(
    title: 'Salary',
    amount: 20000,
    category: 'Salary',
    method: 'Bank',
    date: DateTime(2025, 11, 3),
  ),
  HistoryModel(
    title: 'Taxi Ride',
    amount: 120,
    category: 'Transport',
    method: 'Cash',
    date: DateTime(2025, 11, 4),
  ),
];
