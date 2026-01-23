import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/capital_management_view_model.dart';
import 'capital_management_repository_provider.dart';

final capitalManagementViewModelProvider =
    ChangeNotifierProvider.autoDispose<CapitalManagementViewModel>((ref) {
      final repo = ref.watch(capitalManagementRepositoryProvider).requireValue;
      return CapitalManagementViewModel(repo);
    });
