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
      // Optional: if you have a selectedIndex setter, set it here:
      // ref.read(homeViewModelProvider.notifier).setSelectedIndex(0);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroHeader(
                  title: "Customer",
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
            const SizedBox(height: 14),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                      children: [
                        _bigActionTile(
                          label: "HALIN",
                          subtitle: "Record cash sales",
                          icon: Icons.point_of_sale_outlined,
                          onTap: () => context.push('/record_sales'),
                        ),
                        const SizedBox(height: 18),
                        _bigActionTile(
                          label: "Customer Utang",
                          subtitle: "Manage customer credit",
                          icon: Icons.receipt_long_outlined,
                          onTap: () => context.push('/customer_utang'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ ADD THIS
      bottomNavigationBar: BottomNavBar(
        currentIndex: homeState.selectedIndex,
        noHighlight: true, 
        ),
    );
  }

  Widget _bigActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}