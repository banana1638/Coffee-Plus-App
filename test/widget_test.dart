import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_plus_app/widgets/auth_modal.dart';
import 'package:coffee_plus_app/widgets/coffee_loading_overlay.dart';

void main() {
  testWidgets('AuthTextField renders label hint without app network startup', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthTextField(
            controller: controller,
            hintText: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      ),
    );

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });

  testWidgets('CoffeeLoadingOverlay follows the request lifetime', (
    WidgetTester tester,
  ) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold();
          },
        ),
      ),
    );

    final request = Completer<void>();
    final overlay = CoffeeLoadingOverlay.show(hostContext, request.future);
    await tester.pump();

    expect(find.byType(CoffeeLoadingIndicator), findsOneWidget);

    request.complete();
    await overlay;
    await tester.pumpAndSettle();

    expect(find.byType(CoffeeLoadingIndicator), findsNothing);
  });
}
