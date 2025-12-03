import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/api/salon_auth_service.dart';

void main() {
  group('Resend OTP API Tests', () {
    test('should handle resend OTP API call with existing email', () async {
      final result = await SalonAuthService.resendOtp(
        email:
            'assem.zereg0@gmail.com', // Use the email from Postman collection
      );

      // The API should return a response (either success or error)
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);

      // Print the result for debugging
      print('Resend OTP Result: $result');
    });

    test('should format message correctly for resend OTP', () {
      // Test with string message
      final stringResult =
          SalonAuthService.formatMessage('OTP sent successfully');
      expect(stringResult, equals('OTP sent successfully'));

      // Test with list message
      final listResult =
          SalonAuthService.formatMessage(['Mail not sent', 'Please try again']);
      expect(listResult, equals('Mail not sent, Please try again'));

      // Test with null message
      final nullResult = SalonAuthService.formatMessage(null);
      expect(nullResult, equals(''));
    });
  });
}
