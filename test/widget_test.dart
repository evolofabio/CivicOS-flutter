import 'package:flutter/material.dart';
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civic_os/app.dart';
import 'package:civic_os/core/models/tenant.dart';

void main() {
  testWidgets('CivicOSApp renders home screen', (WidgetTester tester) async {
    final tenant = Tenant(id: 'test', name: 'Test Comune');

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<Tenant>.value(value: tenant)],
        child: CivicOSApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifica che la schermata di login sia visibile
    expect(find.text('Accedi'), findsOneWidget);

    // Inserisci email e password usando le Key
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'test@email.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );
    await tester.pumpAndSettle();

    // Simula login cittadino (testo bottone: 'Accedi')
    final loginButton = find.widgetWithText(ElevatedButton, 'Accedi cittadino');
    expect(
      loginButton,
      findsOneWidget,
      reason: 'Il pulsante Accedi deve essere presente',
    );
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    // Extra pump per sicurezza
    await tester.pump(const Duration(milliseconds: 500));

    // Verifica che la home sia renderizzata
    expect(find.text('Raccolta Oggi'), findsOneWidget);
  });
}
