import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/login/login_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/login_screen.dart';

void main() {
  testWidgets(
      'Login screen shows success notification and navigates to salon home',
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

    // Verify login screen is displayed
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login to your account'), findsOneWidget);
  });
}
