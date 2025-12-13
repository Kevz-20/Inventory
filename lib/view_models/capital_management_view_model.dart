import 'package:flutter/foundation.dart';
import '../models/capital_management_model.dart';
import '../repositories/capital_management_repository.dart';

class CapitalManagementViewModel extends ChangeNotifier {
  final CapitalManagementRepository capitalRepository;

  CapitalManagementViewModel(this.capitalRepository);

  List<CapitalManagementModel> capitals = [];
  double totalBalance = 0.0;
  bool isLoading = false;
  String? error;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Load all capital records
  Future<void> loadCapitals() async {
    _setLoading(true);
    error = null;
    debugPrint("loadCapitals: Start loading capitals");

    try {
      capitals = await capitalRepository.getCapitalByAccount();
      debugPrint("loadCapitals: Loaded ${capitals.length} capitals");
      for (var c in capitals) {
        debugPrint(
          "Capital ID: ${c.id}, Cash: ${c.cashOnHand}, Capital: ${c.capital}, BankCash: ${c.bankCash}, Remarks: ${c.remarks}",
        );
      }
    } catch (e) {
      capitals = [];
      error = e.toString();
      debugPrint("loadCapitals: Error - $error");
    }

    _setLoading(false);
    debugPrint("loadCapitals: Finished loading capitals");
  }

  // Load total balance by summing cashOnHand + bankCash
  Future<void> loadTotalBalance() async {
    _setLoading(true);
    error = null;

    try {
      totalBalance = capitals.fold<double>(
        0.0,
        (sum, c) => sum + c.capital + c.cashOnHand + c.bankCash,
      );
    } catch (e) {
      totalBalance = 0.0;
      error = e.toString();
    }

    _setLoading(false);
  }

  // Add new capital
  Future<void> addCapital({
    required double capitalAmount,
    double cashOnHand = 0,
    double bankCash = 0,
    String remarks = '',
  }) async {
    _setLoading(true);
    error = null;

    try {
      final model = CapitalManagementModel(
        accountId: 0,
        cashOnHand: cashOnHand,
        capital: capitalAmount,
        bankCash: bankCash,
        remarks: remarks,
      );

      await capitalRepository.insertCapital(model);
      await loadCapitals();
      await loadTotalBalance();
    } catch (e) {
      error = e.toString();
    }

    _setLoading(false);
  }

  // Update capital
  Future<void> updateCapital(CapitalManagementModel model) async {
    _setLoading(true);
    error = null;

    try {
      await capitalRepository.updateCapital(model);
      await loadCapitals();
      await loadTotalBalance();
    } catch (e) {
      error = e.toString();
    }

    _setLoading(false);
  }

  // Delete capital
  Future<void> deleteCapital(int id) async {
    _setLoading(true);
    error = null;

    try {
      await capitalRepository.deleteCapital(id);
      await loadCapitals();
      await loadTotalBalance();
    } catch (e) {
      error = e.toString();
    }

    _setLoading(false);
  }

  // Reset state
  void reset() {
    capitals = [];
    totalBalance = 0.0;
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
