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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header (same as your HeroHeader)
            Stack(
              children: [
                HeroHeader(
                  title: "Negosyo",
                  balance: homeState.isMoneyVisible ? balanceText : "₱ •••••",
                  mobileNumber: mobileText,
                  centerTitle: true,
                  showBack: true,
                  onBackTap: () => context.go('/home'),
                  onBellTap: () {},
                  onEyeTap: () => ref
                      .read(homeViewModelProvider.notifier)
                      .toggleMoneyVisibility(),
                ),
              ],
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(
                  children: [
                    _dividerTitle("ACTIONS"),
                    const SizedBox(height: 12),

                    // ✅ 2x2 grid (fills space, no scrolling)
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
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _actionTile(
                                    title: "STOCK IN",
                                    subtitle: "Add New Products",
                                    icon: Icons.inventory_2_outlined,
                                    onTap: () => context.push('/stockin'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _actionTile(
                                    title: "CAPITAL",
                                    subtitle: "Add / Withdraw Capital",
                                    icon: Icons.savings_outlined,
                                    onTap: () =>
                                        context.push('/capital_management'),
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                      ),
                    ),

                    const SizedBox(height: 14),
                    _dividerTitle("REPORTS"),
                    const SizedBox(height: 12),

                    Expanded(
                      flex: 3,
                      child: _reportsCard(
                        title: "REPORTS",
                        subtitle: "Income Statement, Balance Sheet, Cash Flow",
                        icon: Icons.assessment_outlined,
                        onTap: () => context.push('/reports'),
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
  }

  // ============================================================
  // UI: Divider Title like “— ACTIONS —”
  // ============================================================
  Widget _dividerTitle(String text) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withOpacity(.10),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            color: Colors.black.withOpacity(.55),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withOpacity(.10),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UI: Action Tile (center icon + label) like sample
  // ============================================================
  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(22);

    // ✅ closer to your sample: soft gray-green card + soft border
    final cardColor = AppColors.primary.withOpacity(.10);
    final borderColor = AppColors.primary.withOpacity(.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ icon “pill”
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.60),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(.12),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 12),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.3,
                    height: 1.15,
                    color: Colors.black.withOpacity(.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UI: Reports long card like sample (icon left, text, no arrow)
  // ============================================================
  Widget _reportsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(24);

    final cardColor = AppColors.primary.withOpacity(.10);
    final borderColor = AppColors.primary.withOpacity(.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.60),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(.12),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.6,
                          height: 1.15,
                          color: Colors.black.withOpacity(.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}