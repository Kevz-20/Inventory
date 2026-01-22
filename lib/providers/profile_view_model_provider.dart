import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/profile_view_model.dart';
import 'account_repository_provider.dart';
import 'current_mobile_number_provider.dart';

final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  final mobile = ref.watch(currentMobileNumberProvider);

  if (mobile == null) {
    return ProfileViewModel(
      ref,
      ref.read(accountRepositoryProvider).requireValue,
    );
  }

  final repo = ref.read(accountRepositoryProvider).requireValue;
  final vm = ProfileViewModel(ref, repo);

  vm.loadAccount();

  return vm;
});
