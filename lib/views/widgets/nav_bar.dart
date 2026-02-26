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

    final unselectedColor = Colors.grey[600]!;
    final selectedColor = noHighlight ? unselectedColor : AppColors.primary;

    // ✅ Make selected look the same as unselected when noHighlight is true
    final selectedFontSize = noHighlight ? 12.0 : 14.0;
    final unselectedFontSize = 12.0;

    final selectedLabelStyle = TextStyle(
      fontSize: selectedFontSize,
      fontWeight: FontWeight.w600,
      color: selectedColor,
    );

    final unselectedLabelStyle = TextStyle(
      fontSize: unselectedFontSize,
      fontWeight: FontWeight.w600,
      color: unselectedColor,
    );

    final selectedIconTheme = IconThemeData(
      color: selectedColor,
      size: 28,
    );

    final unselectedIconTheme = IconThemeData(
      color: unselectedColor,
      size: 28,
    );

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: safeIndex,

      // ✅ When noHighlight=true, selected color == unselected color
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,

      // ✅ Same icon theme so nothing pops out
      selectedIconTheme: selectedIconTheme,
      unselectedIconTheme: unselectedIconTheme,

      // ✅ Same label styling (this is what often still looks highlighted)
      selectedLabelStyle: noHighlight ? unselectedLabelStyle : selectedLabelStyle,
      unselectedLabelStyle: unselectedLabelStyle,

      // ✅ Same font size so selection doesn’t look “bigger”
      selectedFontSize: selectedFontSize,
      unselectedFontSize: unselectedFontSize,

      backgroundColor: Colors.white,

      onTap: (index) {
        // Allow navigation always
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
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}