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

    // âœ… same approach as HomeScreen: a bit wider on tablet
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

                  // âœ… similar spacing behavior as HomeScreen
                  final gap = (h * 0.02).clamp(10.0, 16.0);

                  // âœ… tile height scales with space (still scrollable)
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

  // âœ… SAME LOOK AS HomeScreen._bigActionTile (uniform design)
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF7F3), Color(0xFFD8EEE8)],
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
                  // âœ… left accent bar (same as Home)
                  Container(
                    width: 5,
                    height: (h * 0.55).clamp(48.0, 64.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // âœ… icon box (same as Home)
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
                      border: Border.all(color: const Color(0xFFB4D8CF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0C4B3E).withOpacity(0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
                  ),
                  const SizedBox(width: 16),

                  // âœ… text (same as Home)
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
                              color: const Color(0xFF0B3D35),
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
                            color: const Color(0xFF2F5C54),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFB4D8CF)),
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
