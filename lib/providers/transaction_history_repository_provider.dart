import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/transaction_history_repository.dart';
import 'account_repository_provider.dart'; // make sure to import your account repo provider

final transactionHistoryRepoProvider =
    FutureProvider<TransactionHistoryRepository>((ref) async {
      // Wait for the AccountRepository to be ready
      final accountRepo = await ref.watch(accountRepositoryProvider.future);

      // Get the database instance from the accountRepo
      final db = accountRepo.database;

      return TransactionHistoryRepository(
        database: db,
        accountRepo: accountRepo,
      );
    });
