import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap; // added optional onTap callback

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap, // accept onTap from parent
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;

        if (onTap != null) {
          onTap!(index); // notify parent
        }

        // Navigate using GoRouter
        String path;
        switch (index) {
          case 0:
            path = '/home';
            break;
          case 1:
            path = '/profile';
            break;
          case 2:
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
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
