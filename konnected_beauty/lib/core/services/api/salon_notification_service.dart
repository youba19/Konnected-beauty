import 'dart:convert';
import 'http_interceptor.dart';

class SalonNotificationService {
  static const String baseUrl = 'https://server.konectedbeauty.com';

  /// Fetch salon notifications
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('🔔 === FETCHING SALON NOTIFICATIONS ===');
      print('📋 Page: $page');
      print('📋 Limit: $limit');

      final queryParams = <String, dynamic>{};
      queryParams['page'] = page;
      queryParams['limit'] = limit;

      print('📤 Query Parameters: $queryParams');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon-notification',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📋 === RAW JSON RESPONSE ===');
      print('═══════════════════════════════════════════════════════');
      print(response.body);
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        print('📋 === PARSED JSON RESPONSE ===');
        print('📋 Message: ${responseData['message']}');
        print('📋 Status Code: ${responseData['statusCode']}');
        print('📋 Current Page: ${responseData['currentPage']}');
        print('📋 Total Pages: ${responseData['totalPages']}');
        print('📋 Total: ${responseData['total']}');
        print('📋 Data Type: ${responseData['data'].runtimeType}');
        print(
            '📋 Data Length: ${(responseData['data'] as List?)?.length ?? 0}');

        if (responseData['data'] != null &&
            (responseData['data'] as List).isNotEmpty) {
          print('');
          print('📋 === FIRST NOTIFICATION IN DATA ===');
          final firstNotification = (responseData['data'] as List)[0];
          print('📋 First notification type: ${firstNotification.runtimeType}');
          if (firstNotification is Map) {
            print(
                '📋 First notification keys: ${firstNotification.keys.toList()}');
            print('📋 First notification: $firstNotification');
            print(
                '📋 operationId in first: ${firstNotification['operationId']}');
            print(
                '📋 operationId type: ${firstNotification['operationId']?.runtimeType}');
          }
          print('📋 === END FIRST NOTIFICATION ===');
        }
        print('📋 === END PARSED JSON RESPONSE ===');
        print('');
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'message':
              responseData['message'] ?? 'Notifications retrieved successfully',
          'statusCode': response.statusCode,
          'currentPage': responseData['currentPage'] ?? 1,
          'totalPages': responseData['totalPages'] ?? 1,
          'total': responseData['total'] ?? 0,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch notifications',
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Mark notification as viewed
  static Future<Map<String, dynamic>> markNotificationAsViewed({
    required String notificationId,
    required String token,
  }) async {
    try {
      print('✅ === MARKING SALON NOTIFICATION AS VIEWED ===');
      print('🆔 Notification ID: $notificationId');
      print('🔑 FCM Token: ${token.substring(0, 20)}...');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'PATCH',
        endpoint: '/salon-notification/$notificationId/mark-as-vued',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {
          'token': token,
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Notification marked as viewed',
            'data': responseData,
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Notification marked as viewed',
          };
        }
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ??
              'Failed to mark notification as viewed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error marking notification as viewed: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
      };
    }
  }
}
