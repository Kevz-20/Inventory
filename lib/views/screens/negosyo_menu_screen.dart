// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_router.dart';
import '../../core/app_colors.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/hero_header.dart';
import '../widgets/nav_bar.dart';

class NegosyoMenuScreen extends ConsumerStatefulWidget {
  const NegosyoMenuScreen({super.key});

  @override
  ConsumerState<NegosyoMenuScreen> createState() => _NegosyoMenuScreenState();
}

class _NegosyoMenuScreenState extends ConsumerState<NegosyoMenuScreen>
    with RouteAware {
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

  double _screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

  double _screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  bool _isTablet(BuildContext context) => _screenWidth(context) >= 700;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool _useSplitLayout(BuildContext context) {
    final width = _screenWidth(context);
    final height = _screenHeight(context);

    return width >= 850 ||
        (width >= 700 && height <= 700) ||
        (_isLandscape(context) && width >= 600);
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
            ? 820.0
            : double.infinity;

    final horizontalPadding = useSplitLayout
        ? (isTablet ? 24.0 : 16.0)
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
              title: "Negosyo",
              balance: homeState.isMoneyVisible ? balanceText : "₱ •••••",
              mobileNumber: mobileText,
              isBalanceVisible: homeState.isMoneyVisible,
              centerTitle: true,
              showBack: true,
              onBackTap: () => context.go('/home'),
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
                            ? (math.min(w, h) * 0.020).clamp(12.0, 18.0)
                            : isLandscape
                                ? (h * 0.018).clamp(8.0, 12.0)
                                : (h * 0.022).clamp(10.0, 16.0);

                        if (useSplitLayout) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 13,
                                child: _buildActionsPanel(
                                  gap: gap,
                                ),
                              ),
                              SizedBox(width: gap),
                              Expanded(
                                flex: 10,
                                child: _buildReportsPanel(),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _dividerTitle("ACTIONS"),
                            SizedBox(height: gap),
                            Expanded(
                              flex: 7,
                              child: _buildActionsGrid(gap: gap),
                            ),
                            SizedBox(height: gap),
                            _dividerTitle("REPORTS"),
                            SizedBox(height: gap),
                            Expanded(
                              flex: 3,
                              child: _reportsCard(
                                title: "REPORTS",
                                subtitle: "Income, Balance Sheet, Cash Flow",
                                icon: Icons.assessment_outlined,
                                onTap: () => context.push('/reports'),
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: homeState.selectedIndex,
        noHighlight: true,
      ),
    );
  }

  Widget _buildActionsPanel({required double gap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dividerTitle("ACTIONS"),
        SizedBox(height: gap),
        Expanded(
          child: _buildActionsGrid(gap: gap),
        ),
      ],
    );
  }

  Widget _buildReportsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dividerTitle("REPORTS"),
        SizedBox(height: _r(context, 14)),
        Expanded(
          child: _reportsCard(
            title: "REPORTS",
            subtitle: "Income, Balance Sheet, Cash Flow",
            icon: Icons.assessment_outlined,
            onTap: () => context.push('/reports'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsGrid({required double gap}) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _actionTile(
                  title: "GASTO",
                  subtitle: "Track Expenses",
                  icon: Icons.payments_outlined,
                  onTap: () => context.push('/expenses'),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _actionTile(
                  title: "STOCK IN",
                  subtitle: "Add Products",
                  icon: Icons.inventory_2_outlined,
                  onTap: () => context.push('/stockin'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _actionTile(
                  title: "CAPITAL",
                  subtitle: "Add / Withdraw",
                  icon: Icons.savings_outlined,
                  onTap: () => context.push('/capital_management'),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _actionTile(
                  title: "OWNER UTANG",
                  subtitle: "Store Payables",
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.push('/owner_utang'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dividerTitle(String text) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final compact = w < 320;

        return Row(
          children: [
            Expanded(
              child: Container(height: 1, color: Colors.black.withOpacity(.10)),
            ),
            SizedBox(width: compact ? 8 : _r(context, 10)),
            Text(
              text,
              style: TextStyle(
                fontSize: compact ? 12 : _r(context, 12),
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 1.4 : _r(context, 1.6),
                color: Colors.black.withOpacity(.55),
              ),
            ),
            SizedBox(width: compact ? 8 : _r(context, 10)),
            Expanded(
              child: Container(height: 1, color: Colors.black.withOpacity(.10)),
            ),
          ],
        );
      },
    );
  }

  Widget _actionTile({
    required String title,
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
            final compact = h < 150 || w < 150;
            final veryCompact = h < 130 || w < 135;

            final iconSize = veryCompact
                ? (h * 0.16).clamp(_r(context, 18), _r(context, 24))
                : compact
                    ? (h * 0.17).clamp(_r(context, 20), _r(context, 26))
                    : (h * 0.18).clamp(_r(context, 22), _r(context, 30));

            final iconBox = veryCompact
                ? (h * 0.24).clamp(_r(context, 36), _r(context, 44))
                : compact
                    ? (h * 0.26).clamp(_r(context, 40), _r(context, 50))
                    : (h * 0.30).clamp(_r(context, 46), _r(context, 60));

            final titleSize = veryCompact
                ? (h * 0.075).clamp(_r(context, 11.5), _r(context, 13.5))
                : compact
                    ? (h * 0.082).clamp(_r(context, 12.2), _r(context, 14.5))
                    : (h * 0.09).clamp(_r(context, 13.5), _r(context, 16.0));

            final subSize = veryCompact
                ? (h * 0.064).clamp(_r(context, 9.5), _r(context, 11.0))
                : compact
                    ? (h * 0.070).clamp(_r(context, 10.2), _r(context, 12.0))
                    : (h * 0.075).clamp(_r(context, 11.0), _r(context, 13.0));

            final horizontalPad = veryCompact
                ? _r(context, 10)
                : compact
                    ? _r(context, 12)
                    : _r(context, 14);

            final topPad = veryCompact
                ? _r(context, 8)
                : compact
                    ? _r(context, 10)
                    : _r(context, 12);

            final bottomPad = veryCompact
                ? _r(context, 7)
                : compact
                    ? _r(context, 8)
                    : _r(context, 10);

            return Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                topPad,
                horizontalPad,
                bottomPad,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF7F3), Color(0xFFD8EEE8)],
                ),
                borderRadius: radius,
                border: Border.all(color: const Color(0xFFBFDCD4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C4B3E).withOpacity(0.18),
                    blurRadius: _r(context, 16),
                    offset: Offset(0, _r(context, 8)),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.85),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: veryCompact
                        ? _r(context, 32)
                        : compact
                            ? _r(context, 38)
                            : _r(context, 46),
                    height: veryCompact
                        ? _r(context, 4.5)
                        : compact
                            ? _r(context, 5.0)
                            : _r(context, 6.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(
                    height: veryCompact
                        ? _r(context, 5)
                        : compact
                            ? _r(context, 6)
                            : (h * 0.06).clamp(6.0, 10.0),
                  ),
                  Container(
                    height: iconBox,
                    width: iconBox,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.96),
                          Colors.white.withOpacity(0.82),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_r(context, 18)),
                      border: Border.all(
                        color: const Color(0xFFB4D8CF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0C4B3E).withOpacity(0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(
                    height: veryCompact
                        ? _r(context, 5)
                        : compact
                            ? _r(context, 6)
                            : (h * 0.06).clamp(6.0, 10.0),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: const Color(0xFF0B3D35),
                      ),
                    ),
                  ),
                  SizedBox(height: veryCompact ? 2 : 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: veryCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subSize,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2F5C54),
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

  Widget _reportsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(_r(context, 24));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final w = c.maxWidth;
            final compact = h < 140 || w < 260;

            final stripH = compact
                ? (h * 0.42).clamp(_r(context, 38), _r(context, 54))
                : (h * 0.55).clamp(_r(context, 48), _r(context, 70));

            final iconBox = compact
                ? (h * 0.42).clamp(_r(context, 40), _r(context, 54))
                : (h * 0.55).clamp(_r(context, 50), _r(context, 72));

            final iconSize = compact
                ? (h * 0.20).clamp(_r(context, 20), _r(context, 26))
                : (h * 0.26).clamp(_r(context, 24), _r(context, 32));

            final titleSize = compact
                ? (h * 0.15).clamp(_r(context, 13), _r(context, 16))
                : (h * 0.18).clamp(_r(context, 15), _r(context, 19));

            final subSize = compact
                ? (h * 0.11).clamp(_r(context, 10.5), _r(context, 12.5))
                : (h * 0.14).clamp(_r(context, 12), _r(context, 15));

            final padH = compact ? _r(context, 12) : _r(context, 16);
            final padV = compact
                ? (h * 0.11).clamp(_r(context, 8), _r(context, 12))
                : (h * 0.18).clamp(_r(context, 12), _r(context, 18));

            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF7F3), Color(0xFFD8EEE8)],
                ),
                borderRadius: radius,
                border: Border.all(color: const Color(0xFFBFDCD4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C4B3E).withOpacity(0.18),
                    blurRadius: _r(context, 16),
                    offset: Offset(0, _r(context, 8)),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.85),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
              child: Row(
                children: [
                  Container(
                    width: _r(context, 6),
                    height: stripH,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(width: compact ? _r(context, 10) : _r(context, 14)),
                  Container(
                    height: iconBox,
                    width: iconBox,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.96),
                          Colors.white.withOpacity(0.82),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_r(context, 18)),
                      border: Border.all(
                        color: const Color(0xFFB4D8CF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0C4B3E).withOpacity(0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
                  ),
                  SizedBox(width: compact ? _r(context, 10) : _r(context, 12)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: const Color(0xFF0B3D35),
                          ),
                        ),
                        SizedBox(height: compact ? 4 : _r(context, 5)),
                        Text(
                          subtitle,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2F5C54),
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
