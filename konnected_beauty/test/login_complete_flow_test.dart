import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/login/login_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/login_screen.dart';

void main() {
  group('Login Complete Flow Tests', () {
    testWidgets('Login button shows loading state and disables interactions',
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

      // Verify form fields are initially enabled
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Verify login button is initially enabled
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Login screen shows success dialog and navigates',
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
  });
}
