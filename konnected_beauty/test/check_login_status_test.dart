import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Check Login Status Test', () {
    test('Check login status using exact endpoint', () async {
      const url = 'http://srv950342.hstgr.cloud:3000/salon-auth/login';

      // Use the exact credentials you provided
      const email = 'youba@spotlightdz.dz';
      const password = 'Youba123@';

      print('\n🔐 === CHECKING LOGIN STATUS ===');
      print('🔗 URL: $url');
      print('📧 Email: $email');
      print('🔑 Password: $password');

      try {
        final requestBody = {
          'email': email,
          'password': password,
        };

        print('📦 Request Body: ${jsonEncode(requestBody)}');

        final response = await http.post(
          Uri.parse(url),
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

              // Check if status is "email-verified" or similar
              if (actualStatus.toString().toLowerCase().contains('verified')) {
                print('✅ Status indicates email is verified');
              } else if (actualStatus
                  .toString()
                  .toLowerCase()
                  .contains('otp')) {
                print('📧 Status indicates OTP verification needed');
              } else if (actualStatus
                  .toString()
                  .toLowerCase()
                  .contains('salon-info')) {
                print('🏢 Status indicates salon info already added');
              } else {
                print('❓ Unknown status: $actualStatus');
              }
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
