import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/account_repository.dart';
import 'database_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  // Use the database synchronously if already initialized
  final db = ref.watch(databaseProvider).maybeWhen(
        data: (db) => db,
        orElse: () => throw Exception('Database not ready'),
      );

  return AccountRepository(db as dynamic);
});
