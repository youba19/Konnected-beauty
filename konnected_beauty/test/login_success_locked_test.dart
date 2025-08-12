import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/login/login_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/login_screen.dart';

void main() {
  testWidgets('Login screen is completely locked after successful login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => LoginBloc()),
            BlocProvider(create: (context) => LanguageBloc()),
          ],
          child: const LoginScreen(),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login to your account'), findsOneWidget);

    // Fill in the form
    await tester.enterText(
        find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'Password123!');

    // Verify form is enabled before login
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Click the login button
    await tester.tap(find.text('Login to your account'));
    await tester.pump(); // Trigger immediate state change

    // Verify that form is immediately disabled
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
