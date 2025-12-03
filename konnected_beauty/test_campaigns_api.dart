import 'dart:convert';
import 'package:http/http.dart' as http;

class CampaignsApiTester {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';
  static const String endpoint = '/campaign/salon-campaigns';

  // Test credentials (you'll need to replace with actual tokens)
  static const String accessToken = 'YOUR_ACCESS_TOKEN_HERE';
  static const String refreshToken = 'YOUR_REFRESH_TOKEN_HERE';

  static Future<Map<String, dynamic>> testCampaignsApi({
    required int page,
    required int limit,
    String? status,
    String? search,
  }) async {
    try {
      print('🧪 === TESTING CAMPAIGNS API ===');
      print('📄 Page: $page');
      print('📏 Limit: $limit');
      print('🔍 Search: ${search ?? 'None'}');
      print('📊 Status: ${status ?? 'None'}');
      print('🔗 URL: $baseUrl$endpoint');
      print('');

      // Prepare query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      // Convert to form data (same as the app)
      final formData = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      print('📤 Form Data: $formData');
      print('');

      // Make the request
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $accessToken',
        },
        body: formData,
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Headers: ${response.headers}');
      print('📡 Response Body Length: ${response.body.length}');
      print('');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ API Response:');
        print('📊 Total: ${data['total']}');
        print('📄 Current Page: ${data['currentPage']}');
        print('📄 Total Pages: ${data['totalPages']}');
        print('📊 Data Count: ${(data['data'] as List).length}');
        print('');

        // Show campaign IDs to verify uniqueness
        final campaigns = data['data'] as List;
        final campaignIds = campaigns.map((c) => c['id']).toList();
        print('🆔 Campaign IDs: $campaignIds');
        print('');

        return {
          'success': true,
          'data': data,
          'campaignIds': campaignIds,
        };
      } else {
        print('❌ API Error:');
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
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

    // Test 1: Page 1 with limit 10
    print('📋 TEST 1: Page 1, Limit 10');
    final result1 = await testCampaignsApi(
      page: 1,
      limit: 10,
      status: 'pending',
    );
    print('');

    // Test 2: Page 2 with limit 10
    print('📋 TEST 2: Page 2, Limit 10');
    final result2 = await testCampaignsApi(
      page: 2,
      limit: 10,
      status: 'pending',
    );
    print('');

    // Test 3: Page 1 with limit 100 (should get all campaigns)
    print('📋 TEST 3: Page 1, Limit 100');
    final result3 = await testCampaignsApi(
      page: 1,
      limit: 100,
      status: 'pending',
    );
    print('');

    // Test 4: Page 2 with limit 100
    print('📋 TEST 4: Page 2, Limit 100');
    final result4 = await testCampaignsApi(
      page: 2,
      limit: 100,
      status: 'pending',
    );
    print('');

    // Analysis
    print('📊 === ANALYSIS ===');
    print('');

    if (result1['success'] && result2['success']) {
      final page1Ids = result1['campaignIds'] as List;
      final page2Ids = result2['campaignIds'] as List;

      print('Page 1 Campaign IDs: $page1Ids');
      print('Page 2 Campaign IDs: $page2Ids');
      print('');

      // Check if page 2 returns different data
      final isDifferent = !_listsEqual(page1Ids, page2Ids);
      print('🔄 Page 2 different from Page 1: $isDifferent');

      if (!isDifferent) {
        print('❌ PROBLEM: Page 2 returns the same data as Page 1!');
        print('   This confirms the backend pagination is broken.');
      } else {
        print('✅ Page 2 returns different data (pagination working)');
      }
    }

    if (result3['success']) {
      final allCampaigns = result3['campaignIds'] as List;
      print('All campaigns with limit 100: ${allCampaigns.length}');
      print('Campaign IDs: $allCampaigns');
    }

    print('');
    print('🏁 === TEST COMPLETED ===');
  }

  static Future<void> runQuickTest() async {
    print('⚡ === QUICK CAMPAIGNS API TEST ===');
    print('');

    // Test with different page numbers
    for (int page = 1; page <= 3; page++) {
      print('📋 Testing Page $page...');
      final result = await testCampaignsApi(
        page: page,
        limit: 10,
        status: 'pending',
      );

      if (result['success']) {
        final data = result['data'];
        print('   Total: ${data['total']}');
        print('   Current Page: ${data['currentPage']}');
        print('   Data Count: ${(data['data'] as List).length}');
        print('   Campaign IDs: ${result['campaignIds']}');
      } else {
        print('   ❌ Failed: ${result['message']}');
      }
      print('');
    }
  }

  static bool _listsEqual(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

void main() async {
  print('🧪 Campaigns API Tester');
  print('⚠️  IMPORTANT: Replace the access tokens in the code before running!');
  print('');

  // Uncomment one of these to run tests:

  // Quick test (3 pages)
  await CampaignsApiTester.runQuickTest();

  // Full pagination test
  // await CampaignsApiTester.runPaginationTest();
}
