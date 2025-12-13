import 'package:flutter/material.dart';
import '../models/transaction_history_model.dart';
import '../repositories/transaction_history_repository.dart';

// Model for single transaction
class TransactionItem {
  final String type;
  final String? description;
  final double? amount;
  final DateTime createdAt;

  TransactionItem({
    required this.type,
    this.description,
    this.amount,
    required this.createdAt,
  });

  // Convert map to TransactionItem
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      type: map['type'] ?? '',
      description: map['description'],
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : 0.0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// Transaction categories
enum TransactionCategory { all, expenses, sales, capitalManagement }

// Extension to get display name for categories
extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.all:
        return 'Tanan';
      case TransactionCategory.expenses:
        return 'Gasto';
      case TransactionCategory.sales:
        return 'Halin';
      case TransactionCategory.capitalManagement:
        return 'Capital';
    }
  }
}

// Extension to convert raw history maps into TransactionItem list
extension TransactionHistoryViewModelExtension on TransactionHistoryViewModel {
  List<TransactionItem> get transactions {
    List<Map<String, dynamic>> rawList;

    switch (selectedCategory) {
      case TransactionCategory.expenses:
        rawList = _history.expenses;
        break;

      case TransactionCategory.sales:
        rawList = [..._history.salesCash, ..._history.salesCredit];
        break;

      case TransactionCategory.capitalManagement:
        rawList = _history.capitalManagement;
        break;

      case TransactionCategory.all:
        rawList = [
          ..._history.expenses,
          ..._history.salesCash,
          ..._history.salesCredit,
          ..._history.capitalManagement,
        ];
        break;
    }

    return rawList.map(TransactionItem.fromMap).toList();
  }
}

// ViewModel for managing transaction history
class TransactionHistoryViewModel extends ChangeNotifier {
  final TransactionHistoryRepository _repository =
      TransactionHistoryRepository();

  TransactionHistoryModel _history = TransactionHistoryModel(
    expenses: [],
    salesCash: [],
    salesCredit: [],
    capitalManagement: [],
  );

  bool _isLoading = false;
  String? _error;

  TransactionCategory selectedCategory = TransactionCategory.all;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 20;

  // Getters for state
  TransactionHistoryModel? get history => _history;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Load transaction history with optional filters
  Future<void> loadHistory({
    TransactionCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final currentCategory = category ?? selectedCategory;
    final currentStart = startDate ?? _startDate;
    final currentEnd = endDate ?? _endDate;

    try {
      final fullHistory = await _repository.loadHistory();

      // Filter transactions by date range
      List<Map<String, dynamic>> filterByDate(List<Map<String, dynamic>> data) {
        if (currentStart == null && currentEnd == null) return data;
        return data.where((item) {
          final createdAt = DateTime.tryParse(item['created_at'] ?? '');
          if (createdAt == null) return false;
          if (currentStart != null && createdAt.isBefore(currentStart)) {
            return false;
          }
          if (currentEnd != null && createdAt.isAfter(currentEnd)) return false;
          return true;
        }).toList();
      }

      // Apply category filter and date filter
      _history = TransactionHistoryModel(
        expenses:
            currentCategory == TransactionCategory.expenses ||
                currentCategory == TransactionCategory.all
            ? filterByDate(fullHistory.expenses)
            : [],

        salesCash:
            currentCategory == TransactionCategory.sales ||
                currentCategory == TransactionCategory.all
            ? filterByDate(fullHistory.salesCash)
            : [],

        salesCredit:
            currentCategory == TransactionCategory.sales ||
                currentCategory == TransactionCategory.all
            ? filterByDate(fullHistory.salesCredit)
            : [],

        capitalManagement:
            currentCategory == TransactionCategory.capitalManagement ||
                currentCategory == TransactionCategory.all
            ? filterByDate(fullHistory.capitalManagement)
            : [],
      );
    } catch (e) {
      _error = e.toString();
      _history;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load next page for selected category
  Future<void> loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final accountId = await _repository.getAccountId();
      final offset = _page * _pageSize;
      List<Map<String, dynamic>> newData = [];

      switch (selectedCategory) {
        // Expenses
        case TransactionCategory.expenses:
          newData = await _repository.getTransactions(
            'expenses',
            accountId,
            limit: _pageSize,
            offset: offset,
          );
          _history = TransactionHistoryModel(
            expenses: [..._history.expenses, ...newData],
            salesCash: _history.salesCash,
            salesCredit: _history.salesCredit,
            capitalManagement: _history.capitalManagement,
          );
          break;

        // Sales
        case TransactionCategory.sales:
          final cashData = await _repository.getTransactions(
            'sales_cash',
            accountId,
            limit: _pageSize,
            offset: offset,
          );

          final creditData = await _repository.getTransactions(
            'sales_credit',
            accountId,
            limit: _pageSize,
            offset: offset,
          );

          _history = TransactionHistoryModel(
            expenses: _history.expenses,
            salesCash: [..._history.salesCash, ...cashData],
            salesCredit: [..._history.salesCredit, ...creditData],
            capitalManagement: _history.capitalManagement,
          );

          _hasMore =
              cashData.length == _pageSize || creditData.length == _pageSize;

          if (_hasMore) _page++;
          break;

        // Capital Management
        case TransactionCategory.capitalManagement:
          newData = await _repository.getTransactions(
            'capital_management',
            accountId,
            limit: _pageSize,
            offset: offset,
          );
          _history = TransactionHistoryModel(
            expenses: _history.expenses,
            salesCash: _history.salesCash,
            salesCredit: _history.salesCredit,
            capitalManagement: [..._history.capitalManagement, ...newData],
          );
          break;

        // All
        case TransactionCategory.all:
          final expensesData = await _repository.getTransactions(
            'expenses',
            accountId,
            limit: _pageSize,
            offset: offset,
          );
          final salesCashData = await _repository.getTransactions(
            'sales_cash',
            accountId,
            limit: _pageSize,
            offset: offset,
          );
          final salesCreditData = await _repository.getTransactions(
            'sales_credit',
            accountId,
            limit: _pageSize,
            offset: offset,
          );
          final capitalData = await _repository.getTransactions(
            'capital_management',
            accountId,
            limit: _pageSize,
            offset: offset,
          );

          _history = TransactionHistoryModel(
            expenses: [..._history.expenses, ...expensesData],
            salesCash: [..._history.salesCash, ...salesCashData],
            salesCredit: [..._history.salesCredit, ...salesCreditData],
            capitalManagement: [..._history.capitalManagement, ...capitalData],
          );

          _hasMore = [
            expensesData.length,
            salesCashData.length,
            salesCreditData.length,
            capitalData.length,
          ].any((len) => len == _pageSize);

          if (_hasMore) _page++;
          break;
      }

      _hasMore = newData.length == _pageSize;
      if (_hasMore) _page++;
    } catch (e) {
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Reset pagination
  void resetPagination() {
    _page = 0;
    _hasMore = true;
    _history = TransactionHistoryModel(
      expenses: [],
      salesCash: [],
      salesCredit: [],
      capitalManagement: [],
    );
  }

  // Update selected category
  void setSelectedCategory(TransactionCategory category) {
    selectedCategory = category;
    resetPagination();
    loadNextPage();
  }

  // Update start date
  void setStartDate(DateTime? date) {
    _startDate = date;
    loadHistory();
  }

  // Update end date
  void setEndDate(DateTime? date) {
    _endDate = date;
    loadHistory();
  }
}
