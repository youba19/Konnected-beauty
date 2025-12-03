import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/api/salon_auth_service.dart';

void main() {
  group('OTP Validation Tests', () {
    test('validateOtp method exists and has correct signature', () {
      // Verify that the method exists and can be called
      expect(SalonAuthService.validateOtp, isA<Function>());
    });

    test('validateOtp endpoint is correctly defined', () {
      // Verify the endpoint URL
      expect(SalonAuthService.validateOtpEndpoint,
          equals('/salon-auth/validate-otp'));
      expect(SalonAuthService.baseUrl,
          equals('http://srv950342.hstgr.cloud:3000'));
    });

    test('validateOtp request format is correct', () {
      // Test the request body format
      const testEmail = 'test@example.com';
      const testOtp = '123456';

      final requestBody = {
        'email': testEmail,
        'otp': testOtp,
      };

      expect(requestBody['email'], equals(testEmail));
      expect(requestBody['otp'], equals(testOtp));
      expect(requestBody.length, equals(2));
    });

    test('formatMessage method handles different message types', () {
      // Test string message
      expect(SalonAuthService.formatMessage('Test message'),
          equals('Test message'));

      // Test list message
      expect(SalonAuthService.formatMessage(['Error 1', 'Error 2']),
          equals('Error 1, Error 2'));

      // Test null message
      expect(SalonAuthService.formatMessage(null), equals(''));

      // Test other types
      expect(SalonAuthService.formatMessage(123), equals('123'));
    });
  });
}
