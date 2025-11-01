import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<T> buildSimpleTransitionPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    transitionDuration: const Duration(milliseconds: 300),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
