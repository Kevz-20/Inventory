import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/page_transitions.dart';
import 'views/screens/about_app_screen.dart';
import 'views/screens/change_pin_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/create_account_screen.dart';
import 'views/screens/forgot_pin_screen.dart';
import 'views/screens/expenses_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/settings_screen.dart';
import 'views/screens/stockin_screen.dart';
import 'views/screens/transaction_record_screen.dart';
import 'views/screens/transaction_history_screen.dart';
import 'views/screens/income_statement_screen.dart';
import 'views/screens/balance_sheet_screen.dart';
import 'views/screens/capital_management_screen.dart';
import 'views/screens/utang_screen.dart';
import 'views/screens/record_sales_screen.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();
final router = GoRouter(
  initialLocation: '/login',
  observers: [routeObserver],
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        final fromLogout = state.extra == 'fromLogout';
        return customPage(
          state,
          const LoginScreen(),
          transition: fromLogout
              ? PageTransitionType.back
              : PageTransitionType.forward,
        );
      },
    ),
    GoRoute(
      path: '/create_account',
      pageBuilder: (context, state) => customPage(
        state,
        const CreateAccountScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/forgot_pin',
      pageBuilder: (context, state) => customPage(
        state,
        const ForgotPinScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) {
        final fromLogin = state.extra == 'fromLogin';
        return customPage(
          state,
          const HomeScreen(),
          transition: fromLogin
              ? PageTransitionType.forward
              : PageTransitionType.none,
        );
      },
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => customPage(
        state,
        const ProfileScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => customPage(
        state,
        const SettingsScreen(),
        transition: PageTransitionType.none,
      ),
    ),
    GoRoute(
      path: '/expenses',
      pageBuilder: (context, state) => customPage(
        state,
        const ExpensesScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/stockin',
      pageBuilder: (context, state) => customPage(
        state,
        const StockInScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/transaction_record',
      pageBuilder: (context, state) => customPage(
        state,
        const TransactionRecordScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/transaction_history',
      pageBuilder: (context, state) => customPage(
        state,
        const TransactionHistoryScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/income_statement',
      pageBuilder: (context, state) => customPage(
        state,
        const IncomeStatementScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/balance_sheet',
      pageBuilder: (context, state) => customPage(
        state,
        const BalanceSheetScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/capital_management',
      pageBuilder: (context, state) => customPage(
        state,
        const CapitalManagementScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/utang',
      pageBuilder: (context, state) => customPage(
        state,
        const UtangScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/record_sales',
      pageBuilder: (context, state) => customPage(
        state,
        const RecordSalesScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/about_app',
      pageBuilder: (context, state) => customPage(
        state,
        const AboutAppScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/change_pin',
      pageBuilder: (context, state) => customPage(
        state,
        const ChangePinScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
  ],
);
