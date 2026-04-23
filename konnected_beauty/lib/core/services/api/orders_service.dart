import 'dart:convert';
import 'http_interceptor.dart';
import '../../config/api_base_url.dart';

class OrdersService {
  static String get baseUrl => ApiBaseUrl.value;

  /// Fetch orders for a specific campaign with filtering
  static Future<Map<String, dynamic>> getOrders({
    required String campaignId,
    String? search,
    double? minAmount,
    double? maxAmount,
    String? dateFrom,
    String? dateTo,
    List<String>? serviceIds,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('📦 Fetching orders for campaign: $campaignId');

      // Build query parameters
      final queryParams = <String, dynamic>{};
      queryParams['page'] = page;
      queryParams['limit'] = limit;

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (minAmount != null) {
        queryParams['minAmount'] = minAmount.toString();
      }

      if (maxAmount != null) {
        queryParams['maxAmount'] = maxAmount.toString();
      }

      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['startDate'] = dateFrom;
        print('📅 Date From: $dateFrom');
      }

      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['endDate'] = dateTo;
        print('📅 Date To: $dateTo');
      }

      print('📅 Date Filter Debug:');
      print('📅 dateFrom parameter: $dateFrom');
      print('📅 dateTo parameter: $dateTo');
      print('📅 Query params: $queryParams');

      if (serviceIds != null && serviceIds.isNotEmpty) {
        // Pass serviceIds as List for array parameter handling
        queryParams['serviceIds[]'] = serviceIds;
        print('🔍 Service IDs as array: $serviceIds');
      }

      // Make GET request to the orders endpoint
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/orders/filter/$campaignId',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Orders fetched successfully');

        // Debug: Check if service filtering is working
        if (serviceIds != null && serviceIds.isNotEmpty) {
          print('🔍 === SERVICE FILTER DEBUG ===');
          print('🔍 Filtering by service IDs: $serviceIds');
          print('🔍 Response data type: ${responseData.runtimeType}');

          if (responseData is Map && responseData['data'] is List) {
            final orders = responseData['data'] as List<dynamic>;
            print('🔍 Total orders returned: ${orders.length}');

            // Check if any orders contain the filtered service
            int matchingOrders = 0;
            for (int i = 0; i < orders.length; i++) {
              final order = orders[i] as Map<String, dynamic>;
              final orderServices = order['services'] as List<dynamic>?;
              if (orderServices != null) {
                for (final service in orderServices) {
                  if (service is Map<String, dynamic>) {
                    final serviceId = service['id']?.toString();
                    if (serviceId != null && serviceIds.contains(serviceId)) {
                      matchingOrders++;
                      print(
                          '🔍 Order ${order['id']} contains filtered service: $serviceId');
                      break;
                    }
                  }
                }
              }
            }
            print(
                '🔍 Orders matching service filter: $matchingOrders/${orders.length}');
          }
        }

        return {
          'success': true,
          'data': responseData,
          'message': 'Orders fetched successfully',
        };
      } else {
        print('❌ Failed to fetch orders: ${response.statusCode}');

        // If all endpoints failed, return error
        print('❌ All API endpoints failed');
        return {
          'success': false,
          'message':
              'All API endpoints failed - please check server configuration',
          'error': 'NoWorkingEndpoint',
          'statusCode': 500,
        };
      }
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return {
        'success': false,
        'message': 'Error fetching orders: ${e.toString()}',
        'error': 'NetworkError',
      };
    }
  }

  /// Get order details by ID
  static Future<Map<String, dynamic>> getOrderDetails({
    required String orderId,
  }) async {
    try {
      print('📦 Fetching order details: $orderId');

      // Make request through interceptor
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/orders/$orderId',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🌐 === HTTP RESPONSE RECEIVED ===');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Headers: ${response.headers}');
      print('🌐 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Order details fetched successfully');
        return {
          'success': true,
          'data': responseData,
          'message': 'Order details fetched successfully',
        };
      } else {
        print('❌ Failed to fetch order details: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch order details',
          'error': responseData['error'] ?? 'Unknown error',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching order details: $e');
      return {
        'success': false,
        'message': 'Error fetching order details: ${e.toString()}',
        'error': 'NetworkError',
      };
    }
  }
}
