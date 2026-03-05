// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../widgets/header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700;

    // ✅ same approach as HomeScreen: a bit wider on tablet
    final maxContentWidth = isTablet ? 760.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Reports', showBackButton: true),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: LayoutBuilder(
                builder: (context, c) {
                  final h = c.maxHeight;

                  // ✅ similar spacing behavior as HomeScreen
                  final gap = (h * 0.02).clamp(10.0, 16.0);

                  // ✅ tile height scales with space (still scrollable)
                  final tileH = isTablet
                      ? (h * 0.18).clamp(110.0, 140.0)
                      : (h * 0.16).clamp(104.0, 130.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        SizedBox(
                          height: tileH,
                          child: _bigActionTile(
                            label: "INCOME STATEMENT",
                            subtitle: "Sales, expenses, and net income",
                            icon: Icons.receipt_long_outlined,
                            onTap: () => context.push('/income_statement'),
                          ),
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          height: tileH,
                          child: _bigActionTile(
                            label: "BALANCE SHEET",
                            subtitle: "Assets, liabilities, and equity",
                            icon: Icons.account_balance_outlined,
                            onTap: () => context.push('/balance_sheet'),
                          ),
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          height: tileH,
                          child: _bigActionTile(
                            label: "CASH FLOW",
                            subtitle: "Cash in and cash out summary",
                            icon: Icons.show_chart_outlined,
                            onTap: () => context.push('/cashflow'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ SAME LOOK AS HomeScreen._bigActionTile (uniform design)
  Widget _bigActionTile({
    required String label,
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

            final iconSize = (h * 0.28).clamp(26.0, 34.0);
            final iconBox = (h * 0.60).clamp(54.0, 74.0);

            final titleSize = (h * 0.18).clamp(16.5, 22.0); // slight min for long labels
            final subSize = (h * 0.13).clamp(12.0, 15.0);

            final vPad = (h * 0.12).clamp(12.0, 18.0);

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: vPad),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ✅ left accent bar (same as Home)
                  Container(
                    width: 6,
                    height: (h * 0.55).clamp(48.0, 64.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ✅ icon box (same as Home)
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(.25),
                      ),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
                  ),
                  const SizedBox(width: 16),

                  // ✅ text (same as Home)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ optional chevron (remove if Home doesn't have it)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black.withOpacity(0.25),
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