import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PrimaryFooterTab {
  home,
  products,
  ownerUtang,
  settings,
}

class PrimaryFooterNav extends StatelessWidget {
  const PrimaryFooterNav({
    super.key,
    this.selectedTab,
  });

  final PrimaryFooterTab? selectedTab;

  double _r(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.84, 1.18);
    return value * scale;
  }

  bool _isVeryNarrowPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 380;
  }

  @override
  Widget build(BuildContext context) {
    final isVeryNarrowPhone = _isVeryNarrowPhone(context);

    return Container(
      margin: EdgeInsets.fromLTRB(
        isVeryNarrowPhone ? _r(context, 10) : _r(context, 18),
        0,
        isVeryNarrowPhone ? _r(context, 10) : _r(context, 18),
        _r(context, 18),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isVeryNarrowPhone ? _r(context, 4) : _r(context, 10),
        vertical: _r(context, 10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(_r(context, 28)),
        border: Border.all(color: const Color(0xFFDDE3F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A8AB5).withValues(alpha: 0.18),
            blurRadius: _r(context, 22),
            offset: Offset(0, _r(context, 12)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                context,
                icon: Icons.home_rounded,
                label: 'Home',
                selected: selectedTab == PrimaryFooterTab.home,
                onTap: () => context.go('/home'),
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                selected: selectedTab == PrimaryFooterTab.products,
                onTap: () => context.go('/manage_inventory'),
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.receipt_long_outlined,
                label: 'Owner Utang',
                selected: selectedTab == PrimaryFooterTab.ownerUtang,
                onTap: () => context.push('/owner_utang'),
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: selectedTab == PrimaryFooterTab.settings,
                onTap: () => context.go('/settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool selected,
  }) {
    final isVeryNarrowPhone = _isVeryNarrowPhone(context);
    final color =
        selected ? const Color(0xFF205CC8) : const Color(0xFF65779C);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_r(context, 18)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isVeryNarrowPhone ? _r(context, 6) : _r(context, 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: isVeryNarrowPhone ? _r(context, 22) : _r(context, 27),
              ),
              SizedBox(height: _r(context, 4)),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize:
                      isVeryNarrowPhone ? _r(context, 9.2) : _r(context, 11.5),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
