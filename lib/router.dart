import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/forgot_pin_screen.dart';
import 'views/screens/create_account_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/expenses_screen.dart';
import 'views/screens/stockin_screen.dart';
import 'views/screens/transaction_record_screen.dart';
import 'views/screens/transaction_history_screen.dart';
import 'views/screens/income_statement_screen.dart';

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/create_account',
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/forgot_pin',
      builder: (context, state) => const ForgotPinScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const ExpensesScreen(),
    ),
    GoRoute(
      path: '/stockin',
      builder: (context, state) => const StockinScreen(),
    ),
    GoRoute(
      path: '/transaction_record',
      builder: (context, state) => const TransactionRecordScreen(),
    ),
    GoRoute(
      path: '/transaction_history',
      builder: (context, state) => const TransactionHistoryScreen(),
    ),
    GoRoute(
      path: '/income_statement',
      builder: (context, state) => const IncomeStatementScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      routerConfig: _router,
      title: 'SLP',
    );
  }
}
