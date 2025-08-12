import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Server Connectivity Test', () {
    test('Check if server is reachable', () async {
      const baseUrl = 'http://srv950342.hstgr.cloud:3000';

      print('\n🌐 === SERVER CONNECTIVITY TEST ===');
      print('🔗 Testing base URL: $baseUrl');

      try {
        // Test basic connectivity
        final response = await http
            .get(
              Uri.parse(baseUrl),
            )
            .timeout(const Duration(seconds: 10));

        print('📡 Response Status Code: ${response.statusCode}');
        print('📄 Response Body: "${response.body}"');
        print('📄 Response Body Length: ${response.body.length}');

        if (response.statusCode == 200) {
          print('✅ Server is reachable');
        } else {
          print('⚠️ Server responded with status: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Server connectivity error: $e');
      }

      // Test different endpoints
      final endpoints = [
        '/',
        '/health',
        '/api',
        '/salon-auth',
        '/salon',
      ];

      for (final endpoint in endpoints) {
        try {
          print('\n🔗 Testing endpoint: $endpoint');
          final response = await http
              .get(
                Uri.parse('$baseUrl$endpoint'),
              )
              .timeout(const Duration(seconds: 5));

          print('📡 Status: ${response.statusCode}');
          print('📄 Body: "${response.body}"');
        } catch (e) {
          print('❌ Error: $e');
        }
      }

      print('\n🌐 === END TEST ===');
    });
  });
}
