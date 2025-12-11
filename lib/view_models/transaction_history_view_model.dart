import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_history_repository_provider.dart';
import '../repositories/transaction_history_repository.dart';
import '../models/transaction_history_model.dart';

// StateNotifier to hold transaction history state
class TransactionHistoryViewModel
    extends StateNotifier<AsyncValue<List<TransactionHistoryModel>>> {
  final TransactionHistoryRepository repository;

  TransactionHistoryViewModel({required this.repository})
    : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      state = const AsyncValue.loading();
      final data = await repository.getAllTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      final transactions = data
          .map((e) => TransactionHistoryModel.fromMap(e))
          .toList();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider for the ViewModel
final transactionHistoryViewModelProvider =
    StateNotifierProvider<
      TransactionHistoryViewModel,
      AsyncValue<List<TransactionHistoryModel>>
    >((ref) {
      final repository = ref.watch(transactionHistoryRepositoryProvider.future);
      return TransactionHistoryViewModel(
        repository: repository as TransactionHistoryRepository,
      );
    });
