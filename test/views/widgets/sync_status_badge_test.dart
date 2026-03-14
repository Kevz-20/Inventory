import 'package:dswd_slp/views/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncStatusBadge', () {
    testWidgets('renders synced state label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusBadge(
              syncStatus: 'synced',
              lastSyncedAt: '2026-03-14T15:00:00.000',
            ),
          ),
        ),
      );

      expect(find.text('Synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('renders pending state label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusBadge(
              syncStatus: 'pending_upload',
            ),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_rounded), findsOneWidget);
    });

    testWidgets('falls back to local only label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusBadge(
              syncStatus: null,
            ),
          ),
        ),
      );

      expect(find.text('Local only'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android_rounded), findsOneWidget);
    });

    testWidgets('invokes onTap when badge is pressed', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusBadge(
              syncStatus: 'pending_upload',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SyncStatusBadge));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
