import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Ensure currentIndex is within valid range
    final safeIndex = currentIndex.clamp(0, 1);

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: (index) {
        if (index == safeIndex) return;

        if (onTap != null) {
          onTap!(index);
        }

        // Navigate using GoRouter
        String path;
        switch (index) {
          case 0:
            path = '/home';
            break;
          case 1:
            path = '/settings';
            break;
          default:
            path = '/home';
        }

        context.go(path);
      },
      iconSize: 28,
      selectedFontSize: 14,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
