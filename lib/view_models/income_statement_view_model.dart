import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeStatementViewModel extends ChangeNotifier {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  double merchandiseSales = 50000;
  double totalSales = 50000;
  double kumpra = 15000;
  double transportation = 5000;
  double totalExpenses = 20000;
  double netIncome = 30000;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

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

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return formatter.format(value);
  }
}
