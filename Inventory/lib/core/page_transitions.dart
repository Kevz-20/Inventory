import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PageTransitionType { forward, back, none }

Page<void> customPage(
  GoRouterState state,
  Widget child, {
  PageTransitionType transition = PageTransitionType.forward,
}) {
  switch (transition) {
    case PageTransitionType.none:
      return NoTransitionPage(key: state.pageKey, child: child);
    case PageTransitionType.forward:
      return CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );
          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
    case PageTransitionType.back:
      return CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation =
              Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );
          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
  }
}
