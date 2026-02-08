import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/database_provider.dart';
import '../repositories/capital_management_repository.dart';
import '../repositories/account_repository.dart';

/// Provider for HomeViewModel
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>(
  (ref) => HomeViewModel(ref),
);

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref ref;
  CapitalManagementRepository? _capitalRepo;
  AccountRepository? _accountRepo;
  bool _initialized = false;

  static const _prefsKeyMoneyVisible = 'isMoneyVisible';

  HomeViewModel(this.ref) : super(HomeState.initial()) {
    _init();
  }

  /// Initialize repositories and load initial state
  Future<void> _init() async {
    final db = await ref.read(databaseProvider.future);
    _accountRepo = AccountRepository();
    _capitalRepo = CapitalManagementRepository(db);

    // Load saved money visibility from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedVisibility = prefs.getBool(_prefsKeyMoneyVisible) ?? true;
    state = state.copyWith(isMoneyVisible: savedVisibility);

    _initialized = true;
    await fetchHomeData();
  }

  /// Fetch mobile number and total cash on hand
  Future<void> fetchHomeData() async {
    if (!_initialized || _accountRepo == null || _capitalRepo == null) return;

    try {
      final mobile = await _accountRepo!.getMobileNumber();

      // Use updated repository method
      final totalCash = await _capitalRepo!.getTotalCashOnHand();

      state = state.copyWith(
        mobileNumber: mobile,
        cashOnHand: totalCash,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Handle bottom navigation tap
  void onNavTap(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  /// Toggle visibility of money
  Future<void> toggleMoneyVisibility() async {
    final newVisibility = !state.isMoneyVisible;
    state = state.copyWith(isMoneyVisible: newVisibility);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyMoneyVisible, newVisibility);
  }
}

/// Home state class
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
