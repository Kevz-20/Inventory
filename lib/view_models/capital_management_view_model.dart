import 'package:flutter/foundation.dart';
import '../models/capital_management_model.dart';
import '../repositories/capital_management_repository.dart';

class CapitalManagementViewModel extends ChangeNotifier {
  final CapitalManagementRepository? repository;

  CapitalManagementViewModel({required this.repository}) {
    if (repository != null) {
      loadCapitals();
    }
  }

  bool isLoading = false;
  String? error;

  List<CapitalManagementModel> capitals = [];

  /// Load all capital records
  Future<void> loadCapitals() async {
    if (repository == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      capitals = await repository!.getAllCapital();
    } catch (e) {
      error = e.toString();
      capitals = [];
    }

    isLoading = false;
    notifyListeners();
  }

  /// Add new capital
  Future<void> addCapital({
    required double capitalAmount,
    String? remarks,
  }) async {
    if (repository == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final model = CapitalManagementModel(
        capital: capitalAmount,
        cashOnHand: capitalAmount,
        bankCash: 0,
        remarks: remarks ?? '',
      );

      await repository!.insertCapital(model);

      await loadCapitals();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  double get totalCapital => capitals.fold(0, (sum, e) => sum + e.capital);

  double get totalCashOnHand =>
      capitals.fold(0, (sum, e) => sum + e.cashOnHand);

  void reset() {
    capitals = [];
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
