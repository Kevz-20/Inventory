import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/account_repository.dart';
import 'database_provider.dart';

final accountRepositoryProvider = FutureProvider<AccountRepository>((
  ref,
) async {
  await ref.watch(databaseProvider.future);
  return AccountRepository();
});
