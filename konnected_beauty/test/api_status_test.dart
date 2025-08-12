import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API Status Test', () {
    test('Login API should return correct status', () async {
      const baseUrl = 'http://srv950342.hstgr.cloud:3000';
      const loginEndpoint = '/salon-auth/login';

      // Use the exact credentials you provided
      const email = 'youba@spotlightdz.dz';
      const password = 'Youba123@';

      print('\n🔐 === TESTING LOGIN API ===');
      print('📧 Email: $email');
      print('🔑 Password: $password');

      try {
        final requestBody = {
          'email': email,
          'password': password,
        };

        print('🔗 URL: $baseUrl$loginEndpoint');
        print('📦 Request Body: ${jsonEncode(requestBody)}');

        final response = await http.post(
          Uri.parse('$baseUrl$loginEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        print('📡 Response Status Code: ${response.statusCode}');
        print('📄 Response Body: "${response.body}"');
        print('📄 Response Body Length: ${response.body.length}');

        if (response.statusCode == 200) {
          if (response.body.isNotEmpty) {
            final responseData = jsonDecode(response.body);
            print('✅ Login Success');
            print('📊 Message: ${responseData['message']}');
            print('📊 Status Code: ${responseData['statusCode']}');

            if (responseData['data'] != null) {
              final data = responseData['data'];
              print('📦 Data Object: $data');
              print('🔍 Status from data.status: ${data['status']}');
              print(
                  '🔍 Status from data.user?.status: ${data['user']?['status']}');
              print(
                  '🔑 Access Token: ${data['access_token'] != null ? 'Present' : 'Missing'}');
              print(
                  '🔄 Refresh Token: ${data['refresh_token'] != null ? 'Present' : 'Missing'}');

              // Determine the actual status
              final actualStatus =
                  data['status'] ?? data['user']?['status'] ?? 'unknown';
              print('🎯 ACTUAL STATUS: $actualStatus');
            }
          } else {
            print('❌ Empty response body');
          }
        } else {
          print('❌ Login Failed');
          if (response.body.isNotEmpty) {
            try {
              final responseData = jsonDecode(response.body);
              print('📊 Error Message: ${responseData['message']}');
            } catch (e) {
              print('📊 Raw Error Response: ${response.body}');
            }
          } else {
            print('📊 Empty error response');
          }
        }
      } catch (e) {
        print('💥 Exception: $e');
      }

      print('🔐 === END TEST ===\n');
    });
  });
}
