import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryViewModel extends ChangeNotifier {
  DateTime? _startDate;
  DateTime? _endDate;

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
      'title': 'Dinner at Jollibee',
      'date': 'Oct 30, 2025',
      'amount': '-₱450.00',
      'category': 'Food',
      'method': 'Gcash',
    },
    {
      'title': 'Jeepney Fare',
      'date': 'Oct 29, 2025',
      'amount': '-₱60.00',
      'category': 'Transport',
      'method': 'Cash',
    },
    {
      'title': 'Gas Refill',
      'date': 'Oct 28, 2025',
      'amount': '-₱800.00',
      'category': 'Transport',
      'method': 'Debit Card',
    },
    {
      'title': 'Electric Bill',
      'date': 'Oct 27, 2025',
      'amount': '-₱3,500.00',
      'category': 'Bills',
      'method': 'Gcash',
    },
    {
      'title': 'Water Bill',
      'date': 'Oct 26, 2025',
      'amount': '-₱600.00',
      'category': 'Bills',
      'method': 'Online Banking',
    },
    {
      'title': 'Clothing Purchase',
      'date': 'Oct 25, 2025',
      'amount': '-₱1,800.00',
      'category': 'Shopping',
      'method': 'Credit Card',
    },
    {
      'title': 'Shoes from Lazada',
      'date': 'Oct 24, 2025',
      'amount': '-₱2,400.00',
      'category': 'Shopping',
      'method': 'Gcash',
    },
    {
      'title': 'Salary',
      'date': 'Oct 23, 2025',
      'amount': '+₱25,000.00',
      'category': 'Salary',
      'method': 'Bank Transfer',
    },
    {
      'title': 'Freelance Project',
      'date': 'Oct 22, 2025',
      'amount': '+₱8,000.00',
      'category': 'Salary',
      'method': 'PayPal',
    },
    {
      'title': 'Charity Donation',
      'date': 'Oct 21, 2025',
      'amount': '-₱500.00',
      'category': 'Other',
      'method': 'Cash',
    },
    {
      'title': 'Gift Received',
      'date': 'Oct 20, 2025',
      'amount': '+₱2,000.00',
      'category': 'Other',
      'method': 'Cash',
    },
    {
      'title': 'Internet Bill',
      'date': 'Oct 19, 2025',
      'amount': '-₱1,000.00',
      'category': 'Utilities',
      'method': 'Credit Card',
    },
    {
      'title': 'Mobile Load',
      'date': 'Oct 18, 2025',
      'amount': '-₱300.00',
      'category': 'Utilities',
      'method': 'Gcash',
    },
  ];

  String _selectedCategory = 'All';

  List<Map<String, String>> get transactions => _transactions;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get selectedCategory => _selectedCategory;

  // Main filter: category + date range
  List<Map<String, String>> get filteredTransactions {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');

    return _transactions.where((t) {
      final tDate = formatter.parse(t['date']!);

      final matchesCategory =
          _selectedCategory == 'All' || t['category'] == _selectedCategory;

      final matchesDateRange =
          (_startDate == null ||
              tDate.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
          (_endDate == null ||
              tDate.isBefore(_endDate!.add(const Duration(days: 1))));

      return matchesCategory && matchesDateRange;
    }).toList();
  }

  bool isExpense(String amount) => amount.startsWith('-');

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
      notifyListeners();
    }
  }

  String getFormattedDate(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    if (date == null) {
      return isStart ? 'Start Date' : 'End Date';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
