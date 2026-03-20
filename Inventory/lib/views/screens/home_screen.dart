// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_router.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/primary_footer_nav.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
// Palette aligned with login_screen.dart (navy / blue family)
class _C {
  // Surface & background
  static const bg         = Color(0xFFF0F4FF);
  static const surface    = Color(0xFFFFFFFF);
  static const border     = Color(0xFFCDD5EE);

  // Brand — navy / blue  (same as login screen)
  static const brandDeep  = Color(0xFF1B3A7A);
  static const brandMid   = Color(0xFF5B6D96);
  static const textDark   = Color(0xFF1B3A7A);

  // Hero card gradient
  static const heroStart  = Color(0xFF1A3584);
  static const heroMid    = Color(0xFF2456D0);
  static const heroEnd    = Color(0xFF4B8AF0);

  // Feature-card icon palette  (diverse colours for quick visual scanning)
  static const red        = Color(0xFFD63031);
  static const redBg      = Color(0xFFFFF0F0);
  static const green      = Color(0xFF00897B);
  static const greenBg    = Color(0xFFE0F2F1);
  static const blue       = Color(0xFF2D5BE3);
  static const blueBg     = Color(0xFFEEF2FF);
  static const orange     = Color(0xFFE67E00);
  static const orangeBg   = Color(0xFFFFF3E0);
  static const purple     = Color(0xFF6C3FC4);
  static const purpleBg   = Color(0xFFF3EEFF);
  static const teal       = Color(0xFF0097A7);
  static const tealBg     = Color(0xFFE0F7FA);

  // Status / utility
  static const amber       = Color(0xFFB7770D);
  static const amberBg     = Color(0xFFFFF8E1);
  static const amberBorder = Color(0xFFFFCC02);
  static const warn        = Color(0xFFD63031);
  static const liveDot     = Color(0xFF00C853);
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  bool _bannerDismissed = false;

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
    _bannerDismissed = false;
    ref.read(homeViewModelProvider.notifier).fetchHomeData();
  }

  double get _w => MediaQuery.of(context).size.width;
  double _r(double v) => v * (_w / 390).clamp(0.85, 1.15);

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning!';
    if (h < 18) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context) {
    final size       = MediaQuery.of(context).size;
    // Tablet (≥700 px) → fixed no-scroll; phone → scrollable
    final isNoScroll = size.width >= 700;

    final state    = ref.watch(homeViewModelProvider);
    final currency = NumberFormat.currency(
        locale: 'en_PH', symbol: '₱', decimalDigits: 2);

    final cashText   = state.isMoneyVisible
        ? currency.format(state.cashOnHand) : '₱ ••••••';
    final salesText  = state.isMoneyVisible
        ? currency.format(state.todaySales) : '₱ ••••••';
    final dateLabel  = DateFormat('EEE, MMM d, yyyy').format(DateTime.now());
    final showBanner = state.lowStockCount > 0 && !_bannerDismissed;

    void onToggle() =>
        ref.read(homeViewModelProvider.notifier).toggleMoneyVisibility();

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(state),
      bottomNavigationBar:
          const PrimaryFooterNav(selectedTab: PrimaryFooterTab.home),
      body: isNoScroll
          ? _PhoneBody(
              cashText:        cashText,
              salesText:       salesText,
              dateLabel:       dateLabel,
              greeting:        _greeting,
              state:           state,
              showBanner:      showBanner,
              onToggle:        onToggle,
              onDismissBanner: () => setState(() => _bannerDismissed = true),
              r:               _r,
            )
          : _ScrollBody(
              cashText:        cashText,
              salesText:       salesText,
              dateLabel:       dateLabel,
              greeting:        _greeting,
              state:           state,
              showBanner:      showBanner,
              onToggle:        onToggle,
              onDismissBanner: () => setState(() => _bannerDismissed = true),
              onRefresh: () async =>
                  ref.read(homeViewModelProvider.notifier).fetchHomeData(),
              r: _r,
            ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(HomeState state) {
    return PreferredSize(
      preferredSize: Size.fromHeight(_r(70)),
      child: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: _r(70),
        titleSpacing: 0,
        // Subtle bottom separator (matches login card borders)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
        title: Padding(
          padding: EdgeInsets.fromLTRB(_r(20), _r(6), _r(20), 0),
          child: Row(
            children: [
              // Logo — rounded rect, gradient fallback matching hero palette
              Container(
                width: _r(44), height: _r(44),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_r(12)),
                  boxShadow: [BoxShadow(
                    color: _C.heroStart.withOpacity(0.22),
                    blurRadius: _r(10), offset: Offset(0, _r(3)))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'lib/assets/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.heroStart, _C.heroEnd],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('E', style: TextStyle(
                        fontSize: _r(20), fontWeight: FontWeight.w900,
                        color: Colors.white)),
                  ),
                ),
              ),
              SizedBox(width: _r(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('EMPOWER', style: TextStyle(
                        fontSize: _r(19), fontWeight: FontWeight.w900,
                        color: _C.brandDeep, letterSpacing: 0.9)),
                    Text('Sari-Sari Store Manager', style: TextStyle(
                        fontSize: _r(11.5), fontWeight: FontWeight.w600,
                        color: _C.brandMid)),
                  ],
                ),
              ),
              _NavIconButton(
                icon: Icons.notifications_outlined,
                badge: state.lowStockCount > 0
                    ? '${state.lowStockCount.clamp(0, 99)}' : null,
                onTap: () => context.push('/notifications'),
                r: _r,
              ),
              SizedBox(width: _r(8)),
              _NavIconButton(
                icon: Icons.receipt_long_outlined,
                onTap: () => context.go('/history'),
                r: _r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Phone body — NO SCROLL ────────────────────────────────────────────────────
class _PhoneBody extends StatelessWidget {
  const _PhoneBody({
    required this.cashText,
    required this.salesText,
    required this.dateLabel,
    required this.greeting,
    required this.state,
    required this.showBanner,
    required this.onToggle,
    required this.onDismissBanner,
    required this.r,
  });

  final String cashText, salesText, dateLabel, greeting;
  final HomeState state;
  final bool showBanner;
  final VoidCallback onToggle, onDismissBanner;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    final pad = r(14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, r(12), pad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(
                cashText:           cashText,
                greeting:           greeting,
                dateLabel:          dateLabel,
                isMoneyVisible:     state.isMoneyVisible,
                onToggleVisibility: onToggle,
                compact:            true,
                r:                  r,
              ),
              SizedBox(height: r(10)),
              _StatsStrip(
                salesText:        salesText,
                transactionCount: state.transactionCount,
                lowStockCount:    state.lowStockCount,
                onSalesTap:       () => context.go('/history'),
                onTransTap:       () => context.go('/history'),
                onLowStockTap:    () => context.go('/manage_inventory'),
                r: r,
              ),
              SizedBox(height: r(12)),
              _SectionLabel(r: r),
              SizedBox(height: r(8)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, r(10)),
            child: _FeatureGrid(fillHeight: true, r: r),
          ),
        ),
      ],
    );
  }
}

// ─── Tablet body — SCROLLABLE ──────────────────────────────────────────────────
class _ScrollBody extends StatelessWidget {
  const _ScrollBody({
    required this.cashText,
    required this.salesText,
    required this.dateLabel,
    required this.greeting,
    required this.state,
    required this.showBanner,
    required this.onToggle,
    required this.onDismissBanner,
    required this.onRefresh,
    required this.r,
  });

  final String cashText, salesText, dateLabel, greeting;
  final HomeState state;
  final bool showBanner;
  final VoidCallback onToggle, onDismissBanner;
  final Future<void> Function() onRefresh;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _C.heroMid,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r(16), r(12), r(16), r(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              cashText:           cashText,
              greeting:           greeting,
              dateLabel:          dateLabel,
              isMoneyVisible:     state.isMoneyVisible,
              onToggleVisibility: onToggle,
              compact:            false,
              r:                  r,
            ),
            SizedBox(height: r(14)),
            _StatsStrip(
              salesText:        salesText,
              transactionCount: state.transactionCount,
              lowStockCount:    state.lowStockCount,
              onSalesTap:       () => context.go('/history'),
              onTransTap:       () => context.go('/history'),
              onLowStockTap:    () => context.go('/manage_inventory'),
              r: r,
            ),
            SizedBox(height: r(18)),
            _SectionLabel(r: r),
            SizedBox(height: r(12)),
            _FeatureGrid(fillHeight: false, r: r),
            SizedBox(height: r(16)),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Icon Button ───────────────────────────────────────────────────────────
class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon, required this.onTap, required this.r, this.badge,
  });
  final IconData icon;
  final VoidCallback onTap;
  final double Function(double) r;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: r(44), height: r(44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _C.blueBg,
            borderRadius: BorderRadius.circular(r(12)),
            border: Border.all(color: _C.border, width: 1.5),
            boxShadow: [BoxShadow(
                color: _C.brandDeep.withOpacity(0.08),
                blurRadius: r(8), offset: Offset(0, r(2)))],
          ),
          child: Icon(icon, color: _C.brandDeep, size: r(20)),
        ),
        if (badge != null)
          Positioned(
            top: -r(5), right: -r(5),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: r(6), vertical: r(2)),
              decoration: BoxDecoration(
                color: _C.warn,
                borderRadius: BorderRadius.circular(r(20)),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(badge!, style: TextStyle(
                  fontSize: r(10), fontWeight: FontWeight.w900,
                  color: Colors.white, height: 1.2)),
            ),
          ),
      ]),
    );
  }
}

// ─── Hero Card ─────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.cashText,
    required this.greeting,
    required this.dateLabel,
    required this.isMoneyVisible,
    required this.onToggleVisibility,
    required this.compact,
    required this.r,
  });
  final String cashText, greeting, dateLabel;
  final bool isMoneyVisible, compact;
  final VoidCallback onToggleVisibility;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    final vPad       = compact ? r(16) : r(22);
    final amountSize = compact ? r(34) : r(38);
    final greetSize  = compact ? r(14) : r(15);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r(22), vPad, r(22), vPad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r(24)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.heroStart, _C.heroMid, _C.heroEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: _C.heroStart.withOpacity(0.32),
            blurRadius: r(28), offset: Offset(0, r(10)),
          ),
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        // Decorative translucent circles
        Positioned(
          bottom: -r(50), right: -r(50),
          child: Container(
            width: r(190), height: r(190),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          bottom: -r(22), right: -r(22),
          child: Container(
            width: r(120), height: r(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ),

        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Row 1: greeting + eye toggle ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  greeting,
                  style: TextStyle(
                    fontSize: greetSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.90),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggleVisibility,
                child: Container(
                  width: r(38), height: r(38),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(r(11)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.30), width: 1.5),
                  ),
                  child: Icon(
                    isMoneyVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: r(18),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? r(12) : r(16)),

          // ── Row 2: live dot + label ────────────────────────────────────────
          Row(children: [
            Container(
              width: r(8), height: r(8),
              decoration: const BoxDecoration(
                color: _C.liveDot, shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: r(6)),
            Text(
              'Cash on Hand',
              style: TextStyle(
                fontSize: r(12.5),
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.78),
                letterSpacing: 0.5,
              ),
            ),
          ]),

          SizedBox(height: r(5)),

          // ── Amount ────────────────────────────────────────────────────────
          Text(
            cashText,
            style: TextStyle(
              fontSize: amountSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),

          SizedBox(height: compact ? r(12) : r(16)),

          // ── Date footer ───────────────────────────────────────────────────
          Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: r(13), color: Colors.white.withOpacity(0.68)),
            SizedBox(width: r(5)),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: r(12),
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ─── Stats Strip ───────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.salesText,
    required this.transactionCount,
    required this.lowStockCount,
    required this.onSalesTap,
    required this.onTransTap,
    required this.onLowStockTap,
    required this.r,
  });
  final String salesText;
  final int transactionCount, lowStockCount;
  final VoidCallback onSalesTap, onTransTap, onLowStockTap;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(r(20)),
        border: Border.all(color: _C.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.brandDeep.withOpacity(0.07),
            blurRadius: r(14), offset: Offset(0, r(3)),
          ),
        ],
      ),
      padding: EdgeInsets.all(r(6)),
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(child: _StatItem(
            icon: Icons.trending_up_rounded,
            iconColor: _C.blue, iconBg: _C.blueBg,
            label: "Today's Sales", value: salesText,
            onTap: onSalesTap, r: r,
          )),
          _VertDivider(r: r),
          Expanded(child: _StatItem(
            icon: Icons.receipt_long_outlined,
            iconColor: _C.green, iconBg: _C.greenBg,
            label: 'Transactions', value: '$transactionCount',
            onTap: onTransTap, r: r,
          )),
          _VertDivider(r: r),
          Expanded(child: _StatItem(
            icon: Icons.warning_amber_rounded,
            iconColor: _C.orange, iconBg: _C.orangeBg,
            label: 'Low Stock',
            value: '$lowStockCount item${lowStockCount == 1 ? '' : 's'}',
            valueColor: lowStockCount > 0 ? _C.warn : null,
            onTap: onLowStockTap, r: r,
          )),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.value,
    required this.onTap, required this.r, this.valueColor,
  });
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  final Color? valueColor;
  final VoidCallback onTap;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: r(12), horizontal: r(6)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: r(38), height: r(38),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(r(11)),
              ),
              child: Icon(icon, color: iconColor, size: r(20)),
            ),
            SizedBox(height: r(7)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: r(11.5),
                fontWeight: FontWeight.w700,
                color: _C.brandMid,
              ),
            ),
            SizedBox(height: r(3)),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: r(14.5),
                fontWeight: FontWeight.w900,
                color: valueColor ?? _C.textDark,
              ),
            ),
            SizedBox(height: r(3)),
            Icon(Icons.keyboard_arrow_right_rounded,
                size: r(13), color: _C.brandMid.withOpacity(0.40)),
          ]),
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider({required this.r});
  final double Function(double) r;

  @override
  Widget build(BuildContext context) => Container(
    width: 1.5,
    margin: EdgeInsets.symmetric(vertical: r(10)),
    color: _C.border,
  );
}

// ─── Low Stock Banner ──────────────────────────────────────────────────────────
// ignore: unused_element
class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({
    required this.count, required this.onTap,
    required this.onDismiss, required this.r,
  });
  final int count;
  final VoidCallback onTap, onDismiss;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(11)),
        decoration: BoxDecoration(
          color: _C.amberBg,
          borderRadius: BorderRadius.circular(r(16)),
          border: Border.all(color: _C.amberBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _C.amber.withOpacity(0.10),
              blurRadius: r(10), offset: Offset(0, r(3)),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: r(38), height: r(38),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.amber.withOpacity(0.14),
              borderRadius: BorderRadius.circular(r(11)),
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: _C.amber, size: r(21)),
          ),
          SizedBox(width: r(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count item${count == 1 ? '' : 's'} running low on stock',
                  style: TextStyle(
                    fontSize: r(13),
                    fontWeight: FontWeight.w800,
                    color: _C.amber,
                  ),
                ),
                SizedBox(height: r(1)),
                Text(
                  'Tap to review inventory',
                  style: TextStyle(
                    fontSize: r(11.5),
                    fontWeight: FontWeight.w600,
                    color: _C.amber.withOpacity(0.70),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: r(6)),
          Icon(Icons.arrow_forward_ios_rounded,
              size: r(12), color: _C.amber.withOpacity(0.72)),
          SizedBox(width: r(8)),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: r(28), height: r(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _C.amber.withOpacity(0.14),
                borderRadius: BorderRadius.circular(r(8)),
              ),
              child: Icon(Icons.close_rounded,
                  size: r(14), color: _C.amber),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.r});
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Accent bar — navy to match brand
        Container(
          width: r(4), height: r(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_C.heroStart, _C.heroEnd],
            ),
            borderRadius: BorderRadius.circular(r(4)),
          ),
        ),
        SizedBox(width: r(9)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: r(13.5),
                fontWeight: FontWeight.w800,
                color: _C.brandDeep,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Tap any button to continue',
              style: TextStyle(
                fontSize: r(11),
                fontWeight: FontWeight.w600,
                color: _C.brandMid,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Feature Grid ──────────────────────────────────────────────────────────────
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.fillHeight, required this.r});
  final bool fillHeight;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    final items = [
      _FeatureItem(
        title: 'Record Sale',    subtitle: 'Sell products',
        assetPath: 'lib/assets/shoppingcart_button.png',
        iconBg: _C.redBg,    accentColor: _C.red,
        onTap: () => context.push('/record_sales'),
      ),
      _FeatureItem(
        title: 'Customer Utang', subtitle: 'Manage credit',
        assetPath: 'lib/assets/customer_button.png',
        iconBg: _C.purpleBg, accentColor: _C.purple,
        onTap: () => context.push('/customer_utang'),
      ),
      _FeatureItem(
        title: 'Stock In',       subtitle: 'Add new stock',
        assetPath: 'lib/assets/stockin_button.png',
        iconBg: _C.greenBg,  accentColor: _C.green,
        onTap: () => context.push('/stockin'),
      ),
      _FeatureItem(
        title: 'Expense',        subtitle: 'Track spending',
        assetPath: 'lib/assets/expense_button.png',
        iconBg: _C.orangeBg, accentColor: _C.orange,
        onTap: () => context.push('/expenses'),
      ),
      _FeatureItem(
        title: 'Capital',        subtitle: 'Business funds',
        assetPath: 'lib/assets/capital.png',
        iconBg: _C.blueBg,   accentColor: _C.blue,
        onTap: () => context.push('/capital_management'),
      ),
      _FeatureItem(
        title: 'Reports',        subtitle: 'Detailed analytics',
        assetPath: 'lib/assets/reports_button.png',
        iconBg: _C.tealBg,   accentColor: _C.teal,
        onTap: () => context.push('/reports'),
      ),
    ];

    final rowGap = SizedBox(height: r(fillHeight ? 10 : 12));

    Widget buildRow(int i) {
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _FeatureCard(item: items[i],     fill: fillHeight, r: r)),
          SizedBox(width: r(10)),
          Expanded(child: _FeatureCard(item: items[i + 1], fill: fillHeight, r: r)),
        ],
      );
      return fillHeight ? Expanded(child: row) : IntrinsicHeight(child: row);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildRow(0), rowGap,
        buildRow(2), rowGap,
        buildRow(4),
      ],
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title, required this.subtitle, required this.assetPath,
    required this.iconBg, required this.accentColor, required this.onTap,
  });
  final String title, subtitle, assetPath;
  final Color iconBg, accentColor;
  final VoidCallback onTap;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.item, required this.fill, required this.r,
  });
  final _FeatureItem item;
  final bool fill;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    final iconSize = fill ? r(56) : r(62);
    final iconRad  = fill ? r(16) : r(18);
    final imgSize  = fill ? r(36) : r(40);
    final titleSz  = fill ? r(15.5) : r(17);
    final subSz    = fill ? r(12.5) : r(13.5);
    final hPad     = fill ? r(14) : r(16);
    final vPad     = fill ? r(14) : r(18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(r(22)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(r(22)),
            border: Border.all(color: _C.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: item.accentColor.withOpacity(0.08),
                blurRadius: r(12), offset: Offset(0, r(4)),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: iconSize, height: iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(iconRad),
                  border: Border.all(
                      color: item.accentColor.withOpacity(0.22), width: 1.5),
                ),
                child: Image.asset(
                  item.assetPath,
                  width: imgSize, height: imgSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.apps_rounded,
                    color: item.accentColor,
                    size: imgSize * 0.85,
                  ),
                ),
              ),
              SizedBox(width: r(10)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSz,
                        fontWeight: FontWeight.w800,
                        color: _C.textDark,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: r(3)),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subSz,
                        fontWeight: FontWeight.w600,
                        color: _C.brandMid,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r(6)),
              Container(
                width: r(30), height: r(30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(r(9)),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    size: r(17), color: item.accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
