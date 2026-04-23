import 'dart:convert';
import 'http_interceptor.dart';
import '../storage/token_storage_service.dart';
import '../../config/api_base_url.dart';

class InfluencerCampaignsService {
  static String get baseUrl => ApiBaseUrl.value;

  /// Fetch influencer campaigns
  static Future<Map<String, dynamic>> getInfluencerCampaigns({
    String? status,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('📋 === FETCHING INFLUENCER CAMPAIGNS ===');
      print('📋 Status: $status');
      print('📋 Search: $search');
      print('📋 Page: $page');
      print('📋 Limit: $limit');

      // Check authentication status before making request
      final token = await TokenStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        return {
          'success': false,
          'message': 'Authentication required',
          'statusCode': 401,
        };
      }

      print('🔑 Token found: ${token.substring(0, 20)}...');

      final queryParams = <String, dynamic>{};
      queryParams['page'] = page;
      queryParams['limit'] = limit;
      queryParams['sort'] = 'createdAt'; // Sort by creation date
      queryParams['order'] = 'desc'; // Descending order (newest first)
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      print('📤 Query Parameters: $queryParams');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/campaign/influencer-campaigns',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> rawCampaigns = responseData['data'] ?? [];

        // Process campaigns data
        final List<Map<String, dynamic>> processedCampaigns =
            rawCampaigns.map((campaign) {
          final salon = campaign['salon'] as Map<String, dynamic>? ?? {};
          final salonInfo = salon['salonInfo'] as Map<String, dynamic>? ?? {};

          return {
            'id': campaign['id'],
            'createdAt': campaign['createdAt'],
            'status': campaign['status'] ?? 'pending',
            'promotion': campaign['promotion'] ?? 0,
            'promotionType': campaign['promotionType'] ?? 'percentage',
            'invitationMessage': campaign['invitationMessage'] ?? '',
            'salonName': salonInfo['name'] ?? 'Unknown Salon',
            'salonId': salon['id'],
            'salon': salon,
            'salonInfo': salonInfo,
          };
        }).toList();

        print('✅ Processed ${processedCampaigns.length} campaigns');

        return {
          'success': true,
          'data': processedCampaigns,
          'message':
              responseData['message'] ?? 'Campaigns fetched successfully',
          'statusCode': response.statusCode,
          'total': responseData['total'] ?? 0,
          'totalPages': responseData['totalPages'] ?? 1,
          'currentPage': responseData['currentPage'] ?? 1,
        };
      } else {
        final errorData = json.decode(response.body);
        print('❌ Failed to fetch campaigns: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch campaigns',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in getInfluencerCampaigns: $e');
      return {
        'success': false,
        'message': 'Error fetching campaigns: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }
}
