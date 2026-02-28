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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        onTap: () => context.push('/customer_menu'),
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

            // ✅ BOTH LINES GRAPH ONLY (clean, no toggle buttons)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _SalesOnlyGraphCard(
                  salesPoints: homeState.income7Days,
                  loading: homeState.isGraphLoading,
                  error: homeState.graphError,
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
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white, // ✅ solid white = clear

          borderRadius: radius,

          // ✅ clear boundary
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),

          // ✅ clean raised 3D (not soft blur)
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
            // ✅ Accent vertical strip (very clear identity)
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(width: 16),

            // ✅ Icon container with clear border
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withOpacity(.25),
                ),
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

// ========================= GRAPH CARD (CLEAN BOTH) =========================

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

          // ✅ simple legend
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

    // ✅ IMPORTANT: Use TOTAL SALES value (not net)
    // If your model field is NOT "net", change it here:
    // e.g. pts[i].income or pts[i].salesTotal
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
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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