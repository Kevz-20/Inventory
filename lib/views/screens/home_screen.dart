import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/nav_bar.dart';
import '../../app_router.dart';
import '../widgets/hero_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).fetchHomeData();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    ref.read(homeViewModelProvider.notifier).fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);

    final pesoFormatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱ ',
      decimalDigits: 2,
    );

    final balanceText = pesoFormatter.format(homeState.cashOnHand);
    final mobileText = homeState.mobileNumber ?? "Not set";

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ UPDATED: use reusable HeroHeader
            HeroHeader(
              title: "Home",
              balance: homeState.isMoneyVisible ? balanceText : "₱ •••••",
              mobileNumber: mobileText,

              // ✅ Home title should stay LEFT
              centerTitle: true,

              // ✅ No back arrow on Home
              showBack: false,

              onBellTap: () {
                // TODO: context.push('/notifications');
              },

              onEyeTap: () => ref
                  .read(homeViewModelProvider.notifier)
                  .toggleMoneyVisibility(),
            ),

            const SizedBox(height: 14),

            // ✅ CUSTOMER & NEGOSYO AT THE TOP
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      _bigActionTile(
                        label: "CUSTOMER",
                        subtitle: "Manage customers",
                        icon: Icons.people_alt_outlined,
                        onTap: () => context.go('/customer_menu'),
                      ),
                      const SizedBox(height: 18),
                      _bigActionTile(
                        label: "NEGOSYO",
                        subtitle: "Store & inventory",
                        icon: Icons.storefront_outlined,
                        onTap: () => context.push('/negosyo_menu'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ✅ STRETCHED GRAPH AT BOTTOM
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _FinanceGraphCard(
                  mode: homeState.graphMode,
                  netPoints: homeState.net7Days,
                  incomePoints: homeState.income7Days,
                  expensePoints: homeState.expense7Days,
                  loading: homeState.isGraphLoading,
                  error: homeState.graphError,
                  onModeChanged: (m) =>
                      ref.read(homeViewModelProvider.notifier).setGraphMode(m),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: homeState.selectedIndex),
    );
  }

  Widget _bigActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Graph card with mode toggle (NET / INCOME / EXPENSE)
/// - NOT clickable (no InkWell)
/// - No chevron/right arrow
/// - Only pills are tappable
class _FinanceGraphCard extends StatelessWidget {
  final HomeGraphMode mode;
  final List<CashflowPoint> netPoints;
  final List<CashflowPoint> incomePoints;
  final List<CashflowPoint> expensePoints;

  final bool loading;
  final String? error;
  final ValueChanged<HomeGraphMode> onModeChanged;

  const _FinanceGraphCard({
    required this.mode,
    required this.netPoints,
    required this.incomePoints,
    required this.expensePoints,
    required this.loading,
    required this.error,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String title;
    if (mode == HomeGraphMode.net) {
      title = 'Net (Income - Expense)';
    } else if (mode == HomeGraphMode.income) {
      title = 'Income (Last 7 Days)';
    } else {
      title = 'Expenses (Last 7 Days)';
    }

    final List<CashflowPoint> points;
    if (mode == HomeGraphMode.net) {
      points = netPoints;
    } else if (mode == HomeGraphMode.income) {
      points = incomePoints;
    } else {
      points = expensePoints;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.78),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _ModePills(mode: mode, onChanged: onModeChanged),
          const SizedBox(height: 10),
          Expanded(child: _buildChart(points)),
        ],
      ),
    );
  }

  Widget _buildChart(List<CashflowPoint> points) {
    if (loading) {
      return const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          'Unable to load graph',
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (points.isEmpty) {
      return Center(
        child: Text(
          'No data yet.',
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final minY = points.map((e) => e.net).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((e) => e.net).reduce((a, b) => a > b ? a : b);

    final pad = (maxY - minY).abs() * 0.2;
    final low = minY - (pad == 0 ? 10 : pad);
    final high = maxY + (pad == 0 ? 10 : pad);

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].net));
    }

    Color lineColor;
    if (mode == HomeGraphMode.expense) {
      lineColor = AppColors.error;
    } else if (mode == HomeGraphMode.income) {
      lineColor = AppColors.primary;
    } else {
      final mostlyNegative = points.where((p) => p.net < 0).length > 3;
      lineColor = mostlyNegative ? AppColors.error : AppColors.primary;
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: low,
        maxY: high,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final d = points[i].day;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.45),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.14),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ModePills extends StatelessWidget {
  final HomeGraphMode mode;
  final ValueChanged<HomeGraphMode> onChanged;

  const _ModePills({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _pill('NET', HomeGraphMode.net)),
          Expanded(child: _pill('INCOME', HomeGraphMode.income)),
          Expanded(child: _pill('EXPENSE', HomeGraphMode.expense)),
        ],
      ),
    );
  }

  Widget _pill(String label, HomeGraphMode value) {
    final selected = mode == value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: selected
                  ? AppColors.primary
                  : Colors.black.withOpacity(0.55),
            ),
          ),
        ),
      ),
    );
  }
}