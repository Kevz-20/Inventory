import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/transaction_history_repository.dart';
import '../repositories/expense_repository.dart';
import 'account_repository_provider.dart';
import 'database_provider.dart';

final transactionHistoryRepoProvider =
    FutureProvider<TransactionHistoryRepository>((ref) async {
      // Wait for the AccountRepository to be ready
      final accountRepo = await ref.watch(accountRepositoryProvider.future);

      // Wait for the ExpenseRepository to be ready
      final expenseRepo = await ref.watch(expenseRepositoryProvider.future);

      // Get the database instance from your Database provider
      final db = await ref.watch(databaseProvider.future);

      return TransactionHistoryRepository(
        database: db,
        accountRepo: accountRepo,
        expenseRepo: expenseRepo, // pass the expenseRepo here
      );
    });
