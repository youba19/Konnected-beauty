import 'package:flutter_test/flutter_test.dart';
import '../konnected_beauty/lib/core/services/api/salon_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Login Status Test', () {
    test('Login response should match Postman response structure', () async {
      // Test credentials (use the same as in Postman)
      const email = 'youba@spotlightdz.dz';
      const password = 'Youba123@';

      print('🧪 === LOGIN STATUS TEST ===');
      print('📧 Testing with email: $email');
      print('🔑 Testing with password: $password');

      try {
        // Call the login API
        final result = await SalonAuthService.login(
          email: email,
          password: password,
        );

        print('📊 Login Result: $result');

        if (result['success']) {
          final data = result['data'];
          print('📦 Data Object: $data');

          // Check if user object exists
          final user = data['user'];
          print('👤 User Object: $user');

          // Check status in different possible locations
          final statusFromUser = user?['status'];
          final statusFromData = data['status'];
          final statusFromRoot = result['status'];

          print('🔍 Status from user object: $statusFromUser');
          print('🔍 Status from data object: $statusFromData');
          print('🔍 Status from root: $statusFromRoot');

          // Expected status from Postman
          const expectedStatus = 'email-verified';

          print('🎯 Expected Status (from Postman): $expectedStatus');
          print('🔍 Actual Status (from user object): $statusFromUser');

          // Assertions
          expect(result['success'], isTrue,
              reason: 'Login should be successful');
          expect(data, isNotNull, reason: 'Data should not be null');
          expect(user, isNotNull, reason: 'User object should not be null');

          // Check if status matches Postman
          if (statusFromUser == expectedStatus) {
            print('✅ Status matches Postman: $statusFromUser');
          } else {
            print('❌ Status mismatch!');
            print('   Expected: $expectedStatus');
            print('   Actual: $statusFromUser');
            print('   This explains the discrepancy between app and Postman');
          }

          // Check tokens
          final accessToken = data['access_token'];
          final refreshToken = data['refresh_token'];

          expect(accessToken, isNotNull,
              reason: 'Access token should not be null');
          expect(refreshToken, isNotNull,
              reason: 'Refresh token should not be null');

          print('🔑 Access Token: ${accessToken.substring(0, 50)}...');
          print('🔄 Refresh Token: ${refreshToken.substring(0, 50)}...');
        } else {
          print('❌ Login failed: ${result['message']}');
          fail('Login should be successful');
        }
      } catch (e) {
        print('💥 Test Exception: $e');
        fail('Test should not throw exception: $e');
      }

      print('🧪 === END LOGIN STATUS TEST ===');
    });

    test('Compare app vs Postman response structure', () {
      // Mock Postman response (what you see in Postman)
      final postmanResponse = {
        'message': 'Login successful',
        'data': {
          'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          'refresh_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          'user': {
            'id': 'fd2756e9-a8b0-44a3-ba92-8fb835cf475e',
            'email': 'Youba@spotlightdz.dz',
            'status': 'email-verified' // This is what Postman shows
          }
        },
        'statusCode': 200
      };

      // Mock app response (what the app might be receiving)
      final appResponse = {
        'message': 'Login successful',
        'data': {
          'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          'refresh_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          'user': {
            'id': 'fd2756e9-a8b0-44a3-ba92-8fb835cf475e',
            'email': 'Youba@spotlightdz.dz',
            'status': 'salon-info-added' // This is what app shows
          }
        },
        'statusCode': 200
      };

      print('📊 === RESPONSE COMPARISON ===');
      print('📋 Postman Response: $postmanResponse');
      print('📱 App Response: $appResponse');

      final postmanStatus = (postmanResponse['data']
          as Map<String, dynamic>?)?['user']?['status'];
      final appStatus =
          (appResponse['data'] as Map<String, dynamic>?)?['user']?['status'];

      print('🔍 Postman Status: $postmanStatus');
      print('🔍 App Status: $appStatus');

      if (postmanStatus == appStatus) {
        print('✅ Statuses match');
      } else {
        print('❌ Statuses differ!');
        print('   Postman: $postmanStatus');
        print('   App: $appStatus');
        print('   This confirms the discrepancy');
      }

      print('📊 === END RESPONSE COMPARISON ===');
    });
  });
}
