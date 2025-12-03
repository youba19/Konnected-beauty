import 'dart:convert';
import 'http_interceptor.dart';

class InfluencerCampaignDetailService {
  /// Fetch campaign details by ID
  static Future<Map<String, dynamic>> getCampaignDetails(
      String campaignId) async {
    try {
      print('📋 === FETCHING CAMPAIGN DETAILS ===');
      print('🎯 Campaign ID: $campaignId');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/campaign/influencer-campaign/$campaignId',
      );

      print('🌐 === CAMPAIGN DETAILS API RESPONSE ===');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['statusCode'] == 200 &&
            responseData['message'] == 'success') {
          final campaignData = responseData['data'] as Map<String, dynamic>;
          print('✅ Campaign details fetched successfully');
          print('📋 Campaign Data: $campaignData');

          return {
            'success': true,
            'data': campaignData,
            'message': 'Campaign details fetched successfully'
          };
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Failed to fetch campaign details',
            'error': 'API_ERROR'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'error': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ Error fetching campaign details: $e');
      return {
        'success': false,
        'message': 'Error fetching campaign details: ${e.toString()}',
        'error': 'NETWORK_ERROR'
      };
    }
  }
}
