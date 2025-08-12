import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Simple cURL Test', () {
    test('Test API using Process.run', () async {
      print('\n🔐 === TESTING WITH CURL ===');

      try {
        // Test with curl command
        final result = await Process.run('curl', [
          '-X',
          'POST',
          '-H',
          'Content-Type: application/json',
          '-d',
          '{"email":"youba@spotlightdz.dz","password":"Youba123@"}',
          'http://srv950342.hstgr.cloud:3000/salon-auth/login',
        ]);

        print('📡 Exit Code: ${result.exitCode}');
        print('📄 Stdout: "${result.stdout}"');
        print('📄 Stderr: "${result.stderr}"');

        if (result.exitCode == 0) {
          print('✅ cURL request successful');
          print('📊 Response: ${result.stdout}');
        } else {
          print('❌ cURL request failed');
          print('📊 Error: ${result.stderr}');
        }
      } catch (e) {
        print('💥 Exception: $e');
      }

      print('🔐 === END TEST ===\n');
    });
  });
}
