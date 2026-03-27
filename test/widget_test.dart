// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:coffee_plus_app/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Use runAsync because of the network calls in initState
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp());
      // Wait for the app to settle
      await tester.pump(const Duration(milliseconds: 500));
    });

    // Verify that the title appears
    expect(find.text('COFFEE PLUS+'), findsOneWidget);
  });
}
