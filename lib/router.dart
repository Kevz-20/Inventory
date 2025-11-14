import 'package:go_router/go_router.dart';
import 'core/page_transitions.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/create_account_screen.dart';
import 'views/screens/forgot_pin_screen.dart';
import 'views/screens/expenses_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/stockin_screen.dart';
import 'views/screens/transaction_record_screen.dart';
import 'views/screens/transaction_history_screen.dart';
import 'views/screens/income_statement_screen.dart';
import 'views/screens/balance_sheet_screen.dart';
import 'views/screens/capital_management_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const LoginScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/create_account',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const CreateAccountScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/forgot_pin',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const ForgotPinScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) {
        final from = state.extra as String?;
        return slidePage(
          key: state.pageKey,
          child: const HomeScreen(),
          forward: from == null || from == '/login',
        );
      },
    ),
    GoRoute(
      path: '/expenses',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const ExpensesScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/stockin',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const StockinScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/transaction_record',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const TransactionRecordScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/transaction_history',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const TransactionHistoryScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/income_statement',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const IncomeStatementScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/balance_sheet',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const BalanceSheetScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/capital_management',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const CapitalManagementScreen(),
        forward: true,
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => slidePage(
        key: state.pageKey,
        child: const ProfileScreen(),
        forward: true,
      ),
    ),
  ],
);
