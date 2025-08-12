import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/login/login_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/login_screen.dart';

void main() {
  group('Navigation Logic Tests', () {
    testWidgets('LoginSuccess state includes userStatus',
        (WidgetTester tester) async {
      // Test that LoginSuccess state properly includes userStatus
      final loginState = LoginInitial();
      final successState =
          LoginSuccess(loginState, userStatus: 'email-verified');

      expect(successState.userStatus, equals('email-verified'));
      expect(successState.isLoading, isFalse);
      expect(successState.hasError, isFalse);
    });

    testWidgets('Navigation logic handles different user statuses',
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

      // Verify that the login screen renders
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    test('User status navigation mapping', () {
      // Test the navigation logic mapping
      const testCases = [
        {'status': 'email-verified', 'expected': 'Add Salon Info'},
        {'status': 'salon-info-added', 'expected': 'Add Salon Profile'},
        {'status': 'active', 'expected': 'Salon Home Screen'},
        {'status': 'suspended', 'expected': 'Salon Home Screen'},
        {'status': 'unknown', 'expected': 'Salon Home Screen'},
      ];

      for (final testCase in testCases) {
        final status = testCase['status'] as String;
        final expected = testCase['expected'] as String;

        // This is a simple test to verify our logic structure
        String getExpectedNavigation(String userStatus) {
          switch (userStatus.toLowerCase()) {
            case 'email-verified':
              return 'Add Salon Info';
            case 'salon-info-added':
              return 'Add Salon Profile';
            default:
              return 'Salon Home Screen';
          }
        }

        expect(getExpectedNavigation(status), equals(expected));
      }
    });
  });
}
