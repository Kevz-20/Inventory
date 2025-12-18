import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: 3 items → clamp 0–2
    final safeIndex = currentIndex.clamp(0, 2);

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: (index) {
        if (index == safeIndex) return;

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
      iconSize: 28,
      selectedFontSize: 14,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
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