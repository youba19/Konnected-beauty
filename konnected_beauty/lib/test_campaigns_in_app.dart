import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CampaignsApiTester {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';
  static const String endpoint = '/campaign/salon-campaigns';

  static Future<String?> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      print('❌ Error getting access token: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> testPage({
    required int page,
    required int limit,
    String? status,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'error': 'No access token found',
        };
      }

      print('🧪 === TESTING PAGE $page ===');
      print('📄 Page: $page');
      print('📏 Limit: $limit');
      print('📊 Status: ${status ?? 'None'}');

      // Prepare query parameters (same as the app)
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = status;

      print('📤 Query Parameters: $queryParams');

      // Use POST with form data in body (as shown in the logs)
      final formData = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final campaigns = data['data'] as List;
        final campaignIds = campaigns.map((c) => c['id']).toList();

        print('✅ Success!');
        print('📊 Total: ${data['total']}');
        print('📄 Current Page: ${data['currentPage']}');
        print('📄 Total Pages: ${data['totalPages']}');
        print('📊 Data Count: ${campaigns.length}');
        print('🆔 Campaign IDs: $campaignIds');

        return {
          'success': true,
          'data': data,
          'campaignIds': campaignIds,
          'total': data['total'],
          'currentPage': data['currentPage'],
          'totalPages': data['totalPages'],
        };
      } else {
        print('❌ Error: ${response.statusCode}');
        print('📄 Response: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {
        'success': false,
        'error': 'Exception',
        'message': e.toString(),
      };
    }
  }

  static Future<void> runPaginationTest() async {
    print('🚀 === CAMPAIGNS API PAGINATION TEST ===');
    print('');

    // Test pages 1, 2, and 3
    final results = <int, Map<String, dynamic>>{};

    for (int page = 1; page <= 3; page++) {
      print('📋 Testing Page $page...');
      results[page] = await testPage(
        page: page,
        limit: 10,
        status: 'pending',
      );
      print('');
    }

    // Analysis
    print('📊 === ANALYSIS ===');
    print('');

    if (results[1]!['success'] && results[2]!['success']) {
      final page1Ids = results[1]!['campaignIds'] as List;
      final page2Ids = results[2]!['campaignIds'] as List;

      print('Page 1 Campaign IDs: $page1Ids');
      print('Page 2 Campaign IDs: $page2Ids');
      print('');

      // Check if page 2 returns different data
      final isDifferent = !_listsEqual(page1Ids, page2Ids);
      print('🔄 Page 2 different from Page 1: $isDifferent');

      if (!isDifferent) {
        print('❌ PROBLEM: Page 2 returns the same data as Page 1!');
        print('   This confirms the backend pagination is broken.');
        print('   The backend is ignoring the page parameter.');
      } else {
        print('✅ Page 2 returns different data (pagination working)');
      }

      // Check currentPage values
      final page1CurrentPage = results[1]!['currentPage'];
      final page2CurrentPage = results[2]!['currentPage'];
      print('Page 1 Current Page: $page1CurrentPage');
      print('Page 2 Current Page: $page2CurrentPage');

      if (page1CurrentPage == page2CurrentPage) {
        print('❌ PROBLEM: Both pages return the same currentPage value!');
        print('   The backend is not respecting the page parameter.');
      }
    }

    // Check if we can get all campaigns with high limit
    print('📋 Testing with high limit (100)...');
    final highLimitResult = await testPage(
      page: 1,
      limit: 100,
      status: 'pending',
    );

    if (highLimitResult['success']) {
      final allCampaigns = highLimitResult['campaignIds'] as List;
      print('All campaigns with limit 100: ${allCampaigns.length}');
      print('Campaign IDs: $allCampaigns');
    }

    print('');
    print('🏁 === TEST COMPLETED ===');
  }

  static bool _listsEqual(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// Function to call from your app
Future<void> testCampaignsApi() async {
  await CampaignsApiTester.runPaginationTest();
}
