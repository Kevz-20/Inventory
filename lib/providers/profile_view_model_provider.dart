import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/profile_view_model.dart';
import 'account_repository_provider.dart';

final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  final accountRepo = ref.watch(accountRepositoryProvider);
  return ProfileViewModel(accountRepo);
});
