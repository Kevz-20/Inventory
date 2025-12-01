import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/capital_management_view_model.dart';
import 'capital_management_repository_provider.dart';

final capitalManagementViewModelProvider =
    FutureProvider<CapitalManagementViewModel>((ref) async {
      final repository = await ref.watch(
        capitalManagementRepositoryProvider.future,
      );
      return CapitalManagementViewModel(repository);
    });
