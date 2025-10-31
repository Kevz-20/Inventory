import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<T> buildSlideTransitionPage<T>({
  required Widget child,
  Offset beginOffset = const Offset(1.0, 0.0),
}) {
  return CustomTransitionPage<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeOutCubic,
      );

      final tween = Tween(begin: beginOffset, end: Offset.zero);

      return SlideTransition(
        position: tween.animate(curvedAnimation),
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
    },
  );
}
