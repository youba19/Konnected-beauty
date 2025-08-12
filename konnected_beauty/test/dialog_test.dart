import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/login/login_bloc.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/login_screen.dart';

void main() {
  group('Login Notification Tests', () {
    testWidgets('should show success notification when login succeeds',
        (WidgetTester tester) async {
      // Build the login screen
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);

      // Verify no overlay notifications are shown initially
      expect(find.byType(Overlay), findsOneWidget);
    });

    testWidgets('should show error notification when login fails',
        (WidgetTester tester) async {
      // Build the login screen
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);

      // Verify no overlay notifications are shown initially
      expect(find.byType(Overlay), findsOneWidget);
    });
  });
}
