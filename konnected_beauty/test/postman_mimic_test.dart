import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Postman Mimic Test', () {
    test('Mimic Postman request exactly', () async {
      const url = 'http://srv950342.hstgr.cloud:3000/salon-auth/login';

      // Use the exact credentials you provided
      const email = 'youba@spotlightdz.dz';
      const password = 'Youba123@';

      print('\n🔐 === MIMICKING POSTMAN REQUEST ===');
      print('🔗 URL: $url');
      print('📧 Email: $email');
      print('🔑 Password: $password');

      try {
        // Try different header combinations that Postman might use
        final headerVariations = [
          {
            'Content-Type': 'application/json',
          },
          {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          {
            'Content-Type': 'application/json',
            'Accept': '*/*',
          },
          {
            'Content-Type': 'application/json',
            'User-Agent': 'PostmanRuntime/7.32.3',
          },
          {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PostmanRuntime/7.32.3',
            'Connection': 'keep-alive',
          },
        ];

        for (int i = 0; i < headerVariations.length; i++) {
          final headers = headerVariations[i];
          print('\n🔧 === TRYING HEADER VARIATION ${i + 1} ===');
          print('📋 Headers: $headers');

          final requestBody = {
            'email': email,
            'password': password,
          };

          print('📦 Request Body: ${jsonEncode(requestBody)}');

          final response = await http
              .post(
                Uri.parse(url),
                headers: headers,
                body: jsonEncode(requestBody),
              )
              .timeout(const Duration(seconds: 15));

          print('📡 Response Status Code: ${response.statusCode}');
          print('📄 Response Body: "${response.body}"');
          print('📄 Response Body Length: ${response.body.length}');

          if (response.statusCode == 200) {
            print('✅ SUCCESS! Found working header combination');
            if (response.body.isNotEmpty) {
              try {
                final responseData = jsonDecode(response.body);
                print('📊 Message: ${responseData['message']}');

                if (responseData['data'] != null) {
                  final data = responseData['data'];
                  print('📦 Data Object: $data');
                  print('🔍 Status from data.status: ${data['status']}');
                  print(
                      '🔍 Status from data.user?.status: ${data['user']?['status']}');

                  final actualStatus =
                      data['status'] ?? data['user']?['status'] ?? 'unknown';
                  print('🎯 ACTUAL STATUS: $actualStatus');

                  // Check if status is "email-verified" or similar
                  if (actualStatus
                      .toString()
                      .toLowerCase()
                      .contains('verified')) {
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
              } catch (e) {
                print('📊 Raw response: ${response.body}');
              }
            } else {
              print('📊 Empty response body');
            }
            break; // Found working combination
          } else {
            print('❌ Failed with status: ${response.statusCode}');
          }
        }
      } catch (e) {
        print('💥 Exception: $e');
      }

      print('\n🔐 === END TEST ===');
    });
  });
}
