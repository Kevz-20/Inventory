import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/nav_bar.dart';
import '../../app_router.dart'; // import for routeObserver
import 'package:intl/intl.dart'; // make sure this is imported at the top

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);

    // Initial fetch
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
    // Called when user comes back to this screen (e.g., using back button)
    ref.read(homeViewModelProvider.notifier).fetchHomeData();
  }

  Widget _menuCard(String title, String iconPath, {VoidCallback? onTap}) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            if (onTap != null) onTap();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedScale(
            scale: isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(iconPath, height: 48),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cash on Hand',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 219, 219, 219),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      homeState.isMoneyVisible
                          ? 'PHP ${NumberFormat.currency(locale: 'en_PH', symbol: '', decimalDigits: 2).format(homeState.cashOnHand)}'
                          : 'PHP ****',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(homeViewModelProvider.notifier)
                          .toggleMoneyVisibility(),
                      child: Icon(
                        homeState.isMoneyVisible
                            ? Icons.remove_red_eye
                            : Icons.visibility_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  'Mobile Number: ${homeState.mobileNumber ?? "Not set"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 219, 219, 219),
                    fontSize: 13,
                  ),
                ),
                if (homeState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Error: ${homeState.error}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _menuCard(
                      'Halin',
                      'lib/assets/record.png',
                      onTap: () => GoRouter.of(context).push('/record_sales'),
                    ),
                    _menuCard(
                      'Utang',
                      'lib/assets/utang.png',
                      onTap: () => GoRouter.of(context).push('/utang'),
                    ),
                    _menuCard(
                      'Gasto',
                      'lib/assets/gasto.png',
                      onTap: () => GoRouter.of(context).push('/expenses'),
                    ),
                    _menuCard(
                      'Stock In',
                      'lib/assets/stockin.png',
                      onTap: () => GoRouter.of(context).push('/stockin'),
                    ),
                    _menuCard(
                      'Capital\nManagement',
                      'lib/assets/cash.png',
                      onTap: () =>
                          GoRouter.of(context).push('/capital_management'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _menuCard(
                      'Balance\nSheet',
                      'lib/assets/balance_sheet.png',
                      onTap: () => GoRouter.of(context).push('/balance_sheet'),
                    ),
                    _menuCard(
                      'Income\nStatement',
                      'lib/assets/income_statement.png',
                      onTap: () =>
                          GoRouter.of(context).push('/income_statement'),
                    ),
                    _menuCard(
                      'Cash\nFlow',
                      'lib/assets/cashflow.png',
                      onTap: () => GoRouter.of(context).push('/cashflow'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: homeState.selectedIndex),
    );
  }
}
