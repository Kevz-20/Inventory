import 'package:flutter/foundation.dart';
import '../models/transaction_history_model.dart';
import '../repositories/transaction_history_repository.dart';

class TransactionHistoryViewModel extends ChangeNotifier {
  final TransactionHistoryRepository repository;

  TransactionHistoryViewModel({required this.repository});

  List<TransactionHistory> _transactions = [];
  List<TransactionHistory> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String _category = 'All';

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get category => _category;

  // Set filters
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    fetchTransactions();
  }

  void setCategory(String category) {
    _category = category;
    fetchTransactions();
  }

  // Fetch transactions from repository
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await repository.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
      );
    } catch (e) {
      _error = 'Failed to load transactions: $e';
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new transaction
  Future<void> addTransaction(TransactionHistory transaction) async {
    try {
      await repository.insertTransaction(transaction);
      await fetchTransactions(); // refresh list
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      notifyListeners();
    }
  }

  // Update a transaction
  Future<void> updateTransaction(TransactionHistory transaction) async {
    try {
      await repository.updateTransaction(transaction);
      await fetchTransactions(); // refresh list
    } catch (e) {
      _error = 'Failed to update transaction: $e';
      notifyListeners();
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(int id) async {
    try {
      await repository.deleteTransaction(id);
      await fetchTransactions(); // refresh list
    } catch (e) {
      _error = 'Failed to delete transaction: $e';
      notifyListeners();
    }
  }
}
