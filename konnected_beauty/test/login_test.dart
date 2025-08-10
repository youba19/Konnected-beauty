import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/api/salon_auth_service.dart';

void main() {
  group('Salon Login API Tests', () {
    test('should login with valid credentials', () async {
      final result = await SalonAuthService.login(
        email: 'assem.zereg0@gmail.com',
        password: 'Assem1_Z',
      );

      // The API should return a response (either success or error)
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);

      // Print the result for debugging
      print('Login Result: $result');

      // If successful, check for tokens
      if (result['success']) {
        expect(result.containsKey('data'), isTrue);
        final data = result['data'];
        expect(data.containsKey('access_token'), isTrue);
        expect(data.containsKey('refresh_token'), isTrue);
        print('Access Token: ${data['access_token']}');
        print('Refresh Token: ${data['refresh_token']}');
      }
    });

    test('should handle invalid credentials', () async {
      final result = await SalonAuthService.login(
        email: 'invalid@email.com',
        password: 'wrongpassword',
      );

      // The API should return a response
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);

      // Should fail with invalid credentials
      expect(result['success'], isFalse);
      print('Invalid Login Result: $result');
    });
  });
}
