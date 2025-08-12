import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/services/storage/token_storage_service.dart';

void main() {
  group('Token Logging', () {
    test('printStoredTokens method exists', () {
      // This test verifies that the method exists
      // The actual console output will be visible when running the app
      expect(TokenStorageService.printStoredTokens, isA<Function>());
    });

    test('Token storage service has required methods', () {
      // Verify that all required methods exist
      expect(TokenStorageService.saveAccessToken, isA<Function>());
      expect(TokenStorageService.getAccessToken, isA<Function>());
      expect(TokenStorageService.saveRefreshToken, isA<Function>());
      expect(TokenStorageService.getRefreshToken, isA<Function>());
      expect(TokenStorageService.saveUserEmail, isA<Function>());
      expect(TokenStorageService.getUserEmail, isA<Function>());
      expect(TokenStorageService.saveUserRole, isA<Function>());
      expect(TokenStorageService.getUserRole, isA<Function>());
      expect(TokenStorageService.saveAuthData, isA<Function>());
      expect(TokenStorageService.clearAuthData, isA<Function>());
      expect(TokenStorageService.isLoggedIn, isA<Function>());
    });
  });
}
