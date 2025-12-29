// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindful_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen shows link-style signup toggle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    // Default state: login
    expect(find.text('Log In!'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    // Tap the link to switch to signup
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up!'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    // Email/password form should be visible by default after toggling
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
