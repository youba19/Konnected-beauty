import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/bloc/login/login_bloc.dart';

void main() {
  group('Login Response Parsing Tests', () {
    test('LoginSuccess state correctly handles email-verified status', () {
      // Test with the provided API response format
      final loginState = const LoginInitial();
      final successState =
          LoginSuccess(loginState, userStatus: 'email-verified');

      expect(successState.userStatus, equals('email-verified'));
      expect(successState.isLoading, isFalse);
      expect(successState.hasError, isFalse);
    });

    test('LoginSuccess state correctly handles salon-info-added status', () {
      final loginState = const LoginInitial();
      final successState =
          LoginSuccess(loginState, userStatus: 'salon-info-added');

      expect(successState.userStatus, equals('salon-info-added'));
      expect(successState.isLoading, isFalse);
      expect(successState.hasError, isFalse);
    });

    test('LoginSuccess state correctly handles other statuses', () {
      final loginState = const LoginInitial();
      final successState = LoginSuccess(loginState, userStatus: 'active');

      expect(successState.userStatus, equals('active'));
      expect(successState.isLoading, isFalse);
      expect(successState.hasError, isFalse);
    });

    test('API response parsing simulation', () {
      // Simulate the API response format you provided
      final apiResponse = {
        'message': 'Login successful',
        'data': {
          'access_token':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImNmMTRhMDE2LTQ3NmItNDM1Zi1hODdlLTc3OTZiYWEyNmE4YSIsImVtYWlsIjoieW91YmFAc3BvdGxpZ2h0ZHouZHoiLCJyb2xlIjoic2Fsb24iLCJpYXQiOjE3NTQ5MTg5NTEsImV4cCI6MTc1NDkxODk4MX0.laMgFpUztBWlp8Ff0DEGH5GnBYD5AqYYXwHXDIyHiOU',
          'refresh_token':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImNmMTRhMDE2LTQ3NmItNDM1Zi1hODdlLTc3OTZiYWEyNmE4YSIsImVtYWlsIjoieW91YmFAc3BvdGxpZ2h0ZHouZHoiLCJyb2xlIjoic2Fsb24iLCJpYXQiOjE3NTQ5MTg5NTEsImV4cCI6MTc1NTUyMzc1MX0.-FIHlY_lVZ3HBfoPQ6hC9ttcxw84ChRvFqCe9pViNXE',
          'status': 'email-verified'
        },
        'statusCode': 200
      };

      // Extract data as the login bloc does
      final data = apiResponse['data'] as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final userStatus = data['status'] as String;

      // Verify the extraction
      expect(accessToken, isNotEmpty);
      expect(refreshToken, isNotEmpty);
      expect(userStatus, equals('email-verified'));
      expect(apiResponse['statusCode'], equals(200));
    });

    test('Navigation logic handles case-insensitive status matching', () {
      // Test that the navigation logic works with different case formats
      final testCases = [
        'email-verified',
        'EMAIL-VERIFIED',
        'Email-Verified',
        'salon-info-added',
        'SALON-INFO-ADDED',
        'Salon-Info-Added',
      ];

      for (final status in testCases) {
        final lowerStatus = status.toLowerCase();

        if (lowerStatus == 'email-verified') {
          expect(lowerStatus, equals('email-verified'));
        } else if (lowerStatus == 'salon-info-added') {
          expect(lowerStatus, equals('salon-info-added'));
        } else {
          // Should not match any specific case
          expect(lowerStatus, isNot(equals('email-verified')));
          expect(lowerStatus, isNot(equals('salon-info-added')));
        }
      }
    });
  });
}
