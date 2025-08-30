import 'dart:convert';
import 'http_interceptor.dart';

class InfluencersService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  /// Fetch all influencers with pagination and filtering support
  static Future<Map<String, dynamic>> getInfluencers({
    int page = 1,
    int limit = 10,
    String? search,
    String? zone,
    String? sortOrder = 'DESC',
  }) async {
    try {
      print('👥 === FETCHING INFLUENCERS ===');
      print('📄 Page: $page');
      print('📏 Limit: $limit');
      print('🔍 Search: ${search ?? 'None'}');
      print('🔗 URL: $baseUrl/influencer');

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortOrder': sortOrder ?? 'DESC',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (zone != null && zone.isNotEmpty) {
        queryParams['zone'] = zone;
      }

      final uri = Uri.parse('$baseUrl/influencer')
          .replace(queryParameters: queryParams);

      print('🔗 Request URL: $uri');
      print('🔧 Using HTTP interceptor for automatic token management');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Influencers fetched successfully');
        print('📊 Total Influencers: ${responseData['data']?.length ?? 0}');
        print('📄 Current Page: ${responseData['currentPage']}');
        print('📄 Total Pages: ${responseData['totalPages']}');

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Influencers fetched successfully',
          'data': responseData['data'] ?? [],
          'currentPage': responseData['currentPage'] ?? 1,
          'totalPages': responseData['totalPages'] ?? 1,
          'total': responseData['total'] ?? 0,
          'statusCode': response.statusCode,
        };
      } else {
        print(
            '❌ Failed to fetch influencers with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to fetch influencers: ${response.statusCode}';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
            'errorDetails': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to fetch influencers: ${response.statusCode}',
            'statusCode': response.statusCode,
            'rawResponse': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Exception in getInfluencers: $e');
      return {
        'success': false,
        'message': 'Error fetching influencers: $e',
        'statusCode': 0,
      };
    }
  }
}
