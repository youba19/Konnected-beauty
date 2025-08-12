import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Direct API Test', () {
    test('Get exact API response', () async {
      print('\n🎯 === DIRECT API TEST ===');
      
      try {
        // Use curl to get the exact API response
        final result = await Process.run('curl', [
          '-X', 'POST',
          '-H', 'Content-Type: application/json',
          '-d', '{"email":"youba@spotlightdz.dz","password":"Youba123@"}',
          'http://srv950342.hstgr.cloud:3000/salon-auth/login',
        ]);
        
        print('📡 Exit Code: ${result.exitCode}');
        print('📄 Raw Response: "${result.stdout}"');
        print('📄 Response Length: ${result.stdout.toString().length}');
        
        if (result.exitCode == 0) {
          print('✅ API call successful');
          print('🎯 EXACT STATUS FROM API: ${result.stdout}');
        } else {
          print('❌ API call failed');
          print('📄 Error: ${result.stderr}');
        }
      } catch (e) {
        print('💥 Exception: $e');
      }
      
      print('🎯 === END DIRECT API TEST ===\n');
    });
  });
}
