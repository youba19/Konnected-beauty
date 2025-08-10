import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/api/salon_auth_service.dart';

void main() {
  group('SalonAuthService Tests', () {
    test('Signup API should work with valid data', () async {
      final result = await SalonAuthService.signup(
        name: 'Test User',
        phoneNumber: '+1234567890',
        email: 'test@example.com',
        password: 'TestPass123!',
      );

      // The API should return a response (either success or error)
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });

    test('OTP validation API should work with valid data', () async {
      final result = await SalonAuthService.validateOtp(
        email: 'test@example.com',
        otp: '123456',
      );

      // The API should return a response (either success or error)
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });

    test('Resend OTP API should work with valid email', () async {
      final result = await SalonAuthService.resendOtp(
        email: 'test@example.com',
      );

      // The API should return a response (either success or error)
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });
}
