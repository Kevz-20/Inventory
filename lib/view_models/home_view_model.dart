import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../repositories/capital_management_repository.dart';
import '../repositories/account_repository.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>(
  (ref) => HomeViewModel(ref),
);

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref ref;
  CapitalManagementRepository? _capitalRepo;
  AccountRepository? _accountRepo;
  bool _initialized = false;

  HomeViewModel(this.ref) : super(HomeState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final db = await ref.read(databaseProvider.future);
    _accountRepo = AccountRepository(db);
    _capitalRepo = CapitalManagementRepository(db);
    _initialized = true;
    await fetchHomeData();
  }

  /// Fetch mobile number and cash_on_hand safely
  Future<void> fetchHomeData() async {
    if (!_initialized || _accountRepo == null || _capitalRepo == null) return;

    try {
      final mobile = await _accountRepo!.getMobileNumber();
      final cashList = await _capitalRepo!.getCashOnHandOnly();
      final totalCash = cashList.fold<double>(
        0.0,
        (sum, e) => sum + e.cashOnHand,
      );

      state = state.copyWith(
        mobileNumber: mobile,
        cashOnHand: totalCash,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void onNavTap(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void toggleMoneyVisibility() {
    state = state.copyWith(isMoneyVisible: !state.isMoneyVisible);
  }
}

class HomeState {
  final int selectedIndex;
  final String? mobileNumber;
  final double cashOnHand;
  final String? error;
  final bool isMoneyVisible;

  HomeState({
    required this.selectedIndex,
    this.mobileNumber,
    required this.cashOnHand,
    this.error,
    this.isMoneyVisible = true,
  });

  factory HomeState.initial() =>
      HomeState(selectedIndex: 0, cashOnHand: 0.0, isMoneyVisible: true);

  HomeState copyWith({
    int? selectedIndex,
    String? mobileNumber,
    double? cashOnHand,
    String? error,
    bool? isMoneyVisible,
  }) {
    return HomeState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      cashOnHand: cashOnHand ?? this.cashOnHand,
      error: error ?? this.error,
      isMoneyVisible: isMoneyVisible ?? this.isMoneyVisible,
    );
  }
}
