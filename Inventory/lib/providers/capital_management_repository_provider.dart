import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/capital_management_repository.dart';
import 'database_provider.dart';

final capitalManagementRepositoryProvider =
    FutureProvider<CapitalManagementRepository>((ref) async {
       final database = await ref.watch(databaseProvider.future);
  return CapitalManagementRepository(database);
});
