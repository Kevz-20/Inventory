import 'package:flutter/material.dart';

// ViewModel for managing transaction history data and date filters
class TransactionHistoryViewModel extends ChangeNotifier {
  DateTime? _startDate; // selected start date
  DateTime? _endDate; // selected end date

  // sample transaction data
  final List<Map<String, String>> _transactions = [
    {
      'title': 'Groceries',
      'date': 'Oct 31, 2025',
      'amount': '-₱1,200.00',
      'category': 'Food',
      'method': 'Cash',
    },
    {
      'title': 'Salary',
      'date': 'Oct 30, 2025',
      'amount': '+₱25,000.00',
      'category': 'Income',
      'method': 'Bank Transfer',
    },
    {
      'title': 'Electric Bill',
      'date': 'Oct 29, 2025',
      'amount': '-₱3,500.00',
      'category': 'Utilities',
      'method': 'Gcash',
    },
    {
      'title': 'Internet',
      'date': 'Oct 28, 2025',
      'amount': '-₱1,000.00',
      'category': 'Bills',
      'method': 'Credit Card',
    },
  ];

  List<Map<String, String>> get transactions => _transactions;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // checks if the transaction is an expense
  bool isExpense(String amount) => amount.startsWith('-');

  // opens date picker and updates selected date
  Future<void> selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      notifyListeners(); // refreshes UI
    }
  }

  // returns formatted date or label text
  String getFormattedDate(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    if (date == null) {
      return isStart ? 'Start Date' : 'End Date';
    }
    return '${date.month}/${date.day}/${date.year}';
  }
}
