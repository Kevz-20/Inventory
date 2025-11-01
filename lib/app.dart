import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/route_transitions.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/forgot_pin_screen.dart';
import 'ui/screens/create_account_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/expenses_screen.dart';
import 'ui/screens/stockin_screen.dart';
import 'ui/screens/transaction_record_screen.dart';

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/create_account',
      pageBuilder: (context, state) =>
          buildSimpleTransitionPage(child: const CreateAccountScreen()),
    ),
    GoRoute(
      path: '/forgot_pin',
      pageBuilder: (context, state) =>
          buildSimpleTransitionPage(child: const ForgotPinScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) =>
          buildSimpleTransitionPage(child: const HomeScreen()),
    ),
    GoRoute(
      path: '/expenses',
      pageBuilder: (context, state) =>
          buildSimpleTransitionPage(child: const ExpensesScreen()),
    ),
    GoRoute(
      path: '/stockin',
      pageBuilder: (context, state) =>
          buildSimpleTransitionPage(child: const StockinScreen()),
    ),
    GoRoute(
      path: '/transaction_record',
      pageBuilder: (context, state) =>
          buildSimpleTransitionPage(child: const TransactionRecordScreen()),
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
