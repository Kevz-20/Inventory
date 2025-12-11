import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_history_repository_provider.dart';
import '../repositories/transaction_history_repository.dart';
import '../models/transaction_history_model.dart';

class TransactionHistoryViewModel
    extends StateNotifier<AsyncValue<List<TransactionHistoryModel>>> {
  final TransactionHistoryRepository repository;

  DateTime? _startDate;
  DateTime? _endDate;
  String _category = 'All';
  bool _isLoading = false;

  TransactionHistoryViewModel({required this.repository})
    : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get category => _category;
  bool get isLoading => _isLoading;
  List<TransactionHistoryModel> get transactions => state.value ?? [];

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadTransactions(startDate: _startDate, endDate: _endDate);
  }

  void setCategory(String category) {
    _category = category;
    loadTransactions(startDate: _startDate, endDate: _endDate);
  }

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    state = AsyncValue.loading();
    try {
      final data = await repository.getAllTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      var transactions = data
          .map((e) => TransactionHistoryModel.fromMap(e))
          .toList();

      // Filter by category if not "All"
      if (_category != 'All') {
        transactions = transactions
            .where((tx) => tx.type == _category)
            .toList();
      }

      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }
}

// Provider for the ViewModel
final transactionHistoryViewModelProvider =
    FutureProvider<TransactionHistoryViewModel>((ref) async {
      final repository = await ref.watch(
        transactionHistoryRepositoryProvider.future,
      );
      return TransactionHistoryViewModel(repository: repository);
    });
