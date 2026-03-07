// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

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

  Size _screenSize(BuildContext context) => MediaQuery.of(context).size;

  double _screenWidth(BuildContext context) => _screenSize(context).width;

  double _screenHeight(BuildContext context) => _screenSize(context).height;

  bool _isTablet(BuildContext context) => _screenWidth(context) >= 700;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool _useSplitLayout(BuildContext context) {
    final width = _screenWidth(context);
    final height = _screenHeight(context);
    return width >= 850 || (width >= 700 && height <= 600) || _isLandscape(context) && width >= 700;
  }

  double _responsiveScale(BuildContext context) {
    final width = _screenWidth(context);
    if (width < 360) return 0.88;
    if (width < 400) return 0.94;
    if (width < 700) return 1.00;
    if (width < 1000) return 1.10;
    return 1.18;
  }

  double _r(BuildContext context, double value) {
    final scaled = value * _responsiveScale(context);
    final min = value * 0.82;
    final max = value * 1.28;
    return scaled.clamp(min, max);
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

    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final useSplitLayout = _useSplitLayout(context);

    final maxContentWidth = useSplitLayout
        ? 1240.0
        : isTablet
            ? 780.0
            : double.infinity;

    final horizontalPadding = useSplitLayout
        ? (isTablet ? 24.0 : 18.0)
        : isTablet
            ? 18.0
            : isLandscape
                ? 14.0
                : 16.0;

    final verticalPadding = useSplitLayout ? 14.0 : (isLandscape ? 10.0 : 12.0);

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
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding,
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final h = c.maxHeight;
                        final w = c.maxWidth;

                        final gap = useSplitLayout
                            ? (math.min(w, h) * 0.022).clamp(12.0, 18.0)
                            : isLandscape
                                ? (h * 0.022).clamp(8.0, 12.0)
                                : (h * 0.026).clamp(10.0, 16.0);

                        if (useSplitLayout) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 11,
                                child: _buildTilesPanel(
                                  context: context,
                                  gap: gap,
                                ),
                              ),
                              SizedBox(width: gap),
                              Expanded(
                                flex: 13,
                                child: _SalesOnlyGraphCard(
                                  salesPoints: homeState.income7Days,
                                  loading: homeState.isGraphLoading,
                                  error: homeState.graphError,
                                ),
                              ),
                            ],
                          );
                        }

                        final tilesBlock = isTablet
                            ? (isLandscape
                                ? (h * 0.36).clamp(220.0, 300.0)
                                : (h * 0.40).clamp(280.0, 380.0))
                            : (isLandscape
                                ? (h * 0.42).clamp(190.0, 260.0)
                                : (h * 0.34).clamp(220.0, 320.0));

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

  Widget _buildTilesPanel({
    required BuildContext context,
    required double gap,
  }) {
    return Column(
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
    );
  }

  Widget _bigActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(_r(context, 22));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final w = c.maxWidth;
            final isLandscape = _isLandscape(context);
            final isTablet = _isTablet(context);
            final compact = h < 120 || w < 320;

            final iconSize = compact
                ? (h * 0.22).clamp(_r(context, 22), _r(context, 30))
                : isTablet
                    ? (h * 0.24).clamp(_r(context, 28), _r(context, 40))
                    : (h * 0.28).clamp(_r(context, 26), _r(context, 34));

            final iconBox = compact
                ? (h * 0.42).clamp(_r(context, 42), _r(context, 56))
                : isTablet
                    ? (h * 0.56).clamp(_r(context, 56), _r(context, 82))
                    : (h * 0.60).clamp(_r(context, 54), _r(context, 74));

            final titleSize = compact
                ? (h * 0.15).clamp(_r(context, 15), _r(context, 18))
                : isLandscape
                    ? (h * 0.17).clamp(_r(context, 17), _r(context, 22))
                    : (h * 0.18).clamp(_r(context, 18), _r(context, 22));

            final subSize = compact
                ? (h * 0.10).clamp(_r(context, 10.5), _r(context, 12.5))
                : isLandscape
                    ? (h * 0.12).clamp(_r(context, 12), _r(context, 14.5))
                    : (h * 0.13).clamp(_r(context, 12.5), _r(context, 15));

            final vPad = compact
                ? (h * 0.08).clamp(_r(context, 8), _r(context, 12))
                : isLandscape
                    ? (h * 0.10).clamp(_r(context, 10), _r(context, 16))
                    : (h * 0.12).clamp(_r(context, 12), _r(context, 18));

            final accentHeight = compact
                ? (h * 0.35).clamp(_r(context, 32), _r(context, 44))
                : isLandscape
                    ? (h * 0.50).clamp(_r(context, 42), _r(context, 60))
                    : (h * 0.55).clamp(_r(context, 48), _r(context, 64));

            final horizontalPad = compact ? _r(context, 12) : _r(context, 18);
            final gapBetween = compact ? _r(context, 10) : _r(context, 16);

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: vPad,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: _r(context, 18),
                    offset: Offset(0, _r(context, 10)),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: _r(context, compact ? 5 : 6),
                    height: accentHeight,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(width: gapBetween),
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(_r(context, 18)),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(.25),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: gapBetween),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(height: _r(context, compact ? 4 : 6)),
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

  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 700;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  double _responsiveScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.88;
    if (width < 400) return 0.94;
    if (width < 700) return 1.00;
    if (width < 1000) return 1.10;
    return 1.18;
  }

  double _r(BuildContext context, double value) {
    final scaled = value * _responsiveScale(context);
    final min = value * 0.82;
    final max = value * 1.28;
    return scaled.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final compact = h < 220;

        return Container(
          padding: EdgeInsets.fromLTRB(
            _r(context, compact ? 12 : 14),
            _r(context, compact ? 10 : 12),
            _r(context, compact ? 12 : 14),
            _r(context, compact ? 8 : 10),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_r(context, 18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: _r(context, 14),
                offset: Offset(0, _r(context, 10)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Sales (Last 7 Days)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact
                      ? _r(context, 13)
                      : isTablet
                          ? _r(context, 15)
                          : _r(context, 14),
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.78),
                ),
              ),
              SizedBox(height: _r(context, compact ? 6 : 8)),
              Row(
                children: [
                  Container(
                    width: _r(context, 10),
                    height: _r(context, 10),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: _r(context, 6)),
                  Text(
                    'Sales',
                    style: TextStyle(
                      fontSize: compact ? _r(context, 11.5) : _r(context, 12.5),
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _r(context, compact ? 6 : (isLandscape ? 8 : 10))),
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
      },
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
          textAlign: TextAlign.center,
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

    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

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

    final horizontalInterval = ((high - low) / 3).clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (len - 1).toDouble(),
        minY: low,
        maxY: high,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isTablet
                  ? (isLandscape ? 46 : 44)
                  : 40,
              interval: horizontalInterval,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isLandscape ? 22 : 18,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= len) return const SizedBox.shrink();
                final d = sales[i].day;
                return Padding(
                  padding: EdgeInsets.only(top: _r(context, 6)),
                  child: Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: isTablet ? 11.5 : 11,
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
            barWidth: isTablet ? 4.0 : 3.6,
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