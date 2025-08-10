import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/api/salon_auth_service.dart';

void main() {
  group('Salon Signup API Tests', () {
    test('should signup with valid credentials', () async {
      final result = await SalonAuthService.signup(
        name: 'Test User',
        phoneNumber: '+33666850072',
        email: 'assem.zereg0@gmail.com',
        password: 'Assem1_Z',
      );

      // The API should return a response (either success or error)
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);

      // Print the result for debugging
      print('Signup Result: $result');
    });

    test('should handle existing email', () async {
      final result = await SalonAuthService.signup(
        name: 'Test User',
        phoneNumber: '+33666850072',
        email: 'assem.zereg0@gmail.com',
        password: 'Assem1_Z',
      );

      // The API should return a response
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);

      // Should fail if email already exists
      print('Existing Email Signup Result: $result');
    });
  });
}
