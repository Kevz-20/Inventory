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

            // ✅ NO SCROLLVIEW: use Expanded layout that fits screen
            Expanded(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    child: Column(
      children: [
        _dividerTitle("ACTIONS"),
        const SizedBox(height: 14),

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
                      ),
                    ),
                    const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
        const SizedBox(height: 14),

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
  // UI: Divider Title
  // ============================================================
  Widget _dividerTitle(String text) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.black.withOpacity(.10)),
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
          child: Container(height: 1, color: Colors.black.withOpacity(.10)),
        ),
      ],
    );
  }

  // ============================================================
  // UI: Action Tile (NO fixed height)
  // ✅ Important: remove fixed height so Expanded can control it
  // ============================================================
  Widget _actionTile({
  required String title,
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

          // scale sizes based on available height
          final iconSize = (h * 0.18).clamp(22.0, 30.0);
          final iconBox = (h * 0.30).clamp(46.0, 60.0);
          final titleSize = (h * 0.09).clamp(13.5, 16.0);
          final subSize = (h * 0.075).clamp(11.0, 13.0);

          return Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                  width: 46,
                  height: 6,
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

                // ✅ Make subtitle always fit (1–2 lines depending on space)
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
  }) {
    final radius = BorderRadius.circular(24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(.25),
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
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.2,
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
        ),
      ),
    );
  }
}
