import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Add this import
import '../models/cashflow_model.dart';
import '../repositories/cashflow_repository.dart';

final cashflowViewModelProvider =
    ChangeNotifierProvider<CashflowViewModel>((ref) {
  return CashflowViewModel();
});

class CashflowViewModel extends ChangeNotifier {
  final CashflowRepository _repository = CashflowRepository();
  final List<CashflowRecord> _records = [];

  DateTime? startDate;
  DateTime? endDate;

  List<CashflowRecord> get filteredRecords {
  final filtered = _records.where((r) {
    final afterStart = startDate == null || !r.date.isBefore(startDate!);
    final beforeEnd = endDate == null || !r.date.isAfter(endDate!);
    return afterStart && beforeEnd;
  }).toList();

  // Show newest first (UI only)
  return filtered.reversed.toList();
}

  void setRecords(List<CashflowRecord> records) {
    _records
      ..clear()
      ..addAll(records);
    notifyListeners();
  }

  // Load transactions from DB
  Future<void> loadCashflows() async {
    final records = await _repository.getCashflows();
    setRecords(records);
  }
}