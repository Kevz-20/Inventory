import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Hello World'))),
    );
    expect(find.text('Hello World'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
