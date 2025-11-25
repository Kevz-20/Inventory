import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/profile_view_model.dart';
import 'account_repository_provider.dart';
import 'current_mobile_number_provider.dart';
import 'database_provider.dart';

final profileViewModelProvider = FutureProvider<ProfileViewModel>((ref) async {
  final mobile = ref.watch(currentMobileNumberProvider);
  if (mobile == null) {
    debugPrint('⭐ [ProfileViewModelProvider] No mobile yet');
    throw Exception('No mobile number available');
  }

  debugPrint(
    '⭐ [ProfileViewModelProvider] Starting initialization for $mobile',
  );

  await ref.watch(databaseProvider.future);
  debugPrint('⭐ [ProfileViewModelProvider] Database ready');

  final repo = await ref.watch(accountRepositoryProvider.future);
  debugPrint('⭐ [ProfileViewModelProvider] AccountRepository ready');

  final vm = ProfileViewModel(ref, repo);
  await vm.loadAccount();
  debugPrint(
    '⭐ [ProfileViewModelProvider] Account loaded: ${vm.account?.mobileNumber}',
  );

  return vm;
});
