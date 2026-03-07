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

class CustomerMenuScreen extends ConsumerStatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  ConsumerState<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends ConsumerState<CustomerMenuScreen>
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

    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 700;

    // ✅ wider on tablet (same pattern as Home)
    final maxContentWidth = isTablet ? 760.0 : 520.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroHeader(
              title: "Customer",
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
            const SizedBox(height: 14),

            // ✅ Responsive "Expanded + Center + ConstrainedBox" (like Home)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final h = c.maxHeight;

                        // ✅ Make it feel "filled" on tablet
                        final tilesBlock = isTablet
                            ? (h * 0.46).clamp(260.0, 380.0)
                            : (h * 0.42).clamp(240.0, 320.0);

                        final gap = (h * 0.03).clamp(12.0, 18.0);

                        return Column(
                          children: [
                            SizedBox(
                              height: tilesBlock,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _homeBigActionTile(
                                      label: "HALIN",
                                      subtitle: "Record cash sales",
                                      icon: Icons.point_of_sale_outlined,
                                      onTap: () => context.push('/record_sales'),
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  Expanded(
                                    child: _homeBigActionTile(
                                      label: "CUSTOMER UTANG",
                                      subtitle: "Manage customer credit",
                                      icon: Icons.receipt_long_outlined,
                                      onTap: () => context.push('/customer_utang'),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: gap),
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

  /// ✅ Responsive tile (no fixed height)
  Widget _homeBigActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(22);
    final isHalin = label.toUpperCase().contains('HALIN');
    final startColor = isHalin
        ? const Color(0xFFEAF7F3)
        : const Color(0xFFE6F3F0);
    final endColor = isHalin
        ? const Color(0xFFD8EEE8)
        : const Color(0xFFD0E9E3);
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

            final iconSize = (h * 0.28).clamp(26.0, 34.0);
            final iconBox = (h * 0.60).clamp(54.0, 74.0);

            final titleSize = (h * 0.18).clamp(18.0, 22.0);
            final subSize = (h * 0.13).clamp(12.5, 15.0);

            final stripH = (h * 0.55).clamp(44.0, 60.0);
            final vPad = (h * 0.12).clamp(12.0, 18.0);

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: vPad),
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
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.80),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: stripH,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 16),

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
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFB4D8CF),
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
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
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
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFB4D8CF),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 20,
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
