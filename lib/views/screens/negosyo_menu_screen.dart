// ignore_for_file: deprecated_member_use

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Same style as your other pages: phone->tablet scaling, clamped.
        final double scale = (w / 390).clamp(0.90, 1.20);

        // Responsive spacing
        final double padH = (16 * scale).clamp(14, 22);
        final double padTop = (10 * scale).clamp(8, 14);
        final double padBottom = (12 * scale).clamp(10, 16);

        final double gap12 = (12 * scale).clamp(8, 14);
        final double gap14 = (14 * scale).clamp(10, 18);

        // On very short screens, reduce gaps a bit to avoid overflow.
        final bool shortScreen = h < 720;
        final double actionsGap = shortScreen ? (10 * scale).clamp(8, 12) : gap14;

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
                  centerTitle: true,
                  showBack: true,
                  onBackTap: () => context.go('/home'),
                  onBellTap: () => context.push('/notifications'),
                  onEyeTap: () => ref
                      .read(homeViewModelProvider.notifier)
                      .toggleMoneyVisibility(),
                ),

                // ✅ NO SCROLLVIEW: keep your Expanded layout, just responsive spacing
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
                    child: Column(
                      children: [
                        _dividerTitle("ACTIONS", scale: scale),
                        SizedBox(height: actionsGap),

                        // 2x2 Grid (fills available space)
                        Expanded(
                          flex: 7,
                          child: Column(
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
                                        scale: scale,
                                      ),
                                    ),
                                    SizedBox(width: gap12),
                                    Expanded(
                                      child: _actionTile(
                                        title: "STOCK IN",
                                        subtitle: "Add Products",
                                        icon: Icons.inventory_2_outlined,
                                        onTap: () => context.push('/stockin'),
                                        scale: scale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: gap12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _actionTile(
                                        title: "CAPITAL",
                                        subtitle: "Add / Withdraw",
                                        icon: Icons.savings_outlined,
                                        onTap: () =>
                                            context.push('/capital_management'),
                                        scale: scale,
                                      ),
                                    ),
                                    SizedBox(width: gap12),
                                    Expanded(
                                      child: _actionTile(
                                        title: "OWNER UTANG",
                                        subtitle: "Store Payables",
                                        icon: Icons.receipt_long_outlined,
                                        onTap: () =>
                                            context.push('/owner_utang'),
                                        scale: scale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: actionsGap),
                        _dividerTitle("REPORTS", scale: scale),
                        SizedBox(height: actionsGap),

                        Expanded(
                          flex: 3,
                          child: _reportsCard(
                            title: "REPORTS",
                            subtitle: "Income, Balance Sheet, Cash Flow",
                            icon: Icons.assessment_outlined,
                            onTap: () => context.push('/reports'),
                            scale: scale,
                          ),
                        ),
                      ],
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
      },
    );
  }

  // ============================================================
  // UI: Divider Title (responsive)
  // ============================================================
  Widget _dividerTitle(String text, {double? scale}) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final sBase = (w / 360).clamp(1.0, 1.25);
        final s = scale != null ? (sBase * (scale.clamp(0.9, 1.2))) : sBase;

        return Row(
          children: [
            Expanded(
              child: Container(height: 1, color: Colors.black.withOpacity(.10)),
            ),
            SizedBox(width: (10 * s).clamp(10.0, 14.0)),
            Text(
              text,
              style: TextStyle(
                fontSize: (12 * s).clamp(12.0, 15.0),
                fontWeight: FontWeight.w900,
                letterSpacing: (1.6 * s).clamp(1.6, 2.0),
                color: Colors.black.withOpacity(.55),
              ),
            ),
            SizedBox(width: (10 * s).clamp(10.0, 14.0)),
            Expanded(
              child: Container(height: 1, color: Colors.black.withOpacity(.10)),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // UI: Action Tile (NO fixed height)
  // ============================================================
  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    double? scale,
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

            // scale sizes based on available height (your original logic)
            final iconSize = (h * 0.18).clamp(22.0, 30.0);
            final iconBox = (h * 0.30).clamp(46.0, 60.0);
            final titleSize = (h * 0.09).clamp(13.5, 16.0);
            final subSize = (h * 0.075).clamp(11.0, 13.0);

            // Responsive paddings (UI only)
            final s = (scale ?? 1.0).clamp(0.9, 1.2);
            final pL = (14 * s).clamp(12.0, 18.0);
            final pT = (12 * s).clamp(10.0, 16.0);
            final pB = (10 * s).clamp(8.0, 14.0);

            return Container(
              padding: EdgeInsets.fromLTRB(pL, pT, pL, pB),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.85),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: (46 * s).clamp(40.0, 52.0),
                    height: (6 * s).clamp(5.5, 7.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(height: (h * 0.06).clamp(6.0, 10.0)),
                  Container(
                    height: iconBox,
                    width: iconBox,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
                  ),
                  SizedBox(height: (h * 0.06).clamp(6.0, 10.0)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subSize,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.65),
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

  // ============================================================
  // UI: Reports Card (responsive height via Expanded)
  // ============================================================
  Widget _reportsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    double? scale,
  }) {
    final radius = BorderRadius.circular(24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;

            final stripH = (h * 0.55).clamp(48.0, 70.0);
            final iconBox = (h * 0.55).clamp(50.0, 72.0);
            final iconSize = (h * 0.26).clamp(24.0, 32.0);

            final titleSize = (h * 0.18).clamp(15.0, 19.0);
            final subSize = (h * 0.14).clamp(12.0, 15.0);

            final s = (scale ?? 1.0).clamp(0.9, 1.2);
            final padV = (h * 0.18).clamp(12.0, 18.0) * s;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.85),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                (16 * s).clamp(14.0, 22.0),
                padV.clamp(12.0, 22.0),
                (16 * s).clamp(14.0, 22.0),
                padV.clamp(12.0, 22.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: (6 * s).clamp(5.5, 7.0),
                    height: stripH,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(width: (14 * s).clamp(12.0, 18.0)),
                  Container(
                    height: iconBox,
                    width: iconBox,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
                  ),
                  SizedBox(width: (12 * s).clamp(10.0, 16.0)),
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
                          ),
                        ),
                        SizedBox(height: (5 * s).clamp(4.0, 8.0)),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.65),
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