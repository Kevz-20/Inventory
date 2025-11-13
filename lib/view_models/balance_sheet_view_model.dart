import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceSheetViewModel extends ChangeNotifier {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<String> assets = [
    "Cash on Hand",
    "Cash in Bank",
    "Accounts Receivable",
    "Inventory",
    "Fixed Assets",
  ];

  List<String> liabilities = ["Accounts Payable"];

  double totalAssets = 150000;
  double totalLiabilities = 50000;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  String getFormattedDate(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return DateFormat('MMMM dd, yyyy').format(date);
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
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
      notifyListeners();
    }
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return formatter.format(value);
  }
}
