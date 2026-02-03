import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final Widget? action; // ✅ defined

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: AppColors.primary,
      elevation: 2,
      actions: action != null ? [action!] : null, // ✅ added this
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
