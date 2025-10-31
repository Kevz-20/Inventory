import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/forgot_pin_screen.dart';
import 'ui/screens/create_account_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/expenses_screen.dart';
import 'ui/screens/stockin_screen.dart';
import 'ui/screens/transaction_record_screen.dart';
import 'core/routes/route_transitions.dart';

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    // Login Screen
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // Create Account Screen
    GoRoute(
      path: '/create_account',
      pageBuilder: (context, state) => buildSlideTransitionPage(
        child: const CreateAccountScreen(),
        beginOffset: const Offset(1.0, 0.0),
      ),
    ),

    // Forgot Pin Screen
    GoRoute(
      path: '/forgot_pin',
      pageBuilder: (context, state) => buildSlideTransitionPage(
        child: const ForgotPinScreen(),
        beginOffset: const Offset(1.0, 0.0),
      ),
    ),

    // Home Screen
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => buildSlideTransitionPage(
        child: const HomeScreen(),
        beginOffset: const Offset(1.0, 0.0),
      ),
    ),

    // Expenses Screen
    GoRoute(
      path: '/expenses',
      pageBuilder: (context, state) => buildSlideTransitionPage(
        child: const ExpensesScreen(),
        beginOffset: const Offset(1.0, 0.0),
      ),
    ),

    // Stock In Screen
    GoRoute(
      path: '/stockin',
      pageBuilder: (context, state) => buildSlideTransitionPage(
        child: const StockinScreen(),
        beginOffset: const Offset(1.0, 0.0),
      ),
    ),

    // Transaction Record Screen
    GoRoute(
      path: '/transaction_record',
      pageBuilder: (context, state) => buildSlideTransitionPage(
        child: const TransactionRecordScreen(),
        beginOffset: const Offset(1.0, 0.0),
      ),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SLP',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
