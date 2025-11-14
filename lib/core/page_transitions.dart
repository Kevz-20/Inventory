import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<T> slidePage<T>({
  required Widget child,
  required LocalKey key,
  bool forward = true,
}) {
  final beginOffset = forward ? const Offset(1, 0) : const Offset(-1, 0);

  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
