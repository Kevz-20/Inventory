// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/db_service.dart';


class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFCDD5EE);
  static const Color _titleColor = Color(0xFF1B3A7A);
  static const Color _subtitleColor = Color(0xFF5B6D96);
  static const Color _accentBlue = Color(0xFF2D5BE3);

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
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Image.asset(
            'lib/assets/arrowleft.png',
            width: _r(context, 22),
            height: _r(context, 22),
            fit: BoxFit.contain,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reports',
          style: TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w900,
            fontSize: _r(context, 20),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFCDD5EE)),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
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
                            child: _buildTopSellingPanel(context),
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
                          child: _buildTopSellingPanel(context),
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
                        child: _buildTopSellingPanel(context),
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

  Future<List<Map<String, dynamic>>> _fetchTopSellingProducts() async {
    final db = await DBService.instance.database;
    return db.rawQuery('''
      SELECT
        p.name AS product_name,
        COALESCE(SUM(si.quantity), 0) AS units_sold,
        COALESCE(SUM(si.unit_price * si.quantity), 0) AS revenue
      FROM sale_item si
      INNER JOIN product p ON p.id = si.product_id
      GROUP BY si.product_id, p.name
      ORDER BY units_sold DESC, revenue DESC, p.name ASC
      LIMIT 5
    ''');
  }

  Widget _buildTopSellingPanel(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTopSellingProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _insightCard(
            context: context,
            title: 'Top Selling Product',
            subtitle: 'Best-performing items based on recorded sales.',
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return _insightCard(
            context: context,
            title: 'Top Selling Product',
            subtitle: 'Best-performing items based on recorded sales.',
            child: const Center(child: Text('Error loading top-selling products')),
          );
        }

        final rows = snapshot.data ?? [];
        return _insightCard(
          context: context,
          title: 'Top Selling Product',
          subtitle: '',
          child: rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: _r(context, 28)),
                    child: Text(
                      'No sales data yet.',
                      style: TextStyle(
                        color: _subtitleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: _r(context, 14),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(rows.length, (index) {
                    final row = rows[index];
                    final name = (row['product_name'] ?? 'Unknown Product').toString();
                    final units = ((row['units_sold'] as num?)?.toInt() ?? 0);
                    return _topSellingRow(
                      context: context,
                      rank: index + 1,
                      name: name,
                      units: units,
                      isFirst: index == 0,
                    );
                  }),
                ),
        );
      },
    );
  }

  Widget _insightCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_r(context, 18)),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(_r(context, 24)),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF93A4CF).withOpacity(0.16),
            blurRadius: _r(context, 20),
            offset: Offset(0, _r(context, 10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: _r(context, 46),
                height: _r(context, 46),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFECF3FF), Color(0xFFD9E8FF)],
                  ),
                  borderRadius: BorderRadius.circular(_r(context, 16)),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: _accentBlue,
                  size: _r(context, 24),
                ),
              ),
              SizedBox(width: _r(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: _r(context, 18),
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      SizedBox(height: _r(context, 4)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _subtitleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: _r(context, 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _r(context, 18)),
          child,
        ],
      ),
    );
  }

  Widget _topSellingRow({
    required BuildContext context,
    required int rank,
    required String name,
    required int units,
    required bool isFirst,
  }) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFC94D),
      2 => const Color(0xFFB8C6DB),
      3 => const Color(0xFFD9975B),
      _ => const Color(0xFFE7EEFF),
    };

    final rankIconColor = switch (rank) {
      1 => const Color(0xFF8A5A00),
      2 => const Color(0xFF52657F),
      3 => const Color(0xFF7F4A20),
      _ => _titleColor,
    };

    return Container(
      margin: EdgeInsets.only(bottom: _r(context, 10)),
      padding: EdgeInsets.all(_r(context, 14)),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xFFF3F7FF) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(_r(context, 18)),
        border: Border.all(
          color: isFirst ? const Color(0xFFCFE0FF) : _cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: _r(context, 38),
            height: _r(context, 38),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: rank <= 3
                    ? [
                        rankColor.withOpacity(0.95),
                        rankColor.withOpacity(0.72),
                      ]
                    : [
                        rankColor,
                        const Color(0xFFD9E5FF),
                      ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.22),
                  blurRadius: _r(context, 8),
                  offset: Offset(0, _r(context, 4)),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: rank <= 3
                ? Icon(
                    rank == 1
                        ? Icons.workspace_premium_rounded
                        : rank == 2
                            ? Icons.military_tech_rounded
                            : Icons.emoji_events_rounded,
                    color: rankIconColor,
                    size: _r(context, 20),
                  )
                : Text(
                    '$rank',
                    style: TextStyle(
                      color: rankIconColor,
                      fontWeight: FontWeight.w900,
                      fontSize: _r(context, 15),
                    ),
                  ),
          ),
          if (rank <= 3) ...[
            SizedBox(width: _r(context, 8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _r(context, 8),
                vertical: _r(context, 4),
              ),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(_r(context, 999)),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankIconColor,
                  fontWeight: FontWeight.w900,
                  fontSize: _r(context, 11.5),
                ),
              ),
            ),
          ],
          SizedBox(width: _r(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: _r(context, 15),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$units units sold',
            style: TextStyle(
              color: _accentBlue,
              fontWeight: FontWeight.w900,
              fontSize: _r(context, 13.5),
            ),
          ),
        ],
      ),
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
        isPrimaryReport ? const Color(0xFFFDFEFF) : const Color(0xFFF8FAFF);
    final endColor =
        isPrimaryReport ? const Color(0xFFF1F5FF) : const Color(0xFFF3F7FF);
    const primaryTextColor = _titleColor;
    const secondaryTextColor = _subtitleColor;

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
                border: Border.all(color: _cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF93A4CF).withOpacity(0.18),
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
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.96),
                          const Color(0xFFEAF2FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_r(context, 18)),
                      border: Border.all(color: const Color(0xFFD8E4FF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF93A4CF).withOpacity(0.16),
                          blurRadius: _r(context, 8),
                          offset: Offset(0, _r(context, 3)),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: _accentBlue, size: iconSize),
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
                      border: Border.all(color: const Color(0xFFD8E4FF)),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: _accentBlue,
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
