// lib/providers/account_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/account_repository.dart';
import 'database_provider.dart';

/// Provider for the AccountRepository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// FutureProvider to get the currently logged-in account
final currentAccountProvider = FutureProvider.autoDispose((ref) async {
  // Ensure the database is initialized first
  await ref.watch(databaseProvider.future);

  final accountRepo = ref.read(accountRepositoryProvider);

  try {
    final account = await accountRepo.getAccountDetails();
    return account; // returns Account object
  } catch (e) {
    // You can handle no account found or other errors
    return null; // null if no account exists
  }
});
