import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';
import '../repositories/transaction_history_repository.dart';

// Provider for DBService singleton
final dbServiceProvider = Provider<DBService>((ref) {
  return DBService.instance;
});

// FutureProvider for TransactionHistoryRepository
final transactionHistoryRepositoryProvider =
    FutureProvider<TransactionHistoryRepository>((ref) async {
      final dbService = ref.watch(dbServiceProvider);
      return TransactionHistoryRepository(dbService: dbService);
    });

// FutureProvider to get all transactions
final allTransactionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, DateTime?>>((
      ref,
      dateRange,
    ) async {
      final repository = await ref.watch(
        transactionHistoryRepositoryProvider.future,
      );
      return repository.getAllTransactions(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );
    });
