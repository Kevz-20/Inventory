import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 1) {
            context.go('/login');
          } else {
            onTap(index);
          }
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
