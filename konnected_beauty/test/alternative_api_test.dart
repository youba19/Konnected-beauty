import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alternative API Test', () {
    test('Try different API variations', () async {
      const baseUrl = 'http://srv950342.hstgr.cloud:3000';
      
      // Test different variations of the login endpoint
      final endpoints = [
        '/salon-auth/login',
        '/api/salon-auth/login',
        '/v1/salon-auth/login',
        '/auth/login',
        '/login',
      ];
      
      const email = 'youba@spotlightdz.dz';
      const password = 'Youba123@';
      
      for (final endpoint in endpoints) {
        print('\n🔐 === TESTING ENDPOINT: $endpoint ===');
        
        try {
          final url = '$baseUrl$endpoint';
          print('🔗 URL: $url');
          
          final requestBody = {
            'email': email,
            'password': password,
          };
          
          print('📦 Request Body: ${jsonEncode(requestBody)}');
          
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 10));

          print('📡 Response Status Code: ${response.statusCode}');
          print('📄 Response Body: "${response.body}"');
          print('📄 Response Body Length: ${response.body.length}');

          if (response.statusCode == 200) {
            print('✅ SUCCESS! Found working endpoint: $endpoint');
            if (response.body.isNotEmpty) {
              try {
                final responseData = jsonDecode(response.body);
                print('📊 Message: ${responseData['message']}');
                
                if (responseData['data'] != null) {
                  final data = responseData['data'];
                  final actualStatus = data['status'] ?? data['user']?['status'] ?? 'unknown';
                  print('🎯 ACTUAL STATUS: $actualStatus');
                }
              } catch (e) {
                print('📊 Raw response: ${response.body}');
              }
            }
            break; // Found working endpoint
          } else {
            print('❌ Failed with status: ${response.statusCode}');
          }
        } catch (e) {
          print('💥 Exception: $e');
        }
      }
      
      print('\n🔐 === END TEST ===');
    });
  });
}
