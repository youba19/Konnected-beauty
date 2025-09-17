import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Replace this with a real access token from your app logs
  const String accessToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImNmMTRhMDE2LTQ3NmItNDM1Zi1hODdlLTc3OTZiYWEyNmE4YSIsImVtYWlsIjoieW91YmFAc3BvdGxpZ2h0ZHouZHoiLCJyb2xlIjoic2Fsb24iLCJpYXQiOjE3NTc1MjAyMzUsImV4cCI6MTc1NzUyMDI2NX0.sw23NN5qsUyNmwy36OAWs0rqLzFLASrejpXc23t-s6I';

  const String baseUrl = 'http://srv950342.hstgr.cloud:3000';
  const String endpoint = '/campaign/salon-campaigns';

  print('🧪 === SIMPLE CAMPAIGNS API TEST ===');
  print('');

  // Test different pages
  for (int page = 1; page <= 3; page++) {
    print('📋 Testing Page $page...');

    try {
      // Prepare form data (same as the app)
      final formData = 'status=pending&page=$page&limit=10';

      print('📤 Request: POST $baseUrl$endpoint');
      print('📤 Body: $formData');
      print('📤 Headers: Content-Type: application/x-www-form-urlencoded');
      print(
          '📤 Headers: Authorization: Bearer ${accessToken.substring(0, 20)}...');
      print('');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $accessToken',
        },
        body: formData,
      );

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Success!');
        print('📊 Total: ${data['total']}');
        print('📄 Current Page: ${data['currentPage']}');
        print('📄 Total Pages: ${data['totalPages']}');
        print('📊 Data Count: ${(data['data'] as List).length}');

        // Show first few campaign IDs
        final campaigns = data['data'] as List;
        if (campaigns.isNotEmpty) {
          final firstId = campaigns.first['id'];
          final lastId = campaigns.last['id'];
          print('🆔 First Campaign ID: $firstId');
          print('🆔 Last Campaign ID: $lastId');
        }
      } else {
        print('❌ Error: ${response.statusCode}');
        print('📄 Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }

    print('---');
    print('');
  }

  print('🏁 Test completed!');
  print('');
  print('💡 What to look for:');
  print('   - If all pages return currentPage: 1, pagination is broken');
  print('   - If all pages return the same campaign IDs, pagination is broken');
  print('   - Page 2 should return different campaigns than Page 1');
}

