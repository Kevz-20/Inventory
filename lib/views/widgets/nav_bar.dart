import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  /// ✅ If true, no tab will LOOK highlighted (Customer page use case)
  final bool noHighlight;

  final Function(int)? onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.noHighlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, 2);

    final w = MediaQuery.of(context).size.width;

    // ✅ Responsive but controlled (same across pages)
    // 390 = modern phone baseline
    final s = (w / 390).clamp(0.95, 1.10);

    final unselectedColor = Colors.grey[600]!;
    final selectedColor = noHighlight ? unselectedColor : AppColors.primary;

    // ✅ SAME size always (noHighlight affects color only)
    final iconSize = (28 * s).clamp(26.0, 32.0);
    final labelSize = (12.5 * s).clamp(12.0, 14.0);

    final labelStyle = TextStyle(
      fontSize: labelSize,
      fontWeight: FontWeight.w600,
    );

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: safeIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,

      selectedIconTheme: IconThemeData(color: selectedColor, size: iconSize),
      unselectedIconTheme: IconThemeData(color: unselectedColor, size: iconSize),

      // ✅ SAME style on selected/unselected so sizing is identical
      selectedLabelStyle: labelStyle,
      unselectedLabelStyle: labelStyle,
      selectedFontSize: labelSize,
      unselectedFontSize: labelSize,

      iconSize: iconSize,
      backgroundColor: Colors.white,

      onTap: (index) {
        onTap?.call(index);

        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/history');
            break;
          case 2:
            context.go('/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}