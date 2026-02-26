import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_router.dart';
import '../../core/app_colors.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/hero_header.dart';

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

              // ✅ Center the title
              centerTitle: true,

              // ✅ Show back arrow
              showBack: true,

              // ✅ Go back to previous page
              onBackTap: () => context.go('/home'),
              // OR if you want always go to Home:
              // onBackTap: () => context.go('/home'),

              onBellTap: () {},

              onEyeTap: () => ref
                  .read(homeViewModelProvider.notifier)
                  .toggleMoneyVisibility(),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _tile("GASTO", Icons.payments_outlined,
                      onTap: () => context.push('/expenses')),
                  _tile("STOCK IN", Icons.inventory_2_outlined,
                      onTap: () => context.push('/stockin')),
                  _tile("CAPITAL", Icons.savings_outlined,
                      onTap: () => context.push('/capital_management')),

                  const SizedBox(height: 14),
                  const Text(
                    "REPORTS",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  _tile("INCOME STATEMENT", Icons.receipt_long_outlined,
                      onTap: () => context.push('/income_statement')),
                  _tile("BALANCE SHEET", Icons.account_balance_outlined,
                      onTap: () => context.push('/balance_sheet')),
                  _tile("CASH FLOW", Icons.bar_chart_outlined,
                      onTap: () => context.push('/cashflow')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, IconData icon, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(40),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}