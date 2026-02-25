import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_router.dart';
import '../../core/app_colors.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/hero_header.dart';


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

  return Scaffold(
    backgroundColor: AppColors.surface,
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          HeroHeader(
            title: "Customer",
            balance: homeState.isMoneyVisible ? balanceText : "₱ •••••",
            mobileNumber: mobileText,
            onBellTap: () {},
            onEyeTap: () => ref
                .read(homeViewModelProvider.notifier)
                .toggleMoneyVisibility(),
          ),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _menuBtn(
                        label: "HALIN",
                        icon: Icons.point_of_sale_outlined,
                        onTap: () => context.push('/record_sales'),
                      ),
                      const SizedBox(height: 12),
                      _menuBtn(
                        label: "UTANG",
                        icon: Icons.receipt_long_outlined,
                        onTap: () => context.push('/utang'),
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
  );
}

  Widget _menuBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}