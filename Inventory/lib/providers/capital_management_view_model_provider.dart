import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/capital_management_view_model.dart';
import 'capital_management_repository_provider.dart';

final capitalManagementViewModelProvider =
    ChangeNotifierProvider<CapitalManagementViewModel>((ref) {
      final repoAsync = ref.watch(capitalManagementRepositoryProvider);

      // If repository isn't loaded yet, return a temporary ViewModel with null repository
      return CapitalManagementViewModel(repository: repoAsync.asData?.value);
    });
