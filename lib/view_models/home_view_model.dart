import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, int>((ref) {
  return HomeViewModel();
});

class HomeViewModel extends StateNotifier<int> {
  HomeViewModel() : super(0);

  void onNavTap(int index) {
    state = index;
  }
}
