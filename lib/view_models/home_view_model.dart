import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/home_repository.dart';
import '../services/db_service.dart';

/// ✅ Graph mode selector
enum HomeGraphMode { net, income, expense }

/// ------------------------------
/// MODEL FOR GRAPH POINTS
/// ------------------------------
class CashflowPoint {
  final DateTime day;
  final double net; // reused for net/income/expense series values

  const CashflowPoint({required this.day, required this.net});
}

class TopSellingProduct {
  final int productId;
  final String name;
  final String? imagePath;
  final int unitsSold;
  final double totalSales;

  const TopSellingProduct({
    required this.productId,
    required this.name,
    required this.imagePath,
    required this.unitsSold,
    required this.totalSales,
  });
}

/// ------------------------------
/// STATE
/// ------------------------------
class HomeState {
  final double cashOnHand;
  final bool isMoneyVisible;
  final String? mobileNumber;
  final String? error;
  final int selectedIndex;

  // Graph mode + series
  final HomeGraphMode graphMode;

  final List<CashflowPoint> net7Days;     // net = income - expense
  final List<CashflowPoint> income7Days;  // income trend
  final List<CashflowPoint> expense7Days; // expense trend

  final bool isGraphLoading;
  final String? graphError;
  final List<TopSellingProduct> topSellingProducts;
  final bool isTopProductsLoading;
  final String? topProductsError;

  const HomeState({
    this.cashOnHand = 0.0,
    this.isMoneyVisible = true,
    this.mobileNumber,
    this.error,
    this.selectedIndex = 0,
    this.graphMode = HomeGraphMode.net,
    this.net7Days = const [],
    this.income7Days = const [],
    this.expense7Days = const [],
    this.isGraphLoading = false,
    this.graphError,
    this.topSellingProducts = const [],
    this.isTopProductsLoading = false,
    this.topProductsError,
  });

  HomeState copyWith({
    double? cashOnHand,
    bool? isMoneyVisible,
    String? mobileNumber,
    String? error,
    int? selectedIndex,
    HomeGraphMode? graphMode,
    List<CashflowPoint>? net7Days,
    List<CashflowPoint>? income7Days,
    List<CashflowPoint>? expense7Days,
    bool? isGraphLoading,
    String? graphError,
    List<TopSellingProduct>? topSellingProducts,
    bool? isTopProductsLoading,
    String? topProductsError,
  }) {
    return HomeState(
      cashOnHand: cashOnHand ?? this.cashOnHand,
      isMoneyVisible: isMoneyVisible ?? this.isMoneyVisible,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      error: error ?? this.error,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      graphMode: graphMode ?? this.graphMode,
      net7Days: net7Days ?? this.net7Days,
      income7Days: income7Days ?? this.income7Days,
      expense7Days: expense7Days ?? this.expense7Days,
      isGraphLoading: isGraphLoading ?? this.isGraphLoading,
      graphError: graphError,
      topSellingProducts: topSellingProducts ?? this.topSellingProducts,
      isTopProductsLoading: isTopProductsLoading ?? this.isTopProductsLoading,
      topProductsError: topProductsError,
    );
  }
}

/// ------------------------------
/// VIEWMODEL
/// ------------------------------
class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._repo) : super(const HomeState());

  final HomeRepository _repo;

  Future<void> fetchHomeData() async {
    try {
      // ✅ cash + mobile from repository
      final cash = await _repo.getCashOnHand();
      final mobile = await _repo.getMobileNumber();

      state = state.copyWith(
        cashOnHand: cash,
        mobileNumber: mobile ?? "Not set",
        error: null,
      );

      // ✅ graph + top products from repository
      await Future.wait([
        fetchGraph7Days(),
        fetchTopSellingProducts(),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchGraph7Days() async {
    state = state.copyWith(isGraphLoading: true, graphError: null);

    try {
      final result = await _repo.getIncomeExpenseLast7Days();
      final income = result.income;
      final expense = result.expense;

      // ✅ compute net = income - expense
      final net = List.generate(7, (i) {
        final day = income[i].day;
        final value = income[i].net - expense[i].net;
        return CashflowPoint(day: day, net: value);
      });

      state = state.copyWith(
        income7Days: income,
        expense7Days: expense,
        net7Days: net,
        isGraphLoading: false,
        graphError: null,
      );
    } catch (e) {
      state = state.copyWith(
        isGraphLoading: false,
        graphError: e.toString(),
      );
    }
  }

  Future<void> fetchTopSellingProducts() async {
    state = state.copyWith(
      isTopProductsLoading: true,
      topProductsError: null,
    );

    try {
      final topProducts = await _repo.getTopSellingProducts(limit: 5);
      state = state.copyWith(
        topSellingProducts: topProducts,
        isTopProductsLoading: false,
        topProductsError: null,
      );
    } catch (e) {
      state = state.copyWith(
        isTopProductsLoading: false,
        topProductsError: e.toString(),
      );
    }
  }

  void toggleMoneyVisibility() {
    state = state.copyWith(isMoneyVisible: !state.isMoneyVisible);
  }

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void setGraphMode(HomeGraphMode mode) {
    state = state.copyWith(graphMode: mode);
  }
}

/// ------------------------------
/// PROVIDERS
/// ------------------------------

/// ✅ HomeRepository provider (inject DBService)
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(DBService.instance);
});

/// ✅ HomeViewModel provider (inject repository)
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref.read(homeRepositoryProvider));
});
