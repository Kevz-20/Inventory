import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeStatementViewModel extends ChangeNotifier {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Sample values for the screen
  double merchandiseSales = 5000;
  double totalSales = 5000;
  double kumpra = 2000;
  double transportation = 500;
  double totalExpenses = 2500;
  double netIncome = 2500;

  /// Format the date for display
  String getFormattedDate(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Show date picker and update date
  Future<void> selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      if (isStart) {
        _startDate = pickedDate;
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = pickedDate;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
      notifyListeners();
    }
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return formatter.format(value);
  }
}
