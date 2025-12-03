import 'dart:convert';
import 'http_interceptor.dart';

class InfluencerWalletService {
  static const String baseUrl = 'https://server.konectedbeauty.com';

  /// Get influencer wallet balance
  static Future<Map<String, dynamic>> getBalance() async {
    try {
      print('💰 === FETCHING INFLUENCER WALLET BALANCE ===');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer-wallet/balance',
      );

      print('💰 Balance API Response Status: ${response.statusCode}');
      print('💰 Balance API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('💰 Parsed Response: $responseData');

        if (responseData['statusCode'] == 200 &&
            (responseData['message'] == 'success' ||
                responseData['messgae'] == 'succss')) {
          final balance = responseData['data']?['balance'] ?? 0.0;
          print('💰 Extracted Balance: $balance');

          return {
            'success': true,
            'balance': balance,
            'message': 'Balance fetched successfully',
          };
        } else {
          print(
              '❌ API returned error: ${responseData['message'] ?? responseData['messgae']}');
          return {
            'success': false,
            'message': responseData['message'] ??
                responseData['messgae'] ??
                'Failed to fetch balance',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error fetching influencer wallet balance: $e');
      return {
        'success': false,
        'message': 'Error fetching balance: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// Get influencer statistics
  static Future<Map<String, dynamic>> getStats({
    String? salonId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('📊 === FETCHING INFLUENCER STATS ===');
      print('🏢 Salon ID: ${salonId ?? 'None'}');
      print('📅 Start Date: ${startDate?.toIso8601String() ?? 'None'}');
      print('📅 End Date: ${endDate?.toIso8601String() ?? 'None'}');

      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (salonId != null && salonId.isNotEmpty) {
        queryParams['salonId'] = salonId;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer-stats',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📊 Stats API Response Status: ${response.statusCode}');
      print('📊 Stats API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('📊 Parsed Response: $responseData');

        if (responseData['statusCode'] == 200 &&
            (responseData['message'] == 'success' ||
                responseData['messgae'] == 'succss')) {
          final stats = responseData['data'] as Map<String, dynamic>;
          print('📊 Extracted Stats: $stats');

          return {
            'success': true,
            'stats': stats,
            'message': 'Stats fetched successfully',
          };
        } else {
          print(
              '❌ API returned error: ${responseData['message'] ?? responseData['messgae']}');
          return {
            'success': false,
            'message': responseData['message'] ??
                responseData['messgae'] ??
                'Failed to fetch stats',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error fetching influencer stats: $e');
      return {
        'success': false,
        'message': 'Error fetching stats: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// Get influencer home statistics (revenue and orders with daily data)
  static Future<Map<String, dynamic>> getHomeStats() async {
    try {
      print('🏠 === FETCHING INFLUENCER HOME STATS ===');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer-stats/home',
      );

      print('🏠 Home Stats API Response Status: ${response.statusCode}');
      print('🏠 Home Stats API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('🏠 Parsed Response: $responseData');

        if (responseData['statusCode'] == 200 &&
            (responseData['message'] == 'success' ||
                responseData['messgae'] == 'succss')) {
          final data = responseData['data'] as Map<String, dynamic>;
          print('🏠 Extracted Home Stats: $data');

          return {
            'success': true,
            'data': data,
            'message': 'Home stats fetched successfully',
          };
        } else {
          print(
              '❌ API returned error: ${responseData['message'] ?? responseData['messgae']}');
          return {
            'success': false,
            'message': responseData['message'] ??
                responseData['messgae'] ??
                'Failed to fetch home stats',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error fetching influencer home stats: $e');
      return {
        'success': false,
        'message': 'Error fetching home stats: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }
}
