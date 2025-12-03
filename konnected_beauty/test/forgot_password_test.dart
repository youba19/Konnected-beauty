import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/otp_verification_screen.dart';
import 'package:konnected_beauty/features/auth/presentation/pages/new_password_screen.dart';

void main() {
  group('Forgot Password Flow Tests', () {
    testWidgets('should show forgot password screen with role selection',
        (WidgetTester tester) async {
      // Build the forgot password screen
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LanguageBloc>(
            create: (context) => LanguageBloc(),
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the forgot password screen is displayed
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      // Verify the title is displayed
      expect(find.text('Forget your password'), findsOneWidget);

      // Verify role selection buttons are displayed
      expect(find.text('Influencer'), findsOneWidget);
      expect(find.text('Saloon'), findsOneWidget);

      // Verify email field is displayed
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);

      // Verify reset password button is displayed
      expect(find.text('Reset password'), findsOneWidget);
    });

    testWidgets('should show OTP verification screen',
        (WidgetTester tester) async {
      // Build the OTP verification screen
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LanguageBloc>(
            create: (context) => LanguageBloc(),
            child: const OtpVerificationScreen(
              email: 'test@example.com',
              role: 'influencer',
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the OTP verification screen is displayed
      expect(find.byType(OtpVerificationScreen), findsOneWidget);

      // Verify the title is displayed
      expect(find.text('Reset your password'), findsOneWidget);

      // Verify OTP field is displayed
      expect(find.text('XXX-XXX'), findsOneWidget);

      // Verify resend code link is displayed
      expect(find.text('Resend Code'), findsOneWidget);

      // Verify submit button is displayed
      expect(find.text('Submit & Continue'), findsOneWidget);
    });

    testWidgets('should show new password screen', (WidgetTester tester) async {
      // Build the new password screen
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LanguageBloc>(
            create: (context) => LanguageBloc(),
            child: const NewPasswordScreen(
              email: 'test@example.com',
              role: 'influencer',
              otp: '123456',
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the new password screen is displayed
      expect(find.byType(NewPasswordScreen), findsOneWidget);

      // Verify the title is displayed
      expect(find.text('Reset your password'), findsOneWidget);

      // Verify password fields are displayed
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);

      // Verify reset password button is displayed
      expect(find.text('Reset password'), findsOneWidget);
    });
  });
}
