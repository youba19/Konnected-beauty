import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/api/salon_auth_service.dart';

void main() {
  group('Comprehensive Salon Login Tests', () {
    test('should handle login with provided credentials', () async {
      final result = await SalonAuthService.login(
        email: 'assem.zereg0@gmail.com',
        password: 'Assem1_Z',
      );

      print('=== LOGIN TEST RESULT ===');
      print('Success: ${result['success']}');
      print('Message: ${result['message']}');
      print('Status Code: ${result['statusCode']}');
      print('Error: ${result['error']}');

      if (result['success']) {
        print('=== TOKENS ===');
        final data = result['data'];
        print('Access Token: ${data['access_token']}');
        print('Refresh Token: ${data['refresh_token']}');
        print('Status: ${data['status']}');
      }

      // The API should return a response
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);
    });

    test('should handle invalid email format', () async {
      final result = await SalonAuthService.login(
        email: 'invalid-email',
        password: 'Assem1_Z',
      );

      print('=== INVALID EMAIL TEST ===');
      print('Result: $result');

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });

    test('should handle empty credentials', () async {
      final result = await SalonAuthService.login(
        email: '',
        password: '',
      );

      print('=== EMPTY CREDENTIALS TEST ===');
      print('Result: $result');

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });

    test('should handle wrong password', () async {
      final result = await SalonAuthService.login(
        email: 'assem.zereg0@gmail.com',
        password: 'WrongPassword123!',
      );

      print('=== WRONG PASSWORD TEST ===');
      print('Result: $result');

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });
}
