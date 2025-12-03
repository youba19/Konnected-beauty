import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Salon Information API Test', () {
    test('Salon add-info API should work correctly', () async {
      const baseUrl = 'http://srv950342.hstgr.cloud:3000';
      const addInfoEndpoint = '/salon/add-info';

      // First, let's try to login to get a token
      print('\n🔐 === LOGIN TO GET TOKEN ===');

      final loginResponse = await http.post(
        Uri.parse('$baseUrl/salon-auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'youba@spotlightdz.dz',
          'password': 'Youba123@',
        }),
      );

      print('📡 Login Response Status: ${loginResponse.statusCode}');
      print('📄 Login Response Body: "${loginResponse.body}"');

      String? accessToken;

      if (loginResponse.statusCode == 200 && loginResponse.body.isNotEmpty) {
        try {
          final loginData = jsonDecode(loginResponse.body);
          accessToken = loginData['data']?['access_token'];
          print('✅ Login successful, got access token');
        } catch (e) {
          print('❌ Failed to parse login response: $e');
        }
      } else {
        print('❌ Login failed, will test without token');
      }

      // Now test the salon add-info API
      print('\n🏢 === TESTING SALON ADD-INFO API ===');

      final requestBody = {
        "name": "Dev salon",
        "address": "Bab Ezzouar",
        "domain": "development"
      };

      print('🔗 URL: $baseUrl$addInfoEndpoint');
      print('📦 Request Body: ${jsonEncode(requestBody)}');

      final headers = {
        'Content-Type': 'application/json',
      };

      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
        print('🔑 Using Bearer token');
      } else {
        print('⚠️ No Bearer token available');
      }

      try {
        final response = await http.post(
          Uri.parse('$baseUrl$addInfoEndpoint'),
          headers: headers,
          body: jsonEncode(requestBody),
        );

        print('📡 Response Status Code: ${response.statusCode}');
        print('📄 Response Body: "${response.body}"');
        print('📄 Response Body Length: ${response.body.length}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.body.isNotEmpty) {
            final responseData = jsonDecode(response.body);
            print('✅ Salon Add Info Success');
            print('📊 Message: ${responseData['message']}');
            print('📊 Status Code: ${responseData['statusCode']}');
            print('📦 Data: ${responseData['data']}');
          } else {
            print('✅ Salon Add Info Success (empty response)');
          }
        } else {
          print('❌ Salon Add Info Failed');
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

      print('🏢 === END TEST ===\n');
    });
  });
}
