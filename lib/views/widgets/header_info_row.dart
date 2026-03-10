import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../view_models/home_view_model.dart';
import './adaptive_digits_text.dart';

class HomeInfoHeader extends ConsumerWidget {
  final VoidCallback? onBellTap;

  const HomeInfoHeader({super.key, this.onBellTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);

    return Container(
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
          // Top row: label + bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cash on Hand',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 219, 219, 219),
                  fontSize: 14,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onBellTap,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Cash + eye toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AdaptiveDigitsText(
                  homeState.isMoneyVisible
                      ? 'PHP ${NumberFormat.currency(locale: 'en_PH', symbol: '', decimalDigits: 2).format(homeState.cashOnHand)}'
                      : 'PHP ****',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 28,
                  ),
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
    );
  }
}
