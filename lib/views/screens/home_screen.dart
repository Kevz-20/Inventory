// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_router.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/dashboard_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).fetchHomeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
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

  double get _screenWidth => MediaQuery.of(context).size.width;

  bool get _isTablet => _screenWidth >= 700;

  bool get _isNarrowPhone => _screenWidth < 430;

  bool get _isVeryNarrowPhone => _screenWidth < 380;

  double _r(double value) {
    final scale = (_screenWidth / 390).clamp(0.84, 1.18);
    return value * scale;
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final currency = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    final cashText = homeState.isMoneyVisible
        ? currency.format(homeState.cashOnHand)
        : '₱ ••••••';
    final salesText = homeState.isMoneyVisible
        ? currency.format(homeState.todaySales)
        : '₱ ••••••';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_isVeryNarrowPhone ? _r(86) : _r(96)),
        child: AppBar(
          backgroundColor: const Color(0xFFF5F7FF),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: _isVeryNarrowPhone ? _r(86) : _r(96),
          titleSpacing: 0,
          title: Padding(
            padding: EdgeInsets.fromLTRB(
              _isVeryNarrowPhone ? _r(14) : _r(22),
              _r(8),
              _isVeryNarrowPhone ? _r(14) : _r(22),
              0,
            ),
            child: _topHeader(homeState),
          ),
        ),
      ),
      body: Stack(
        children: [
          const DashboardBackground(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    _isVeryNarrowPhone ? _r(14) : _r(22),
                    _r(18),
                    _isVeryNarrowPhone ? _r(14) : _r(22),
                    _r(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroCard(
                        cashText: cashText,
                        updatedLabel: 'Updated just now',
                      ),
                      SizedBox(height: _r(16)),
                      _summaryStrip(
                        salesText: salesText,
                        transactionCount: homeState.transactionCount,
                        lowStockCount: homeState.lowStockCount,
                      ),
                      SizedBox(height: _r(16)),
                      _featureSection(),
                      SizedBox(height: _r(24)),
                    ],
                  ),
                ),
              ),
              _bottomNav(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topHeader(HomeState state) {
    return Row(
      children: [
        Image.asset(
          'lib/assets/logo.png',
          width: _isVeryNarrowPhone ? _r(44) : _r(52),
          height: _isVeryNarrowPhone ? _r(44) : _r(52),
        ),
        SizedBox(width: _r(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMPOWER',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _isVeryNarrowPhone ? _r(21) : _r(26),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: const Color(0xFF204C93),
                ),
              ),
              Text(
                'Sari-Sari Store Manager',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _isVeryNarrowPhone ? _r(11.5) : _r(14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5B6D96),
                ),
              ),
            ],
          ),
        ),
        _circleIconButton(
          assetPath: 'lib/assets/notification.png',
          badge: state.lowStockCount > 0
              ? '${state.lowStockCount.clamp(0, 99)}'
              : null,
          onTap: () => context.push('/notifications'),
        ),
        SizedBox(width: _r(8)),
        _circleIconButton(
          assetPath: 'lib/assets/transactionhistory.png',
          onTap: () => context.go('/history'),
        ),
      ],
    );
  }

  Widget _heroCard({
    required String cashText,
    required String updatedLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_isVeryNarrowPhone ? _r(14) : _r(18)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_r(26)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF173D86),
            Color(0xFF1D79D8),
            Color(0xFF28C4D5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4A9A).withOpacity(0.24),
            blurRadius: _r(28),
            offset: Offset(0, _r(14)),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: _r(80),
            right: _r(_isVeryNarrowPhone ? 0 : 110),
            bottom: -_r(20),
            child: _waveBand(
              height: _r(90),
              opacity: 0.18,
              colors: const [
                Color(0xFFAEDCFF),
                Color(0x884FC8FF),
                Color(0x0037B8FF),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash on Hand',
                      style: TextStyle(
                        fontSize: _isVeryNarrowPhone ? _r(16) : _r(18),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.96),
                      ),
                    ),
                    SizedBox(height: _r(10)),
                    Text(
                      cashText,
                      style: TextStyle(
                        fontSize: _isVeryNarrowPhone ? _r(24) : _r(34),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: _r(10)),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.white.withOpacity(0.92),
                          size: _isVeryNarrowPhone ? _r(16) : _r(18),
                        ),
                        SizedBox(width: _r(8)),
                        Expanded(
                          child: Text(
                            updatedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: _isVeryNarrowPhone ? _r(11.5) : _r(13.5),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isVeryNarrowPhone) ...[
                SizedBox(width: _r(10)),
                Image.asset(
                  'lib/assets/cashonhand.png',
                  width: _isNarrowPhone ? _r(92) : _r(126),
                  height: _isNarrowPhone ? _r(92) : _r(126),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.account_balance_wallet_rounded,
                    size: _r(92),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStrip({
    required String salesText,
    required int transactionCount,
    required int lowStockCount,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _r(12),
        vertical: _r(14),
      ),
      decoration: _softCardDecoration(),
      child: _isNarrowPhone
          ? Column(
              children: [
                _metricItem(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF2B7BE4),
                  title: "Today's Sales",
                  value: salesText,
                  compact: false,
                ),
                _horizontalDivider(),
                _metricItem(
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFF2E7EF7),
                  title: 'Transactions',
                  value: '$transactionCount',
                  compact: false,
                ),
                _horizontalDivider(),
                _metricItem(
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFFF8A36),
                  title: 'Low Stock',
                  value: '$lowStockCount item${lowStockCount == 1 ? '' : 's'}',
                  valueColor: const Color(0xFFFF7A1A),
                  compact: false,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _metricItem(
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF2B7BE4),
                    title: "Today's Sales",
                    value: salesText,
                    compact: true,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _metricItem(
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF2E7EF7),
                    title: 'Transactions',
                    value: '$transactionCount',
                    compact: true,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _metricItem(
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFFF8A36),
                    title: 'Low Stock',
                    value: '$lowStockCount item${lowStockCount == 1 ? '' : 's'}',
                    valueColor: const Color(0xFFFF7A1A),
                    compact: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _featureSection() {
    final cards = [
      _featureCard(
        title: 'Record Sale',
        subtitle: 'Sell products',
        assetPath: 'lib/assets/shoppingcart_button.png',
        accent: const Color(0xFFFFE9D8),
        onTap: () => context.push('/record_sales'),
      ),
      _featureCard(
        title: 'Customer Utang',
        subtitle: 'Manage customer credit',
        assetPath: 'lib/assets/customer_button.png',
        accent: const Color(0xFFE9F6EA),
        onTap: () => context.push('/customer_utang'),
      ),
      _featureCard(
        title: 'Stock In',
        subtitle: 'Add new stock',
        assetPath: 'lib/assets/stockin_button.png',
        accent: const Color(0xFFE3F1FF),
        onTap: () => context.push('/stockin'),
      ),
      _featureCard(
        title: 'Expense',
        subtitle: 'Track expenses',
        assetPath: 'lib/assets/expense_button.png',
        accent: const Color(0xFFF3E9FF),
        onTap: () => context.push('/expenses'),
      ),
      _featureCard(
        title: 'Capital',
        subtitle: 'Manage business funds',
        assetPath: 'lib/assets/capital.png',
        accent: const Color(0xFFE8F6FF),
        onTap: () => context.push('/capital_management'),
      ),
      _featureCard(
        title: 'Reports',
        subtitle: 'View detailed reports',
        assetPath: 'lib/assets/reports_button.png',
        accent: const Color(0xFFEAF1FF),
        onTap: () => context.push('/reports'),
      ),
    ];

    if (!_isTablet) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) SizedBox(height: _r(14)),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            SizedBox(width: _r(14)),
            Expanded(child: cards[1]),
          ],
        ),
        SizedBox(height: _r(14)),
        Row(
          children: [
            Expanded(child: cards[2]),
            SizedBox(width: _r(14)),
            Expanded(child: cards[3]),
          ],
        ),
        SizedBox(height: _r(14)),
        Row(
          children: [
            Expanded(child: cards[4]),
            SizedBox(width: _r(14)),
            Expanded(child: cards[5]),
          ],
        ),
      ],
    );
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
    required String assetPath,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final compact = !_isTablet;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_r(22)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? _r(12) : _r(14)),
          decoration: _softCardDecoration(),
          child: Stack(
            children: [
              Positioned(
                right: -_r(34),
                bottom: -_r(34),
                child: Container(
                  width: _r(compact ? 120 : 140),
                  height: _r(compact ? 120 : 140),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.45),
                  ),
                ),
              ),
              Positioned(
                left: -_r(18),
                bottom: -_r(14),
                child: _waveBand(
                  height: _r(52),
                  colors: [
                    accent.withOpacity(0.50),
                    accent.withOpacity(0.10),
                    Colors.transparent,
                  ],
                  opacity: 1,
                ),
              ),
              Row(
                children: [
                  Image.asset(
                    assetPath,
                    width: compact ? _r(72) : _r(86),
                    height: compact ? _r(72) : _r(86),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: compact ? _r(8) : _r(10)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? _r(16) : _r(18),
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF203A6C),
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: _r(6)),
                        Text(
                          subtitle,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? _r(12.5) : _r(13.5),
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5D7097),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
    required bool compact,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _r(compact ? 6 : 2),
        vertical: _r(compact ? 0 : 2),
      ),
      child: Row(
        children: [
          Container(
            width: _r(compact ? 42 : 38),
            height: _r(compact ? 42 : 38),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(_r(14)),
            ),
            child: Icon(icon, color: iconColor, size: _r(compact ? 24 : 22)),
          ),
          SizedBox(width: _r(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _r(compact ? 12.2 : 11.3),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF687B9F),
                  ),
                ),
                SizedBox(height: _r(2)),
                Text(
                  value,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _r(compact ? 15.2 : 14),
                    fontWeight: FontWeight.w900,
                    color: valueColor ?? const Color(0xFF1F376B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    IconData? icon,
    String? assetPath,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_r(24)),
        onTap: onTap,
        child: SizedBox(
          width: _isVeryNarrowPhone ? _r(44) : _r(52),
          height: _isVeryNarrowPhone ? _r(44) : _r(52),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: assetPath == null
                    ? BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7082B8).withOpacity(0.18),
                            blurRadius: _r(18),
                            offset: Offset(0, _r(8)),
                          ),
                        ],
                      )
                    : null,
                child: assetPath != null
                    ? Padding(
                        padding: EdgeInsets.all(_isVeryNarrowPhone ? _r(4) : _r(5)),
                        child: Image.asset(
                          assetPath,
                          width: _isVeryNarrowPhone ? _r(30) : _r(34),
                          height: _isVeryNarrowPhone ? _r(30) : _r(34),
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(
                        icon,
                        color: const Color(0xFF284C93),
                        size: _isVeryNarrowPhone ? _r(22) : _r(26),
                      ),
              ),
              if (badge != null)
                Positioned(
                  right: -_r(2),
                  top: -_r(2),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _r(6),
                      vertical: _r(3),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6942),
                      borderRadius: BorderRadius.circular(_r(20)),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: _r(11),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        _isVeryNarrowPhone ? _r(10) : _r(18),
        0,
        _isVeryNarrowPhone ? _r(10) : _r(18),
        _r(18),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _isVeryNarrowPhone ? _r(4) : _r(10),
        vertical: _r(10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(_r(28)),
        border: Border.all(color: const Color(0xFFDDE3F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A8AB5).withOpacity(0.18),
            blurRadius: _r(22),
            offset: Offset(0, _r(12)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
                onTap: () => context.go('/home'),
              ),
            ),
            Expanded(
              child: _navItem(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                onTap: () => context.push('/manage_inventory'),
              ),
            ),
            Expanded(
              child: _navItem(
                icon: Icons.receipt_long_outlined,
                label: 'Owner Utang',
                onTap: () => context.push('/owner_utang'),
              ),
            ),
            Expanded(
              child: _navItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.go('/settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    IconData? icon,
    String? assetPath,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final color =
        selected ? const Color(0xFF205CC8) : const Color(0xFF65779C);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_r(18)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: _isVeryNarrowPhone ? _r(6) : _r(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              assetPath != null
                  ? Image.asset(
                      assetPath,
                      width: _isVeryNarrowPhone ? _r(22) : _r(27),
                      height: _isVeryNarrowPhone ? _r(22) : _r(27),
                      fit: BoxFit.contain,
                      color: color,
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: _isVeryNarrowPhone ? _r(22) : _r(27),
                    ),
              SizedBox(height: _r(4)),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _isVeryNarrowPhone ? _r(9.2) : _r(11.5),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: _r(54),
      color: const Color(0xFFDCE3F5),
    );
  }

  Widget _horizontalDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _r(10)),
      height: 1,
      color: const Color(0xFFDCE3F5),
    );
  }

  BoxDecoration _softCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_r(24)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7F9FF),
          Color(0xFFF5F8FF),
        ],
      ),
      border: Border.all(color: const Color(0xFFE1E6F8)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF93A4CF).withOpacity(0.16),
          blurRadius: _r(22),
          offset: Offset(0, _r(12)),
        ),
      ],
    );
  }

  Widget _waveBand({
    required double height,
    List<Color>? colors,
    double opacity = 0.24,
  }) {
    final waveColors = colors ??
        [
          const Color(0xFF89B2FF).withOpacity(opacity),
          const Color(0xFFDCEAFF).withOpacity(opacity * 0.7),
          const Color(0x00FFFFFF),
        ];

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          return SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              size: Size(width, height),
              painter: _WavePainter(colors: waveColors),
            ),
          );
        },
      ),
    );
  }

}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = colors[0];
    final paint2 = Paint()..color = colors[1];

    final path1 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.28,
        size.width * 0.48,
        size.height * 0.60,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.88,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.48,
        size.width * 0.66,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.96,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}
