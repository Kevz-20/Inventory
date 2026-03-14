import 'package:dswd_slp/views/screens/add_utang_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/page_transitions.dart';
import 'models/utang_customer_model.dart';
import 'services/db_service.dart';
import 'views/screens/about_app_screen.dart';
import 'views/screens/activity_log_screen.dart';
import 'views/screens/add_member_screen.dart';
import 'views/screens/cashflow_screen.dart';
import 'views/screens/change_pin_screen.dart';
import 'views/screens/existing_expense_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/create_account_screen.dart';
import 'views/screens/forgot_pin_screen.dart';
import 'views/screens/expenses_screen.dart';
import 'views/screens/new_customer.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/settings_screen.dart';
import 'views/screens/manage_inventory_screen.dart';
import 'views/screens/stockin_screen.dart';
import 'views/screens/sync_center_screen.dart';
import 'views/screens/transaction_record_screen.dart';
import 'views/screens/transaction_history_screen.dart';
import 'views/screens/income_statement_screen.dart';
import 'views/screens/balance_sheet_screen.dart';
import 'views/screens/capital_management_screen.dart';
import 'views/screens/record_sales_screen.dart';
import 'views/screens/utang_summary.screen.dart';
import 'views/screens/customer_menu_screen.dart';
import 'views/screens/negosyo_menu_screen.dart';
import 'views/screens/reports_screen.dart';
import 'views/screens/customer_utang_screen.dart';
import 'views/screens/owner_utang_screen.dart';
import 'views/screens/notification_screen.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

Future<({int accountCount, int memberCount, int? firstAccountId})>
    _loadSetupState() async {
  final db = await DBService.instance.database;
  final accountRows = await db.rawQuery(
    'SELECT id FROM account ORDER BY id ASC LIMIT 1',
  );
  final memberRows = await db.rawQuery(
    'SELECT COUNT(*) AS count FROM slpa_member',
  );
  return (
    accountCount: accountRows.isEmpty ? 0 : 1,
    memberCount: (memberRows.first['count'] as num?)?.toInt() ?? 0,
    firstAccountId:
        accountRows.isEmpty ? null : (accountRows.first['id'] as num).toInt(),
  );
}

final router = GoRouter(
  initialLocation: '/login',
  observers: [routeObserver],
  redirect: (context, state) async {
    final setup = await _loadSetupState();
    final path = state.matchedLocation;
    final isFirstMemberPath =
        path == '/add_member' && state.uri.queryParameters['first'] == '1';

    if (setup.accountCount == 0) {
      return path == '/create_account' ? null : '/create_account';
    }

    if (setup.memberCount == 0) {
      if (path == '/add_member') return null;
      return '/add_member?first=1';
    }

    if ((path == '/create_account' || isFirstMemberPath) &&
        setup.memberCount > 0) {
      return '/login';
    }

    return null;
  },
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
      path: '/add_member',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final data = extra is Map<String, dynamic> ? extra : const <String, dynamic>{};
        final firstFromQuery = state.uri.queryParameters['first'] == '1';
        return customPage(
          state,
          AddMemberScreen(
            accountId: data['accountId'] as int?,
            isFirstMember:
                data['isFirstMember'] as bool? ?? firstFromQuery,
          ),
          transition: PageTransitionType.forward,
        );
      },
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
      path: '/activity_log',
      pageBuilder: (context, state) => customPage(
        state,
        const ActivityLogScreen(),
        transition: PageTransitionType.forward,
      ),
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
      path: '/sync_center',
      pageBuilder: (context, state) => customPage(
        state,
        const SyncCenterScreen(),
        transition: PageTransitionType.forward,
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
      path: '/manage_inventory',
      pageBuilder: (context, state) => customPage(
        state,
        const ManageInventoryScreen(),
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
      path: '/history',
      pageBuilder: (context, state) => customPage(
        state,
        const TransactionHistoryScreen(),
        transition: PageTransitionType.none,
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
    path: '/customer_menu',
    pageBuilder: (context, state) => customPage(
      state,
      const CustomerMenuScreen(),
      transition: PageTransitionType.forward,
    ),
  ),

  GoRoute(
    path: '/negosyo_menu',
    pageBuilder: (context, state) => customPage(
      state,
      const NegosyoMenuScreen(),
      transition: PageTransitionType.forward,
    ),
  ),

  GoRoute(
  path: '/reports',
  pageBuilder: (context, state) => customPage(
    state,
    const ReportsScreen(),
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
      redirect: (context, state) => '/customer_utang',
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
    GoRoute(
      path: '/cashflow',
      pageBuilder: (context, state) => customPage(
        state,
        const CashFlowScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/new_customer',
      pageBuilder: (context, state) => customPage(
        state,
        const NewCustomerPage(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/add_utang',
      pageBuilder: (context, state) => customPage(
        state,
        const AddUtangPage(),
        transition: PageTransitionType.forward,
      ),
    ),

    GoRoute(
      path: '/customer_utang',
      builder: (context, state) {
        final extra = state.extra;
        final int? customerId = extra is int ? extra : null;
        return CustomerUtangScreen(initialCustomerId: customerId);
      },
    ),


    GoRoute(
      path: '/owner_utang',
      builder: (context, state) => const OwnerUtangScreen(),
    ),

    GoRoute(
      path: '/utang_summary',
      pageBuilder: (context, state) {
        final customer = state.extra as UtangCustomer;

        return customPage(
          state,
          UtangSummaryPage(customer: customer),
          transition: PageTransitionType.forward,
        );
      },
    ),

    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => customPage(
        state,
        const NotificationScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
    GoRoute(
      path: '/list_expenses',
      pageBuilder: (context, state) => customPage(
        state,
        const ExistingExpensesScreen(),
        transition: PageTransitionType.forward,
      ),
    ),
  ],
);
