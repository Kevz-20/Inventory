import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_history_model.dart';
import '../repositories/transaction_history_repository.dart';

// Represents a single transaction
class TransactionItem {
  final String type;
  final String? description;
  final double? amount;
  final DateTime createdAt;
  final String? paymentType;
  final String? productName;
  final int? quantity;
  final String? receiptImagePath;
  final String? category;

  // NEW FIELD
  final String? recordedBy;

  TransactionItem({
    required this.type,
    this.description,
    this.amount,
    required this.createdAt,
    this.paymentType,
    this.productName,
    this.quantity,
    this.receiptImagePath,
    this.category,
    this.recordedBy, // <-- add here
  });

  factory TransactionItem.fromMap(
    Map<String, dynamic> map, {
    String fallbackType = '',
    bool isCapital = false,
  }) {
    double value;
    String? paymentType;

    String? receiptImagePath = map['receipt'] ??
        map['receipt_image_path'] ??
        map['resibo'] ??
        map['image_path'];

    if (isCapital) {
      value = (map['capital'] as num?)?.toDouble() ?? 0.0;
      if (value > 0) paymentType = 'Deposit';
    } else if (map.containsKey('bank_cash')) {
      value = (map['bank_cash'] as num?)?.toDouble() ?? 0.0;
      if (value > 0) paymentType = 'Withdraw';
    } else {
      value = (map['amount'] as num?)?.toDouble() ?? 0.0;
      paymentType = 'Cash'; // default cash
    }

    // Build recordedBy from map
    final createdByFirst = map['created_by_first_name'] ?? '';
    final createdByMiddle = map['created_by_middle_name'] ?? '';
    final createdByLast = map['created_by_last_name'] ?? '';
    final recordedBy =
        [createdByFirst, createdByMiddle, createdByLast].where((s) => s.isNotEmpty).join(' ');

    return TransactionItem(
      type: map['type'] ?? fallbackType,
      description: (map['description'] ?? map['remarks'] ?? map['note'])?.toString(),
      amount: value,
      createdAt: _parseCreatedAt(map),
      paymentType: paymentType,
      productName: map['product_name'],
      quantity: (map['quantity'] as num?)?.toInt(),
      receiptImagePath: receiptImagePath,
      category: map['category'],
      recordedBy: recordedBy.isNotEmpty ? recordedBy : null, // <-- set here
    );
  }

  static DateTime _parseCreatedAt(Map<String, dynamic> map) {
    final rawCandidates = [
      map['created_at'],
      map['paid_at'],
      map['date'],
      map['credit_date'],
    ];

    for (final raw in rawCandidates) {
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }

    // Oldest fallback so invalid timestamps never jump to the top.
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}


// Transaction section (grouped by date)
class TransactionSection {
  final String title;
  final List<TransactionItem> items;

  TransactionSection({
    required this.title,
    required this.items,
  });
}

// Transaction categories
enum TransactionCategory {
  all,
  expenses,
  sales,
  capitalManagement,
  customerPayment,
  ownerPayment,
}

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
      case TransactionCategory.customerPayment:
        return 'Customer Payment';
      case TransactionCategory.ownerPayment:
        return 'Owner Payment';
    }
  }
}

// ViewModel
class TransactionHistoryViewModel extends ChangeNotifier {
  final TransactionHistoryRepository _repository =
      TransactionHistoryRepository();

  TransactionHistoryModel? _fullHistory;
  TransactionHistoryModel _filteredHistory = TransactionHistoryModel(
    expenses: [],
    salesCash: [],
    salesCredit: [],
    capitalManagement: [],
    customerPayments: [],
    utangPayments: [],
    ownerPayments: [],
  );

  bool _isLoading = false;
  String? _error;
  TransactionCategory selectedCategory = TransactionCategory.all;
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination
  static const int pageSize = 20;
  int _currentPage = 0;

  // Cache per category
  final Map<TransactionCategory, List<TransactionItem>> _cache = {};

  // ---------------- Getters ----------------
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  String get emptyStateMessage {
    switch (selectedCategory) {
      case TransactionCategory.expenses:
        return 'No expense transactions yet';
      case TransactionCategory.sales:
        return 'No sales transactions yet';
      case TransactionCategory.capitalManagement:
        return 'No capital transactions yet';
      case TransactionCategory.customerPayment:
        return 'No customer payments yet';
      case TransactionCategory.ownerPayment:
        return 'No owner payments yet';
      case TransactionCategory.all:
        return 'No transactions found';
    }
  }

  List<TransactionItem> get pagedTransactions {
    final allItems = transactions.toList();
    final start = _currentPage * pageSize;
    if (start >= allItems.length) return [];
    final end = (start + pageSize) > allItems.length
        ? allItems.length
        : start + pageSize;
    return allItems.sublist(start, end);
  }

  int get transactionCount => pagedTransactions.length;

  TransactionItem transactionAt(int index) => pagedTransactions[index];

  List<TransactionItem> _sortNewestFirst(Iterable<TransactionItem> items) {
    final sorted = items.toList();
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  // ---------------- Computed transactions with caching ----------------
  Iterable<TransactionItem> get transactions {
    if (_cache.containsKey(selectedCategory)) return _cache[selectedCategory]!;

    Iterable<TransactionItem> items() sync* {
      for (var map in _filteredHistory.expenses) {
        yield TransactionItem.fromMap(map, fallbackType: 'Gasto');
      }
      for (var map in _filteredHistory.salesCash) {
        yield TransactionItem.fromMap(map, fallbackType: 'Halin');
      }
      for (var map in _filteredHistory.salesCredit) {
        yield TransactionItem.fromMap(map, fallbackType: 'Halin');
      }
      for (var map in _filteredHistory.capitalManagement) {
        yield TransactionItem.fromMap(map,
            fallbackType: 'Capital', isCapital: true);
      }
      for (var map in _filteredHistory.customerPayments) {
        yield TransactionItem.fromMap(
          map,
          fallbackType: 'Customer Payment',
        );
      }
      for (var map in _filteredHistory.utangPayments) {
        yield TransactionItem.fromMap(map, fallbackType: 'Owner Payment');
      }
      for (var map in _filteredHistory.ownerPayments) {
        yield TransactionItem.fromMap(map, fallbackType: 'Owner Payment');
      }
    }

    Iterable<TransactionItem> result;
    if (selectedCategory != TransactionCategory.all) {
      if (selectedCategory == TransactionCategory.sales) {
        // Show only cash sales under Halin; credit/utang sales are excluded.
        result = _filteredHistory.salesCash.map(
          (map) => TransactionItem.fromMap(map, fallbackType: 'Halin'),
        );
      } else if (selectedCategory == TransactionCategory.customerPayment) {
        result = items().where((tx) => tx.type == 'Customer Payment');
      } else if (selectedCategory == TransactionCategory.ownerPayment) {
        result =
            items().where((tx) => tx.type == 'Owner Payment' || tx.type == 'Downpayment');
      } else {
        final type = selectedCategory == TransactionCategory.expenses
            ? 'Gasto'
            : selectedCategory == TransactionCategory.capitalManagement
                    ? 'Capital'
                    : '';
        result = items().where((tx) => tx.type == type);
      }
    } else {
      result = items().toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _cache[selectedCategory] = _sortNewestFirst(result);
    return _cache[selectedCategory]!;
  }

  // ---------------- Constructor ----------------
  TransactionHistoryViewModel() {
    _loadFullHistory();
  }

  // ---------------- Load full history ----------------
  Future<void> _loadFullHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _fullHistory = await _repository.loadHistory();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------- Filters ----------------
  void _applyFilters() {
    if (_fullHistory == null) return; // <-- prevent crash if not loaded yet

    _filteredHistory = TransactionHistoryModel(
      expenses: _filterByDate(_fullHistory!.expenses),
      salesCash: _filterByDate(_fullHistory!.salesCash),
      salesCredit: _filterByDate(_fullHistory!.salesCredit),
      capitalManagement: _filterByDate(_fullHistory!.capitalManagement),
      customerPayments: _filterByDate(_fullHistory!.customerPayments),
      utangPayments: _filterByDate(_fullHistory!.utangPayments),
      ownerPayments: _filterByDate(_fullHistory!.ownerPayments),
    );
    _cache.clear();
    _currentPage = 0;
    notifyListeners();
  }

  List<Map<String, dynamic>> _filterByDate(List<Map<String, dynamic>> data) {
    if (_startDate == null && _endDate == null) return data;

    return data.where((item) {
      final createdAt = TransactionItem._parseCreatedAt(item);
      if (_startDate != null && createdAt.isBefore(_startDate!)) return false;
      if (_endDate != null && createdAt.isAfter(_endDate!)) return false;
      return true;
    }).toList();
  }

  // ---------------- Sections (grouped by day) ----------------
  List<TransactionSection> get sections {
    final Map<String, List<TransactionItem>> grouped = {};

    for (final tx in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    final now = DateTime.now();

    return grouped.entries.map((entry) {
      final date = DateTime.parse(entry.key);

      final title = DateUtils.isSameDay(date, now)
          ? 'Today'
          : DateFormat('MMMM d, yyyy').format(date);

      // Sort items by time descending within the section
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return TransactionSection(
        title: title,
        items: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.items.first.createdAt.compareTo(a.items.first.createdAt));
  }

  // ---------------- Setters ----------------
  void setSelectedCategory(TransactionCategory category) {
    selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    _applyFilters();
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    _applyFilters();
    notifyListeners();
  }

  // ---------------- Pagination ----------------
  void loadNextPage() {
    final totalPages = (transactions.length / pageSize).ceil();
    if (_currentPage + 1 < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void resetPagination() {
    _currentPage = 0;
    notifyListeners();
  }
}
