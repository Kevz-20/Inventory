import 'package:dswd_slp/models/account_model.dart';
import 'package:dswd_slp/providers/profile_view_model_provider.dart';
import 'package:dswd_slp/view_models/profile_view_model.dart';
import 'package:dswd_slp/views/screens/audit_log_screen.dart';
import 'package:dswd_slp/views/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsScreen opens audit log from sync section', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/audit_logs',
          builder: (context, state) => const AuditLogScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith((ref) {
            final vm = _FakeProfileViewModel(ref);
            vm.account = Account(
              id: 1,
              mobileNumber: '09171234567',
              pin: '1234',
              firstName: 'Maria',
              middleName: 'S',
              lastName: 'Santos',
            );
            vm.isLoading = false;
            return vm;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    final auditLogTile = find.widgetWithText(ListTile, 'Audit Log');
    await tester.scrollUntilVisible(
      auditLogTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(auditLogTile);
    await tester.pumpAndSettle();

    expect(find.text('Audit Log'), findsWidgets);
    expect(find.byType(AuditLogScreen), findsOneWidget);
  });
}

class _FakeProfileViewModel extends ProfileViewModel {
  _FakeProfileViewModel(super.ref);

  @override
  Future<void> init() async {}
}
