import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter HTTP Test', () {
    test('Test Flutter http package with real API', () async {
      const url = 'http://srv950342.hstgr.cloud:3000/salon-auth/login';

      print('\n🔐 === TESTING FLUTTER HTTP PACKAGE ===');

      try {
        final requestBody = {
          'email': 'youba@spotlightdz.dz',
          'password': 'Youba123@',
        };

        print('🔗 URL: $url');
        print('📦 Request Body: ${jsonEncode(requestBody)}');

        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 30));

        print('📡 Response Status Code: ${response.statusCode}');
        print('📄 Response Body: "${response.body}"');
        print('📄 Response Body Length: ${response.body.length}');

        if (response.statusCode == 200) {
          if (response.body.isNotEmpty) {
            final responseData = jsonDecode(response.body);
            print('✅ Flutter HTTP Success');
            print('📊 Message: ${responseData['message']}');

            if (responseData['data'] != null) {
              final data = responseData['data'];
              print('📦 Data Object: $data');
              print('🔍 Status from data.status: ${data['status']}');
              print('🔍 Status type: ${data['status']?.runtimeType}');
              print('🔍 Raw status value: "${data['status']}"');

              final actualStatus = data['status'] ?? 'unknown';
              print('🎯 ACTUAL STATUS: $actualStatus');
            }
          } else {
            print('❌ Empty response body');
          }
        } else {
          print('❌ Flutter HTTP Failed');
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
