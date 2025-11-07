import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryViewModel extends ChangeNotifier {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String selectedCategory = 'All';

  final List<Map<String, String>> transactions = [
    {
      'title': 'Grocery',
      'amount': '₱500',
      'category': 'Food',
      'method': 'Cash',
      'date': '2025-11-01',
    },
    {
      'title': 'Salary',
      'amount': '₱20000',
      'category': 'Salary',
      'method': 'Bank',
      'date': '2025-11-03',
    },
  ];

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  List<Map<String, String>> get filteredTransactions {
    return transactions.where((tx) {
      final date = DateTime.parse(tx['date']!);
      final matchesDate =
          date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(_endDate.add(const Duration(days: 1)));
      final matchesCategory =
          selectedCategory == 'All' || tx['category'] == selectedCategory;
      return matchesDate && matchesCategory;
    }).toList();
  }

  String getFormattedDate(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  bool isExpense(String amount) => amount.contains('-');
}
