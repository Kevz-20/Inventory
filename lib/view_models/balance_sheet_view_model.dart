import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/balancesheet_repository.dart';

class BalanceSheetViewModel extends ChangeNotifier {
  final BalanceSheetRepository repository = BalanceSheetRepository();

  // ---------------- Dates ----------------
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // ---------------- Data ----------------
  Map<String, double> assets = {};
  Map<String, double> liabilities = {};
  Map<String, double> equity = {};

  double get totalAssets => assets.values.fold(0, (prev, cur) => prev + cur);
  double get totalLiabilities => liabilities.values.fold(0, (prev, cur) => prev + cur);
  double get totalEquity => equity.values.fold(0, (prev, cur) => prev + cur);

  // ---------------- Methods ----------------
  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return formatter.format(value);
  }

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

  // ---------------- Load data from DB ----------------
  /// All transactions are visible to all users — no account filtering
  Future<void> loadBalanceSheet() async {
    assets = await repository.getAssets();         // no accountIds
    liabilities = await repository.getLiabilities(); // no accountIds
    equity = await repository.getEquity();         // no accountIds
    notifyListeners();
  }
}
