import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/api/salon_auth_service.dart';

void main() {
  group('Message Formatting Tests', () {
    test('should format string message correctly', () {
      final result = SalonAuthService.formatMessage('Test message');
      expect(result, equals('Test message'));
    });

    test('should format list message correctly', () {
      final result = SalonAuthService.formatMessage(['Error 1', 'Error 2']);
      expect(result, equals('Error 1, Error 2'));
    });

    test('should handle null message', () {
      final result = SalonAuthService.formatMessage(null);
      expect(result, equals(''));
    });

    test('should handle empty list', () {
      final result = SalonAuthService.formatMessage([]);
      expect(result, equals(''));
    });

    test('should handle single item list', () {
      final result = SalonAuthService.formatMessage(['Single error']);
      expect(result, equals('Single error'));
    });
  });
}
