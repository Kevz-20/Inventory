import 'package:flutter_test/flutter_test.dart';
import 'package:dswd_slp/app.dart';
import 'package:dswd_slp/ui/screens/login_screen.dart';
import 'package:dswd_slp/ui/screens/home_screen.dart';

void main() {
  testWidgets('App starts at PinLoginPage and navigates to HomeScreen', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify the initial screen is PinLoginPage
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    // Simulate entering correct PIN: 1, 2, 3, 4, then Enter
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('enter'));
    await tester.pumpAndSettle();

    // Verify that HomeScreen appears
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
