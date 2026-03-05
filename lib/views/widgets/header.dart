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
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700;

    // ✅ keep same toolbar height, just adjust title sizing a bit on tablet
    final titleFontSize = isTablet ? 18.0 : 16.0;

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

      // ✅ Responsive title (won’t overflow on small phones)
      title: LayoutBuilder(
        builder: (context, c) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: c.maxWidth,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: titleFontSize,
                ),
              ),
            ),
          );
        },
      ),

      centerTitle: true,
      backgroundColor: AppColors.primary,
      elevation: 2,

      // ✅ same action logic
      actions: action != null ? [action!] : null,

      // ✅ small spacing improvement so title stays centered nicely
      titleSpacing: showBackButton ? 0 : (isTablet ? 16 : 8),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}