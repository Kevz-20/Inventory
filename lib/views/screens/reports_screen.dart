// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../services/db_service.dart';
import '../widgets/header.dart';
import '../widgets/utang_calendar_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Size _screenSize(BuildContext context) => MediaQuery.of(context).size;

  double _screenWidth(BuildContext context) => _screenSize(context).width;

  double _screenHeight(BuildContext context) => _screenSize(context).height;

  bool _isTablet(BuildContext context) => _screenWidth(context) >= 700;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool _isShortScreen(BuildContext context) => _screenHeight(context) < 500;

  bool _useSplitLayout(BuildContext context) {
    final width = _screenWidth(context);
    final height = _screenHeight(context);
    return width >= 900 && height >= 560;
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
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShortScreen = _isShortScreen(context);
    final useSplitLayout = _useSplitLayout(context);

    final maxContentWidth = useSplitLayout
        ? 1240.0
        : isTablet
            ? 780.0
            : double.infinity;

    final horizontalPadding = useSplitLayout
        ? 24.0
        : isTablet
            ? 18.0
            : isLandscape
                ? 14.0
                : 16.0;

    final verticalPadding = useSplitLayout
        ? 14.0
        : isShortScreen
            ? 8.0
            : isLandscape
                ? 10.0
                : 12.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Reports', showBackButton: true),
      body: SafeArea(
        top: false,
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
                      ? (w * 0.018).clamp(12.0, 18.0)
                      : isShortScreen
                          ? 10.0
                          : isLandscape
                              ? (h * 0.022).clamp(8.0, 12.0)
                              : (h * 0.026).clamp(10.0, 16.0);

                  if (isLandscape && isShortScreen && !isTablet) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: _r(context, 108),
                            child: _bigActionTile(
                              context: context,
                              label: "INCOME STATEMENT",
                              subtitle: "Sales, expenses, and net income",
                              icon: Icons.receipt_long_outlined,
                              onTap: () => context.push('/income_statement'),
                            ),
                          ),
                          SizedBox(height: gap),
                          SizedBox(
                            height: _r(context, 108),
                            child: _bigActionTile(
                              context: context,
                              label: "BALANCE SHEET",
                              subtitle: "Assets, liabilities, and equity",
                              icon: Icons.account_balance_outlined,
                              onTap: () => context.push('/balance_sheet'),
                            ),
                          ),
                          SizedBox(height: gap),
                          SizedBox(
                            height: _r(context, 108),
                            child: _bigActionTile(
                              context: context,
                              label: "CASH FLOW",
                              subtitle: "Cash in and cash out summary",
                              icon: Icons.show_chart_outlined,
                              onTap: () => context.push('/cashflow'),
                            ),
                          ),
                          SizedBox(height: gap),
                          SizedBox(
                            height: _r(context, 320),
                            child: _buildCalendarPanel(),
                          ),
                        ],
                      ),
                    );
                  }

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
                          child: _buildCalendarPanel(),
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
                        child: _buildTilesPanel(context: context, gap: gap),
                      ),
                      SizedBox(height: gap),
                      Expanded(
                        child: _buildCalendarPanel(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
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
            context: context,
            label: "INCOME STATEMENT",
            subtitle: "Sales, expenses, and net income",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.push('/income_statement'),
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: _bigActionTile(
            context: context,
            label: "BALANCE SHEET",
            subtitle: "Assets, liabilities, and equity",
            icon: Icons.account_balance_outlined,
            onTap: () => context.push('/balance_sheet'),
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: _bigActionTile(
            context: context,
            label: "CASH FLOW",
            subtitle: "Cash in and cash out summary",
            icon: Icons.show_chart_outlined,
            onTap: () => context.push('/cashflow'),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarPanel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DBService.instance.fetchCustomerUtangList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text("Error loading utang"),
            ),
          );
        } else {
          final utangList = snapshot.data ?? [];
          final totalUtang = utangList.fold<double>(
            0,
            (prev, e) => prev + (e['total_amount'] as double? ?? 0),
          );

          return UtangCalendarCard(
            utangList: utangList,
            totalUtang: totalUtang,
          );
        }
      },
    );
  }

  Widget _bigActionTile({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(_r(context, 22));
    final isPrimaryReport = label.toUpperCase().contains('INCOME');
    final startColor =
        isPrimaryReport ? const Color(0xFFEAF7F3) : const Color(0xFFE6F3F0);
    final endColor =
        isPrimaryReport ? const Color(0xFFD8EEE8) : const Color(0xFFD0E9E3);
    const primaryTextColor = Color(0xFF0B3D35);
    const secondaryTextColor = Color(0xFF2F5C54);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final w = c.maxWidth;
            final compact = h < 120 || w < 320;
            final isLandscape = _isLandscape(context);
            final isTablet = _isTablet(context);

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

            final horizontalPad = compact ? _r(context, 12) : _r(context, 18);
            final gapBetween = compact ? _r(context, 10) : _r(context, 16);
            final accentHeight = compact
                ? (h * 0.35).clamp(_r(context, 32), _r(context, 44))
                : isLandscape
                    ? (h * 0.50).clamp(_r(context, 42), _r(context, 60))
                    : (h * 0.55).clamp(_r(context, 48), _r(context, 64));

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: vPad,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [startColor, endColor],
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
                    color: Colors.white.withOpacity(0.80),
                    blurRadius: _r(context, 5),
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: _r(context, compact ? 4 : 5),
                    height: accentHeight * 0.9,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(width: gapBetween),
                  Container(
                    width: iconBox,
                    height: iconBox,
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
                      border: Border.all(color: const Color(0xFFB4D8CF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0C4B3E).withOpacity(0.16),
                          blurRadius: _r(context, 8),
                          offset: Offset(0, _r(context, 3)),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
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
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        SizedBox(height: _r(context, 6)),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: _r(context, compact ? 8 : 10)),
                  Container(
                    width: _r(context, compact ? 32 : 38),
                    height: _r(context, compact ? 32 : 38),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFB4D8CF)),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: _r(context, compact ? 18 : 20),
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
