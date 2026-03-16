import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/profile_view_model.dart';

final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  final vm = ProfileViewModel(ref);
  vm.init();
  return vm;
});
