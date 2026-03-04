// ignore_for_file: deprecated_member_use

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

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700;

    // ✅ a bit wider on tablet so it doesn't look too narrow
    final maxContentWidth = isTablet ? 760.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            HeroHeader(
              title: "Home",
              balance: homeState.isMoneyVisible ? balanceText : "₱ •••••",
              mobileNumber: mobileText,
              centerTitle: true,
              showBack: false,
              showLogo: true,
              onBellTap: () => context.push('/notifications'),
              onEyeTap: () => ref
                  .read(homeViewModelProvider.notifier)
                  .toggleMoneyVisibility(),
            ),

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final h = c.maxHeight;

                        // ✅ Make the tiles area bigger on tablet so it feels "filled"
                        // Negosyo feels full because ACTIONS grid takes lots of height.
                        final tilesBlock = isTablet
                            ? (h * 0.40).clamp(280.0, 380.0)
                            : (h * 0.34).clamp(220.0, 320.0);

                        final gap = (h * 0.03).clamp(10.0, 16.0);

                        return Column(
                          children: [
                            SizedBox(
                              height: tilesBlock,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _bigActionTile(
                                      label: "CUSTOMER",
                                      subtitle: "Manage customers",
                                      icon: Icons.people_alt_outlined,
                                      onTap: () => context.push('/customer_menu'),
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  Expanded(
                                    child: _bigActionTile(
                                      label: "NEGOSYO",
                                      subtitle: "Store & inventory",
                                      icon: Icons.storefront_outlined,
                                      onTap: () => context.push('/negosyo_menu'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: gap),

                            // ✅ Graph fills remaining space
                            Expanded(
                              child: _SalesOnlyGraphCard(
                                salesPoints: homeState.income7Days,
                                loading: homeState.isGraphLoading,
                                error: homeState.graphError,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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
    final radius = BorderRadius.circular(22);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;

            final iconSize = (h * 0.28).clamp(26.0, 34.0);
            final iconBox = (h * 0.60).clamp(54.0, 74.0);

            final titleSize = (h * 0.18).clamp(18.0, 22.0);
            final subSize = (h * 0.13).clamp(12.5, 15.0);

            // ✅ Add vertical padding that adapts (so tile doesn't feel "empty")
            final vPad = (h * 0.12).clamp(12.0, 18.0);

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: vPad),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: (h * 0.55).clamp(48.0, 64.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withOpacity(.25)),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ========================= GRAPH CARD (SALES ONLY) =========================

class _SalesOnlyGraphCard extends StatelessWidget {
  final List<CashflowPoint> salesPoints;
  final bool loading;
  final String? error;

  const _SalesOnlyGraphCard({
    required this.salesPoints,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
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
            'Total Sales (Last 7 Days)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.78),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Sales',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _buildChart(
              context: context,
              sales: salesPoints,
              loading: loading,
              error: error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart({
    required BuildContext context,
    required List<CashflowPoint> sales,
    required bool loading,
    required String? error,
  }) {
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

    if (sales.isEmpty) {
      return Center(
        child: Text(
          'No sales yet.',
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final len = sales.length;

    final spots = <FlSpot>[];
    for (int i = 0; i < len; i++) {
      spots.add(FlSpot(i.toDouble(), sales[i].net));
    }

    final values = sales.map((e) => e.net).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);

    final pad = (maxY - minY).abs() * 0.2;
    final low = minY - (pad == 0 ? 10 : pad);
    final high = maxY + (pad == 0 ? 10 : pad);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (len - 1).toDouble(),
        minY: low,
        maxY: high,

        // ✅ Make the chart look "not empty" (like negosyo page feels filled)
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((high - low) / 3).clamp(1.0, double.infinity),
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),

        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          // ✅ show left labels a bit so chart feels real
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: ((high - low) / 3).clamp(1.0, double.infinity),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.35),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= len) return const SizedBox.shrink();
                final d = sales[i].day;
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

        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                return LineTooltipItem(
                  'Sales: ₱${s.y.toStringAsFixed(2)}',
                  const TextStyle(fontWeight: FontWeight.w900),
                );
              }).toList();
            },
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3.6,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }
}